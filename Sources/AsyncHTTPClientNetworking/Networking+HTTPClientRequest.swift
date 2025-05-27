import Foundation
import NIOFoundationCompat
import NIO
import AsyncHTTPClient
import AnyEncodable

extension Networking where Request == HTTPClient.Request {
  public func request<E>(_ endpoint: E) throws(NetworkingError) -> Request where E: Endpoint {
    endpoint.check()
    var request = try! HTTPClient.Request(url: url(for: endpoint), method: endpoint.method, headers: headers(for: endpoint))
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

  func headers<E>(for endpoint: E) -> HTTPHeaders where E: Endpoint {
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

    return headers
  }

  public func asyncRequest<E>(_ endpoint: E) throws(NetworkingError) -> HTTPClientRequest where E: Endpoint {
    endpoint.check()
    var request = try HTTPClientRequest(url: url(for: endpoint).absoluteString)
    request.method = endpoint.method
    request.headers = headers(for: endpoint)
    guard E.RequestBody.self != Void.self else {
      return request
    }
    if let encodable = endpoint.body as? Encodable {
      let body = AnyEncodable(encodable)
      switch endpoint.contentType {
      case .json:
        request.body = .bytes(try! jsonEncoder.encode(body))
      case .none: break // Already checked
      case .wwwFormUrlEncoded:
        request.body = .bytes(try Array(wwwFormUrlEncodedBody(for: body).utf8))
      }
    } else if let custom = endpoint.body as? CustomRequestBody {
      var body = ByteBufferView()
      try custom.write(to: &body)
      request.body = .bytes(ByteBuffer(body))
    } else if let multipart = endpoint.body as? MultipartRequestBody {
      fatalError("Unimplemented multipart \(multipart)")
    } else if let stream = endpoint.body as? StreamRequestBody {
      fatalError("Unimplemented stream \(stream)")
    } else {
      fatalError("Unsupported RequestBody type: \(E.self)")
    }
    return request
  }

}

public extension AsyncHTTPClientNetworking {

  func segmentedBody<E>(_ endpoint: E, timeout: TimeAmount = .seconds(8)) async throws -> AsyncThrowingMapSequence<HTTPClientResponse.Body, E.ResponseBody> where E: Endpoint, E.ResponseBody: Decodable {
    let request = try asyncRequest(endpoint)
    let response = try await http.execute(request, timeout: timeout)
    let acceptType = endpoint.acceptType

    return response.body.map { buf throws(NetworkingError) -> E.ResponseBody in
      try self.decode(contentType: acceptType, body: buf).get()
    }
  }

}

public final class HTTPAsyncStreamDelegate: HTTPClientResponseDelegate, @unchecked Sendable {

  @inlinable
  public init(receiveCompletion: @escaping @Sendable (Result<Void, NetworkingError>) -> Void, receiveValue: @escaping @Sendable (ByteBuffer) -> Void) {
    self.receiveCompletion = receiveCompletion
    self.receiveValue = receiveValue
  }

  public func didFinishRequest(task: HTTPClient.Task<Void>) throws -> Void {
    if let error = error {
      receiveCompletion(.failure(.network(error)))
    } else {
      receiveCompletion(.success(()))
    }
  }
  @usableFromInline
  let receiveCompletion: @Sendable (Result<Void, NetworkingError>) -> Void
  @usableFromInline
  let receiveValue: @Sendable (ByteBuffer) -> Void
  var error: Error?

  public typealias Response = Void

  public func didReceiveError(task: HTTPClient.Task<Void>, _ error: Error) {
    self.error = error
  }

  public func didReceiveBodyPart(task: HTTPClient.Task<Void>, _ buffer: ByteBuffer) -> EventLoopFuture<Void> {
    receiveValue(buffer)
    return task.eventLoop.makeSucceededFuture(())
  }

}
