package rohy_player_cangjie_bridge.network

internal import ohos.ark_interop.*
import rohy_player_cangjie_bridge.util.stringMapOf
import std.io.StringReader

public func listDirectory(runtime: JSContext, callInfo: JSCallInfo): JSValue {
    let path = callInfo[0].toString(runtime)
    let authorization = callInfo[1].toString(runtime)
    let (client, response) = httpRequest(path, "PROPFIND", stringMapOf("authorization", authorization))
    if (response.status == 200) {
        let inputStream = response.body
        var result = StringReader(response.body).readToEnd()
        client.close()
        return runtime.string(result).toJSValue()
    } else {
        client.close()
        return runtime.undefined().toJSValue()
    }
}

