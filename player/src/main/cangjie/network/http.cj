package rohy_player_cangjie_bridge.network
import std.collection.Map
import net.http.ClientBuilder
import net.http.HttpRequest
import net.http.HttpRequestBuilder
import encoding.url.URL
import net.http.HttpHeaders
import net.http.HttpResponse
import net.tls.TlsClientConfig
import net.http.Client
import net.tls.CertificateVerifyMode

func createClient(): Client {
    let builder = ClientBuilder()
    var tlsConfig = TlsClientConfig()
    tlsConfig.verifyMode = CertificateVerifyMode.TrustAll
    builder.tlsConfig(tlsConfig)
    builder.build()
}

public func httpRequest(url: String, method: String, headers: Map<String, String>): (Client, HttpResponse) {
    let client = createClient()
    let httpHeaders = HttpHeaders()
    for ((k, v) in headers) {
    	httpHeaders.add(k, v)
    }
    let httpRequest = HttpRequestBuilder()
    .url(URL.parse(url))
    .method(method)
    .setHeaders(httpHeaders)
    .build()

    return (client, client.send(httpRequest))
}