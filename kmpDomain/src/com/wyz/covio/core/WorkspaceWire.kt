package com.wyz.covio.core

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

/**
 * 工作区与对端之间的线格式。
 *
 * 字段与操作名与 `docs/research/shared-transfer-workspace/solution.md` 第 2 节一致：
 * 请求是 `{request_id, op, args}`，响应是 `{ok, data, error_code, error_message}`。
 * 传输层由跨设备主题提供，这里只管信封与字段。
 *
 * **单位在这一层是毫秒。** 契约第 2.2 节写的是 UTC 毫秒，本地索引用的是秒。
 * 转换只在 [WorkspaceWire.args] 与 [WorkspaceWire.entry] 两处发生。
 */
object WorkspaceWire {
    const val OP_LIST = "workspace.list"
    const val OP_PUT = "workspace.put"
    const val OP_FETCH = "workspace.fetch"
    const val OP_DELETE = "workspace.delete"
    const val OP_STAT = "workspace.stat"
    const val OP_CHUNK = "transfer.chunk"
    const val OP_COMMIT = "transfer.commit"
    const val OP_CANCEL = "transfer.cancel"

    /**
     * 线格式的读写。
     *
     * `encodeDefaults` 关着，所以等于默认值的字段不写出去：
     * 没有参数的操作就没有 `args`，成功的响应就没有 `error_code`。
     * 契约里必须出现的字段（`ok`、`request_id`、`op`）不设默认值，因此总会写出去。
     */
    private val json = Json {
        encodeDefaults = false
        ignoreUnknownKeys = true
    }

    fun encode(request: WorkspaceRequest): String =
        json.encodeToString(WorkspaceRequest.serializer(), request)

    fun decodeRequest(text: String): WorkspaceRequest? =
        runCatching { json.decodeFromString(WorkspaceRequest.serializer(), text) }.getOrNull()

    fun encode(response: WorkspaceResponse): String =
        json.encodeToString(WorkspaceResponse.serializer(), response)

    fun decodeResponse(text: String): WorkspaceResponse? =
        runCatching { json.decodeFromString(WorkspaceResponse.serializer(), text) }.getOrNull()

    /** 成功的响应。 */
    fun ok(data: WorkspaceResponseData? = null): WorkspaceResponse =
        WorkspaceResponse(ok = true, data = data, errorCode = null, errorMessage = null)

    /** 失败的响应。错误码用线格式。 */
    fun failed(errorCode: WorkspaceErrorCode, errorMessage: String = ""): WorkspaceResponse =
        WorkspaceResponse(ok = false, data = null, errorCode = errorCode.wire, errorMessage = errorMessage)

    /**
     * 把一个条目变成请求参数。
     *
     * 放入方发出去的就是这一份。`availability` 表示本机有没有内容，
     * 接收方只当参考，它按自己的情况决定。
     */
    fun args(of: WorkspaceEntry): WorkspaceArgs = WorkspaceArgs(
        entryId = of.entryId,
        kind = of.kind.wire,
        displayName = of.displayName,
        byteSize = of.byteSize,
        contentType = of.contentType,
        createdAtEpochMillis = of.createdAtEpochSeconds * 1_000L,
        expiresAtEpochMillis = of.expiresAtEpochSeconds * 1_000L,
        originDeviceId = of.originDeviceId,
        availability = of.availability.wire,
    )

    /**
     * 把请求参数还原成条目。
     *
     * 摘要是内容寻址的依据，类别决定用哪个图标与哪种预览。
     * 两者有一个认不出来就不该接下这次复制。
     */
    fun entry(from: WorkspaceArgs): WorkspaceEntryParse {
        val id = normalizeEntryId(from.entryId.orEmpty())
        if (!WorkspaceLogic.isValidEntryId(id)) return WorkspaceEntryParse.BadDigest
        val kind = workspaceKindOf(from.kind.orEmpty()) ?: return WorkspaceEntryParse.BadKind
        return WorkspaceEntryParse.Ok(
            WorkspaceEntry(
                entryId = id,
                kind = kind,
                displayName = from.displayName.orEmpty(),
                byteSize = (from.byteSize ?: 0L).coerceAtLeast(0L),
                contentType = from.contentType.orEmpty(),
                createdAtEpochSeconds = (from.createdAtEpochMillis ?: 0L).coerceAtLeast(0L) / 1_000L,
                originDeviceId = from.originDeviceId.orEmpty(),
                expiresAtEpochSeconds = (from.expiresAtEpochMillis ?: 0L).coerceAtLeast(0L) / 1_000L,
                // 接收方的状态由接收方定，发送方说的不算。
                availability = WorkspaceAvailability.LOCAL,
            ),
        )
    }
}

