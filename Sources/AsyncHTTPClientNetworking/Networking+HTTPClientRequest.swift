import Foundation
import NIOFoundationCompat
import NIO
import AsyncHTTPClient

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
    if endpoint.contentType != .none {
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

extension AsyncHTTPClientNetworking where Request == HTTPClient.Request {
  public func stream<E>(_ endpoint: E, receiveCompletion: @escaping (Result<Void, Error>) -> Void, receiveValue: @escaping (RawResponseBody) -> Void) throws -> StreamTask where E: Endpoint {
    let request = try request(endpoint)
    return http.execute(request: request, delegate: StreamDelegate(receiveCompletion: receiveCompletion, receiveValue: receiveValue), deadline: nil)
  }
}

final class StreamDelegate: HTTPClientResponseDelegate {
  internal init(receiveCompletion: @escaping (Result<Void, Error>) -> Void, receiveValue: @escaping (ByteBufferView) -> Void) {
    self.receiveCompletion = receiveCompletion
    self.receiveValue = receiveValue
  }

  func didFinishRequest(task: HTTPClient.Task<Void>) throws -> Void {
    if let error = error {
      receiveCompletion(.failure(error))
    } else {
      receiveCompletion(.success(()))
    }
  }

  let receiveCompletion: (Result<Void, Error>) -> Void
  let receiveValue: (ByteBufferView) -> Void
  var error: Error?

  typealias Response = Void

  func didReceiveError(task: HTTPClient.Task<Void>, _ error: Error) {
    self.error = error
  }

  func didReceiveBodyPart(task: HTTPClient.Task<Void>, _ buffer: ByteBuffer) -> EventLoopFuture<Void> {
    receiveValue(.init(buffer))
    return task.eventLoop.makeSucceededFuture(())
  }

}
