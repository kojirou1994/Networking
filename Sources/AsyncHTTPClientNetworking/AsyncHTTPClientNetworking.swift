import AsyncHTTPClient
import Networking
import Foundation
import NIOHTTP1
import NIOFoundationCompat
import NIO

open class AsyncHTTPClientNetworking: Networking {

  public typealias Response = HTTPClient.Response
  public typealias RawResponseBody = ByteBuffer

  open var urlComponents: URLComponents
  public var commonHTTPHeaders: HTTPHeaders
  public let jsonDecoder: JSONDecoder
  public let jsonEncoder: JSONEncoder
  public let client: HTTPClient

  public init(client: HTTPClient) {
    self.client = client
    urlComponents = .init()
    urlComponents.queryItems = []
    commonHTTPHeaders = .init()
    jsonDecoder = .init()
    jsonEncoder = .init()
  }

  @usableFromInline
  func request<E>(_ endpoint: E) throws -> HTTPClient.Request where E: Endpoint {
    var components = urlComponents
    components.path = endpoint.path
    components.queryItems?.append(contentsOf: endpoint.queryItems)

    var headers = HTTPHeaders()
    headers.add(name: "Accept", value: endpoint.acceptType.rawValue)
    if endpoint.method != .GET {
        headers.add(name: "Content-Type", value: endpoint.contentType.rawValue)
    }
    headers.add(contentsOf: commonHTTPHeaders)
    headers.add(contentsOf: endpoint.headers)
    
    let body: HTTPClient.Body?
    switch endpoint.contentType {
    case .json:
      body = .data(try jsonEncoder.encode(endpoint.body))
    case .empty: body = nil
    }
    let url = components.url!
    let request = try HTTPClient.Request(url: url, method: endpoint.method, body: body)
    return request
  }

  @usableFromInline
  func decode<E>(_ endpoint: E, body: ByteBuffer) throws -> E.ResponseBody where E: Endpoint {
    switch endpoint.acceptType {
    case .json:
      return try jsonDecoder.decode(E.ResponseBody.self, from: body)
    case .empty: fatalError()
    }
  }

  public func executeRaw<E>(_ endpoint: E, completion: @escaping (Result<NetworkingResponse<Response, ByteBuffer>, Error>) -> Void) where E : Endpoint {
    executeRawFuture(endpoint).whenComplete(completion)
  }

  public func execute<E>(_ endpoint: E, completion: @escaping (Result<NetworkingResponse<Response, E.ResponseBody>, Error>) -> Void) where E : Endpoint {
    executeFuture(endpoint).whenComplete(completion)
  }

  public func executeFuture<E>(_ endpoint: E) -> EventLoopFuture<NetworkingResponse<Response, E.ResponseBody>> where E : Endpoint {
    executeRawFuture(endpoint)
      .flatMapThrowing { rawResponse in
        if E.ResponseBody.self == EmptyBody.self {
          return .init(response: rawResponse.response, body: EmptyBody() as! E.ResponseBody)
        }
        guard rawResponse.body.readableBytes > 0 else {
          throw NetworkingError.emptyResponseBody
        }

        return .init(response: rawResponse.response, body: try self.decode(endpoint, body: rawResponse.body))
    }
  }

  public func executeRawFuture<E>(_ endpoint: E) -> EventLoopFuture<NetworkingResponse<Response, ByteBuffer>> where E : Endpoint {
    do {
      return client.execute(request: try request(endpoint))
        .flatMapThrowing{ (response) -> NetworkingResponse<Response, ByteBuffer> in
          guard endpoint.acceptedStatusCode.contains(numericCast(response.status.code)) else {
            throw NetworkingError.invalidStatusCode(numericCast(response.status.code))
          }
          return .init(response: response, body: response.body ?? ByteBuffer(ByteBufferView()))
      }
    } catch {
      return client.eventLoopGroup.next().makeFailedFuture(error)
    }
  }
}
