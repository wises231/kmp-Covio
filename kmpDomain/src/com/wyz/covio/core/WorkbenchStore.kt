package com.wyz.covio.core

import com.wyz.covio.domain.EngineLock
import kotlinx.serialization.DeserializationStrategy
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonPrimitive
import okio.FileSystem
import okio.Path
import okio.Path.Companion.toPath

/**
 * `workbench.json` 的读写。
 *
 * 单独一个文件，不与 `config.json` 合并。两条理由：
 *
 * 1. `config.json` 承诺与 0.4.2 双向兼容（见 [ConfigStore]）。工作台配置是 0.5.0
 *    新加的，不用背这个包袱。
 * 2. 需求 F7 要求工作台配置损坏时回退默认布局。分成两个文件后，坏掉一个不影响另一个。
 *
 * 用 okio 而不是 `java.nio.file`，因为同一份代码要跑在 jvm 与 macosArm64 上。
 *
 * **坏文件不整份丢。** 一条工作区坏掉时只丢那一条，其余照常读出来。
 * 整份都读不出来时才回退默认布局。见 [load] 与 [WorkbenchConfig.normalized]。
 */
class WorkbenchStore(
    val path: String = defaultWorkbenchPath(),
    private val fileSystem: FileSystem = FileSystem.SYSTEM,
    private val json: Json = defaultJson(),
) {
    private val lock = EngineLock()

    /**
     * 读配置。文件不存在、读不动、或者整份坏掉时返回默认布局。
     *
     * 读的时候不写盘。文件不存在时也照样返回默认布局，不建空文件：
     * 建了之后用户没改过设置也会留下一个文件，卸载时不好判断该不该删。
     */
    fun load(): WorkbenchConfig = lock.withLock {
        val target = path.toPath()
        if (!fileSystem.exists(target)) return@withLock WorkbenchConfig.defaults()
        runCatching {
            val root = json.parseToJsonElement(fileSystem.read(target) { readUtf8() }) as? JsonObject
                ?: return@runCatching WorkbenchConfig.defaults()
            decode(root)
        }.getOrElse { WorkbenchConfig.defaults() }.normalized()
    }

    /**
     * 写配置，返回规范化之后的结果。
     *
     * 写之前先读回现有 JSON 再合并，所以本版不认识的顶层键会被保留。
     * 与 [ConfigStore.save] 同一条约定。
     *
     * **写盘失败不抛异常。** Kotlin 的异常跨到 Swift 没有接收方，会直接终止进程
     * （`Function doesn't have or inherit @Throws annotation`）。磁盘满、目录被删、
     * 权限不对都会走到这里，而调用方是每次改布局都会跑的落盘。所以失败时和
     * [load] 与 [clear] 一样咽掉：内存里的配置照常生效，只是这一版没落盘。
     */
    fun save(config: WorkbenchConfig): WorkbenchConfig = lock.withLock {
        val normalized = config.normalized()
        runCatching {
            val target = path.toPath()
            target.parent?.let { fileSystem.createDirectories(it) }

            val existing = runCatching {
                json.parseToJsonElement(fileSystem.read(target) { readUtf8() }) as? JsonObject
            }.getOrNull() ?: JsonObject(emptyMap())

            val merged = JsonObject(existing.toMutableMap().apply {
                putAll(json.encodeToJsonElement(WorkbenchConfig.serializer(), normalized) as JsonObject)
            })

            val temporary = temporaryPath(target)
            fileSystem.write(temporary) { writeUtf8(json.encodeToString(JsonObject.serializer(), merged)) }
            fileSystem.atomicMove(temporary, target)
        }
        normalized
    }

    fun clear(): Boolean = lock.withLock {
        runCatching {
            val target = path.toPath()
            fileSystem.delete(target, mustExist = false)
            fileSystem.delete(temporaryPath(target), mustExist = false)
        }.isSuccess
    }

    private fun temporaryPath(target: Path): Path = target.parent!!.resolve(target.name + ".tmp")

    /**
     * 按字段读。一个字段坏了不影响别的字段，与 [ConfigStore] 的读法一致。
     *
     * `panes` 与 `homeWidgets` 逐条读：一条坏掉只丢那一条。
     * 整条读的话，一个认不出的种类会让整份配置回退默认布局。
     */
    private fun decode(root: JsonObject): WorkbenchConfig {
        val defaults = WorkbenchConfig.defaults()
        return WorkbenchConfig(
            schemaVersion = root["schemaVersion"]?.jsonPrimitive?.intOrNull ?: defaults.schemaVersion,
            panes = decodeEach(root["panes"], PaneInstance.serializer()),
            homeWidgets = decodeEach(root["homeWidgets"], WidgetInstance.serializer()),
        )
    }

    private fun <T> decodeEach(element: JsonElement?, serializer: DeserializationStrategy<T>): List<T> {
        val array = element as? JsonArray ?: return emptyList()
        return array.mapNotNull { item ->
            runCatching { json.decodeFromJsonElement(serializer, item) }.getOrNull()
        }
    }

    companion object {
        /**
         * 按路径构造一个工作台存储。
         *
         * Swift 侧不能走主构造函数：`json` 与 `fileSystem` 的默认值在 Kotlin 里，
         * 默认参数不导出到 Swift，从 Swift 就得自己拼一个 `Json`。
         * 拼出来的设置可能与这里不一致，那会让两版写出的 `workbench.json` 不同。
         * 所以统一从这一个入口构造。与 `ConfigStore.create` 同一个理由。
         */
        fun create(path: String = defaultWorkbenchPath()): WorkbenchStore =
            WorkbenchStore(path = path, fileSystem = FileSystem.SYSTEM, json = defaultJson())

        internal fun defaultJson(): Json = Json {
            prettyPrint = true
            ignoreUnknownKeys = true
            encodeDefaults = true
        }
    }
}
