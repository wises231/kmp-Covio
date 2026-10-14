package com.wyz.covio.core

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.doubleOrNull
import okio.FileSystem
import okio.Path.Companion.toPath

/**
 * 设计合同诊断的严重程度。
 *
 * `ERROR` 让 [DesignContractValidationResult.isValid] 变成 false。
 * `WARNING` 只记录，不拦。
 */
enum class DesignContractSeverity {
    ERROR,
    WARNING,
}

/**
 * 一条合同诊断。
 *
 * [path] 是出错的位置，写法是 JSON 路径，例如 `tokens/token/motion/hub-expand`。
 * 只写路径不写行号：合同是格式化过的 JSON，路径比行号更能定位。
 */
data class DesignContractDiagnostic(
    val severity: DesignContractSeverity,
    val path: String,
    val message: String,
) {
    /** 给人看的单行写法。 */
    fun describe(): String = "${severity.name} $path: $message"
}

/**
 * 合同校验的结果。
 *
 * [contract] 在出现 `ERROR` 时为 null：合同读不完整，用它的模型会误导调用方。
 * 只有 `WARNING` 时 [contract] 照常给出。
 */
data class DesignContractValidationResult(
    val contract: DesignContract?,
    val diagnostics: List<DesignContractDiagnostic>,
) {
    /** 没有 `ERROR` 就是有效。`WARNING` 不影响结果。 */
    val isValid: Boolean
        get() = diagnostics.none { it.severity == DesignContractSeverity.ERROR }

    val errors: List<DesignContractDiagnostic>
        get() = diagnostics.filter { it.severity == DesignContractSeverity.ERROR }

    val warnings: List<DesignContractDiagnostic>
        get() = diagnostics.filter { it.severity == DesignContractSeverity.WARNING }

    companion object {
        /** 全部通过。 */
        fun ok(contract: DesignContract): DesignContractValidationResult =
            DesignContractValidationResult(contract, emptyList())
    }
}

/**
 * 合同里的一条文案。
 *
 * 只有两种语言。合同给的就是这两种，界面不做第三语言的回退。
 */
data class DesignCopyEntry(
    val key: String,
    val en: String,
    val zhHans: String,
)

/**
 * 合同里的一枚令牌。
 *
 * 颜色与尺寸用 `light` 与 `dark` 两个字符串；动效令牌用 [durationMs] 三个数。
 * 两类令牌共用一个模型，[isMotion] 区分。
 * 这样调用方可以用一套遍历处理全部令牌，只在自己的分支里看需要的字段。
 */
data class DesignToken(
    val key: String,
    val type: String,
    val purpose: String,
    val light: String?,
    val dark: String?,
    val durationMs: Double?,
    val minMs: Double?,
    val maxMs: Double?,
    val reducedMotionMs: Double?,
    val curve: String?,
) {
    /** 是不是动效令牌。 */
    val isMotion: Boolean get() = type == "duration"

    /**
     * 动效时长的范围是否成立，且取值落在范围里。
     *
     * 非动效令牌返回 true：这条规则不管它们。
     */
    val hasValidMotionRange: Boolean
        get() {
            if (!isMotion) return true
            val low = minMs ?: return false
            val value = durationMs ?: return false
            val high = maxMs ?: return false
            if (value <= 0.0 || low <= 0.0 || high <= 0.0) return false
            if (low > value || value > high) return false
            val reduced = reducedMotionMs ?: return true
            return reduced <= value
        }
}

/**
 * 合同的只读模型。
 *
 * 只收界面与校验用得到的段：`schemaVersion`、`tokens`、`copy`、`components`、
 * `platformMapping`。`figmaNodeMap` 与 `variables` 是 Figma 侧的账，界面不读。
 *
 * 这个模型不写回合同。合同的写入方是 Figma 交付脚本，不是应用。
 */
data class DesignContract(
    val schemaVersion: String,
    val tokens: List<DesignToken>,
    val copy: List<DesignCopyEntry>,
    val components: List<String>,
    val platformMappings: List<String>,
) {
    /** 动效令牌。按令牌里的时长给动画用。 */
    val motionTokens: List<DesignToken> get() = tokens.filter { it.isMotion }

    fun token(key: String): DesignToken? = tokens.firstOrNull { it.key == key }

    /**
     * 按键取一条文案。
     *
     * 不叫 `copyEntry`：Kotlin/Native 把数据类上以 `copy` 开头的方法重命名，
     * `copyEntry` 会导出成 `doCopyEntry`，Swift 侧看起来像另一个东西。
     * 同类的还有 `copy` 导出成 `doCopy`。
     */
    fun entry(key: String): DesignCopyEntry? = copy.firstOrNull { it.key == key }
}

