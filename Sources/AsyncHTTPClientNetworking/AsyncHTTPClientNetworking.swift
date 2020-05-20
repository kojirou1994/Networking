import Foundation
@_exported import Networking
@_exported import AsyncHTTPClient
import NIO

open class AsyncHTTPClientNetworking: EventLoopFutureNetworking {

  public typealias Request = HTTPClient.Request

  public typealias Response = HTTPClient.Response
  public typealias RawResponseBody = ByteBufferView

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
    _ request: Request
  ) -> EventLoopFuture<NetworkingResponse<Response, RawResponseBody>> {
    client.execute(request: request).map { response in
      //        guard endpoint.acceptedStatusCode.contains(numericCast(response.status.code)) else {
      //          throw NetworkingError.invalidStatusCode(numericCast(response.status.code))
      //        }
      let body = response.body ?? ByteBuffer(.init())
      return .init(response: response,
                   body: body.viewBytes(at: body.readerIndex, length: body.readableBytes) ?? ByteBufferView())
    }
  }

  @inlinable public var eventLoop: EventLoop { client.eventLoopGroup.next() }
}