/** 线格式上的类别写法。契约第 2.2 节用小写单词。 */
internal val WorkspaceKind.wire: String get() = name.lowercase()

/** 线格式上的内容状态写法。 */
internal val WorkspaceAvailability.wire: String get() = name.lowercase()

/** 按线格式找类别。认不出来返回 null。 */
internal fun workspaceKindOf(value: String): WorkspaceKind? =
    WorkspaceKind.entries.firstOrNull { it.wire == value.trim().lowercase() }

/**
 * 对端回的错误码。写法与契约第 2.6 节一致。
 *
 * 枚举名转小写就是线格式，所以不必逐个标注。
 */
enum class WorkspaceErrorCode {
    QUOTA_EXCEEDED,
    ENTRY_EXPIRED,
    ENTRY_NOT_FOUND,
    CONTENT_UNAVAILABLE,
    UNSUPPORTED_KIND,
    SHARE_DENIED,
    STORAGE_FULL,
    CHECKSUM_MISMATCH,
    PEER_OFFLINE,
    LOCAL_NETWORK_DENIED,
    ;

    val wire: String get() = name.lowercase()

    companion object {
        /** 按线格式找错误码。认不出来返回 null。 */
        fun fromWire(value: String): WorkspaceErrorCode? =
            entries.firstOrNull { it.wire == value.trim().lowercase() }
    }
}

/** 一条请求。`op` 是 [WorkspaceWire] 里的操作名。 */
@Serializable
data class WorkspaceRequest(
    @SerialName("request_id") val requestId: String,
    @SerialName("op") val op: String,
    @SerialName("args") val args: WorkspaceArgs = WorkspaceArgs(),
)

/**
 * 所有操作共用的参数表。
 *
 * 每个操作只用其中几项，所以字段都可空。等于默认值的项不写到线上去。
 */
@Serializable
data class WorkspaceArgs(
    @SerialName("entry_id") val entryId: String? = null,
    @SerialName("kind") val kind: String? = null,
    @SerialName("display_name") val displayName: String? = null,
    @SerialName("byte_size") val byteSize: Long? = null,
    @SerialName("content_type") val contentType: String? = null,
    @SerialName("created_at") val createdAtEpochMillis: Long? = null,
    @SerialName("expires_at") val expiresAtEpochMillis: Long? = null,
    @SerialName("origin_device_id") val originDeviceId: String? = null,
    @SerialName("availability") val availability: String? = null,
    @SerialName("task_id") val taskId: String? = null,
    @SerialName("offset") val offset: Long? = null,
    @SerialName("length") val length: Long? = null,
    @SerialName("sha256") val sha256: String? = null,
    @SerialName("since") val since: Long? = null,
    @SerialName("limit") val limit: Int? = null,
)

/** 一条响应。`ok` 与 `data`、`errorCode` 互斥。 */
@Serializable
data class WorkspaceResponse(
    @SerialName("ok") val ok: Boolean,
    @SerialName("data") val data: WorkspaceResponseData? = null,
    @SerialName("error_code") val errorCode: String? = null,
    @SerialName("error_message") val errorMessage: String? = null,
)

/** 响应正文。每个操作只用其中几项。 */
@Serializable
data class WorkspaceResponseData(
    @SerialName("accepted") val accepted: Boolean? = null,
    @SerialName("task_id") val taskId: String? = null,
    @SerialName("received") val received: Long? = null,
    @SerialName("entries") val entries: List<WorkspaceArgs>? = null,
    @SerialName("total_bytes") val totalBytes: Long? = null,
    @SerialName("max_total_bytes") val maxTotalBytes: Long? = null,
    @SerialName("entry_count") val entryCount: Int? = null,
)

/** 请求参数还原成条目的三种结局。 */
sealed interface WorkspaceEntryParse {
    data class Ok(val entry: WorkspaceEntry) : WorkspaceEntryParse

    /** 摘要不是合法的 SHA-256。 */
    data object BadDigest : WorkspaceEntryParse

    /** 类别不在支持列表里。 */
    data object BadKind : WorkspaceEntryParse
}
