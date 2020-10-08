import Foundation
import NIOFoundationCompat
import NIO

extension Networking where Request == HTTPClient.Request {
  public func request<E>(_ endpoint: E) throws -> Request where E: Endpoint {
    try _request(endpoint)
  }

  public func request<E>(_ endpoint: E) throws -> Request where E: Endpoint, E.RequestBody: Encodable {
    var request = try _request(endpoint)

    switch endpoint.contentType {
    case .json:
      request.body = .data(try! jsonEncoder.encode(endpoint.body))
    case .none: break // Already checked
    case .wwwFormUrlEncoded:
      request.body = .string(try wwwFormUrlEncodedBody(for: endpoint.body))
    }
    return request
  }

  public func request<E>(_ endpoint: E) throws -> Request where E: Endpoint, E.RequestBody: CustomRequestBody {
    var request = try _request(endpoint)
    var body = ByteBufferView()
    try endpoint.body.write(to: &body)
    request.body = .byteBuffer(ByteBuffer(body))
    return request
  }

  public func request<E>(_ endpoint: E) throws -> Request where E: Endpoint, E.RequestBody: MultipartRequestBody {
    fatalError("Unimplemented")
  }
  public func request<E>(_ endpoint: E) throws -> Request where E: Endpoint, E.RequestBody: StreamRequestBody {
    fatalError("Unimplemented")
  }

  func _request<E>(_ endpoint: E) throws -> Request where E: Endpoint {
    endpoint.check()
    var headers = HTTPHeaders()
    if endpoint.method != .GET {
      headers.add(name: "Content-Type", value: endpoint.contentType.headerValue)
    }
    if endpoint.acceptType != .none {
      headers.add(name: "Accept", value: endpoint.acceptType.headerValue)
    }
    headers.add(contentsOf: commonHTTPHeaders)
    headers.add(contentsOf: endpoint.headers)

    return try HTTPClient.Request(url: url(for: endpoint), method: endpoint.method, headers: headers)
  }

}