/**
 * 读设计合同并校验。
 *
 * 权威文件是 `docs/covio-design-contract.json`。生成器
 * `scripts/generate-contract-constants.py` 从同一份文件产出 Swift 常量，
 * `scripts/validate-contract.py` 做跨段校验。
 * 这里做的是应用侧能做的那些检查：形状、必填项、取值自洽。
 *
 * **这台读取器不抛异常。** Kotlin 的异常跨到 Swift 没有接收方，会终止进程。
 * 文件缺失、JSON 坏掉、字段类型不对都变成 `ERROR` 诊断。
 */
object DesignContractReader {
    private val json = Json { ignoreUnknownKeys = true }

    fun parse(text: String): DesignContractValidationResult {
        val root = runCatching {
            json.parseToJsonElement(text) as? JsonObject
        }.getOrNull() ?: return failure("", "合同不是合法的 JSON 对象")

        val diagnostics = mutableListOf<DesignContractDiagnostic>()

        val schemaVersion = root.string("schemaVersion")
        if (schemaVersion.isNullOrBlank()) {
            diagnostics += DesignContractDiagnostic(
                DesignContractSeverity.ERROR,
                "schemaVersion",
                "缺 schemaVersion，或者它不是非空字符串",
            )
        }

        val tokens = readTokens(root.obj("tokens"), diagnostics)
        val copy = readCopy(root.obj("copy"), diagnostics)
        val components = readComponents(root.obj("components"), diagnostics)
        val platformMappings = readPlatformMappings(root.obj("platformMapping"), diagnostics)

        if (tokens.isEmpty()) diagnostics += missing("tokens")
        if (copy.isEmpty()) diagnostics += missing("copy")
        if (components.isEmpty()) diagnostics += missing("components")
        if (platformMappings.isEmpty()) diagnostics += missing("platformMapping")

        if (diagnostics.any { it.severity == DesignContractSeverity.ERROR }) {
            return DesignContractValidationResult(null, diagnostics)
        }
        return DesignContractValidationResult(
            DesignContract(
                schemaVersion = schemaVersion!!,
                tokens = tokens,
                copy = copy,
                components = components,
                platformMappings = platformMappings,
            ),
            diagnostics,
        )
    }

    /**
     * 从磁盘读合同。
     *
     * 读不到时返回一条 `ERROR` 诊断，不抛异常。
     */
    fun read(
        path: String = defaultContractPath(),
        fileSystem: FileSystem = FileSystem.SYSTEM,
    ): DesignContractValidationResult = runCatching {
        fileSystem.read(path.toPath()) { readUtf8() }
    }.fold(
        onSuccess = { parse(it) },
        onFailure = { failure(path, "读不到合同文件：${it.message ?: it::class.simpleName}") },
    )

    /**
     * 从磁盘读合同，只用路径。
     *
     * Swift 侧走这一个入口。`read` 的 `fileSystem` 是默认参数，
     * Kotlin 的默认参数不导出到 Swift，从 Swift 调 `read` 就得自己拼一个 `FileSystem`。
     * 拼错了会读到别的地方。所以留一个参数最少的入口。
     */
    fun readFile(path: String): DesignContractValidationResult = read(path, FileSystem.SYSTEM)

    /** 合同的默认位置。相对仓库根目录。 */
    fun defaultContractPath(): String = "docs/covio-design-contract.json"

    private fun readTokens(node: JsonObject?, diagnostics: MutableList<DesignContractDiagnostic>): List<DesignToken> {
        if (node == null) return emptyList()
        return node.entries.mapNotNull { (key, element) ->
            val path = "tokens/$key"
            val entry = element as? JsonObject
            if (entry == null) {
                diagnostics += DesignContractDiagnostic(DesignContractSeverity.ERROR, path, "不是对象")
                return@mapNotNull null
            }
            if (!key.startsWith("token/")) {
                diagnostics += DesignContractDiagnostic(
                    DesignContractSeverity.ERROR,
                    path,
                    "令牌键不以 token/ 开头",
                )
            }
            val type = entry.string("type")
            if (type == null) {
                diagnostics += DesignContractDiagnostic(DesignContractSeverity.ERROR, path, "缺 type")
                return@mapNotNull null
            }
            val token = DesignToken(
                key = key,
                type = type,
                purpose = entry.string("purpose").orEmpty(),
                light = entry.string("light"),
                dark = entry.string("dark"),
                durationMs = entry.number("durationMs"),
                minMs = entry.number("minMs"),
                maxMs = entry.number("maxMs"),
                reducedMotionMs = entry.number("reducedMotionMs"),
                curve = entry.string("curve"),
            )
            when (type) {
                "color", "dimension" -> {
                    if (token.light == null || token.dark == null) {
                        diagnostics += DesignContractDiagnostic(
                            DesignContractSeverity.ERROR,
                            path,
                            "颜色与尺寸令牌要有 light 与 dark",
                        )
                    }
                }
                "duration" -> {
                    if (!token.hasValidMotionRange) {
                        diagnostics += DesignContractDiagnostic(
                            DesignContractSeverity.ERROR,
                            path,
                            "动效时长的范围不成立：minMs=${token.minMs} durationMs=${token.durationMs} " +
                                "maxMs=${token.maxMs} reducedMotionMs=${token.reducedMotionMs}",
                        )
                    }
                }
                else -> diagnostics += DesignContractDiagnostic(
                    DesignContractSeverity.ERROR,
                    path,
                    "认不出的令牌类型：$type",
                )
            }
            if (token.purpose.isBlank()) {
                diagnostics += DesignContractDiagnostic(DesignContractSeverity.WARNING, path, "缺 purpose")
            }
            token
        }
    }

