package rohy_player_cangjie_bridge

import rohy_player_cangjie_bridge.network.listDirectory

internal import ohos.ark_interop.*

let EXPORT_MODULE = JSModule.registerModule {
    runtime, exports => exports["webdav_listDirectory"] = runtime.function(listDirectory).toJSValue()
}
