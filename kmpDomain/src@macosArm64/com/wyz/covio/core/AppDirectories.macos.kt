package com.wyz.covio.core

import platform.Foundation.NSHomeDirectory

internal actual object AppDirectories {
    actual val home: String = NSHomeDirectory().removeSuffix("/")

    actual val userApplicationSupport: String get() = "$home/Library/Application Support"

    actual val support: String get() = "$userApplicationSupport/$APP_ID"
}
