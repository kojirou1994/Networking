import Foundation
@_exported import Networking
@_exported import AsyncHTTPClient
import NIO

open class AsyncHTTPClientNetworking: EventLoopFutureNetworking {

  public typealias Request = HTTPClient.Request

  public typealias Response = HTTPClient.Response
  public typealias RawResponseBody = ByteBuffer

  public var urlComponents: URLComponents
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

  public func rawEventLoopFuture(
    _ request: HTTPClient.Request
  ) -> EventLoopFuture<NetworkingResponse<HTTPClient.Response, ByteBuffer>> {
    client.execute(request: request).map { response in
      //        guard endpoint.acceptedStatusCode.contains(numericCast(response.status.code)) else {
      //          throw NetworkingError.invalidStatusCode(numericCast(response.status.code))
      //        }
      return .init(response: response, body: response.body ?? ByteBuffer(ByteBufferView()))
    }
  }

  @inlinable public var eventLoop: EventLoop { client.eventLoopGroup.next() }
}
