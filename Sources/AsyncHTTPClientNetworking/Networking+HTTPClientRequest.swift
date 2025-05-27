import Foundation
import NIOFoundationCompat
import NIO
import AsyncHTTPClient
import AnyEncodable

extension Networking where Request == HTTPClient.Request {
  public func request<E>(_ endpoint: E) throws -> Request where E: Endpoint {
    var request = try baseRequest(endpoint)
    guard E.RequestBody.self != Void.self else {
      return request
    }
    if let encodable = endpoint.body as? Encodable {
      let body = AnyEncodable(encodable)
      switch endpoint.contentType {
      case .json:
        request.body = .data(try! jsonEncoder.encode(body))
      case .none: break // Already checked
      case .wwwFormUrlEncoded:
        request.body = .string(try wwwFormUrlEncodedBody(for: body))
      }
    } else if let custom = endpoint.body as? CustomRequestBody {
      var body = ByteBufferView()
      try custom.write(to: &body)
      request.body = .byteBuffer(ByteBuffer(body))
    } else if let multipart = endpoint.body as? MultipartRequestBody {
      fatalError("Unimplemented multipart \(multipart)")
    } else if let stream = endpoint.body as? StreamRequestBody {
      fatalError("Unimplemented stream \(stream)")
    } else {
      fatalError("Unsupported RequestBody type: \(E.self)")
    }
    return request
  }

  func baseRequest<E>(_ endpoint: E) throws -> Request where E: Endpoint {
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
  public func stream<E>(_ endpoint: E, receiveCompletion: @escaping @Sendable (Result<Void, Error>) -> Void, receiveValue: @escaping @Sendable (RawResponseBody) -> Void) throws -> StreamTask where E: Endpoint {
    let request = try request(endpoint)
    return http.execute(request: request, delegate: StreamDelegate(receiveCompletion: receiveCompletion, receiveValue: receiveValue), deadline: nil)
  }
}

final class StreamDelegate: HTTPClientResponseDelegate, @unchecked Sendable {
  internal init(receiveCompletion: @escaping @Sendable (Result<Void, Error>) -> Void, receiveValue: @escaping @Sendable (ByteBufferView) -> Void) {
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

  let receiveCompletion: @Sendable (Result<Void, Error>) -> Void
  let receiveValue: @Sendable (ByteBufferView) -> Void
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