    private fun readCopy(node: JsonObject?, diagnostics: MutableList<DesignContractDiagnostic>): List<DesignCopyEntry> {
        if (node == null) return emptyList()
        return node.entries.mapNotNull { (key, element) ->
            val path = "copy/$key"
            val entry = element as? JsonObject
            if (entry == null) {
                diagnostics += DesignContractDiagnostic(DesignContractSeverity.ERROR, path, "不是对象")
                return@mapNotNull null
            }
            if (!key.startsWith("copy/")) {
                diagnostics += DesignContractDiagnostic(
                    DesignContractSeverity.ERROR,
                    path,
                    "文案键不以 copy/ 开头",
                )
            }
            val en = entry.string("en")
            val zhHans = entry.string("zh-Hans")
            if (en.isNullOrBlank() || zhHans.isNullOrBlank()) {
                diagnostics += DesignContractDiagnostic(
                    DesignContractSeverity.ERROR,
                    path,
                    "文案要同时有 en 与 zh-Hans，且都不能为空",
                )
                return@mapNotNull null
            }
            DesignCopyEntry(key = key, en = en, zhHans = zhHans)
        }
    }

    private fun readComponents(node: JsonObject?, diagnostics: MutableList<DesignContractDiagnostic>): List<String> {
        if (node == null) return emptyList()
        node.forEach { (key, element) ->
            val path = "components/$key"
            val entry = element as? JsonObject
            if (entry == null) {
                diagnostics += DesignContractDiagnostic(DesignContractSeverity.ERROR, path, "不是对象")
                return@forEach
            }
            // macOS 下每个组件都要有 Swift 落点。
            // schema 的 required 是全局的，表达不了「只在某个平台必填」，
            // 所以这条规则在这里和 scripts/validate-contract.py 里各查一遍。
            val mapping = entry["swiftMapping"] as? JsonObject
            if (mapping == null) {
                diagnostics += DesignContractDiagnostic(
                    DesignContractSeverity.ERROR,
                    path,
                    "缺 swiftMapping。macOS 下每个组件都要有 Swift 落点",
                )
                return@forEach
            }
            if (mapping.string("target").isNullOrBlank()) {
                diagnostics += DesignContractDiagnostic(
                    DesignContractSeverity.ERROR,
                    "$path/swiftMapping",
                    "缺 target",
                )
            }
        }
        return node.keys.sorted()
    }

    private fun readPlatformMappings(
        node: JsonObject?,
        diagnostics: MutableList<DesignContractDiagnostic>,
    ): List<String> {
        if (node == null) return emptyList()
        node.forEach { (key, element) ->
            val path = "platformMapping/$key"
            val entry = element as? JsonObject
            if (entry == null) {
                diagnostics += DesignContractDiagnostic(DesignContractSeverity.ERROR, path, "不是对象")
                return@forEach
            }
            if (entry.string("status") == null) {
                diagnostics += DesignContractDiagnostic(DesignContractSeverity.ERROR, path, "缺 status")
            }
            if (entry.string("swiftRuntimeTarget").isNullOrBlank()) {
                diagnostics += DesignContractDiagnostic(
                    DesignContractSeverity.ERROR,
                    path,
                    "缺 swiftRuntimeTarget",
                )
            }
        }
        return node.keys.sorted()
    }

    private fun missing(section: String) = DesignContractDiagnostic(
        DesignContractSeverity.ERROR,
        section,
        "缺 $section 段，或者它是空的",
    )

    private fun failure(path: String, message: String) = DesignContractValidationResult(
        contract = null,
        diagnostics = listOf(DesignContractDiagnostic(DesignContractSeverity.ERROR, path, message)),
    )

    private fun JsonObject.obj(name: String): JsonObject? = this[name] as? JsonObject

    private fun JsonObject.string(name: String): String? =
        (this[name] as? JsonPrimitive)?.contentOrNull?.takeIf { it.isNotBlank() }

    private fun JsonObject.number(name: String): Double? =
        (this[name] as? JsonPrimitive)?.doubleOrNull
}
