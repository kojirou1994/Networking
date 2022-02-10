import Foundation
@_exported import Networking
@_exported import AsyncHTTPClient
import NIO

public protocol AsyncHTTPClientNetworking: EventLoopFutureNetworking
where Request == HTTPClient.Request, Response == HTTPClient.Response, RawResponseBody == ByteBufferView {

  var http: HTTPClient { get }

}

extension AsyncHTTPClientNetworking {

  @inlinable
  public func eventLoopFuture(_ request: Request) -> EventLoopFuture<NetworkingResponse<Response, RawResponseBody>> {
    client.execute(request: request).map { response in
      let body = response.body ?? ByteBuffer(.init())
      return .init(response: response,
                   body: body.viewBytes(at: body.readerIndex, length: body.readableBytes) ?? ByteBufferView())
    }
  }

  @inlinable
  public var eventLoop: EventLoop {
    client.eventLoopGroup.next()
  }

  @available(* ,renamed: "http")
  @inlinable
  var client: HTTPClient { http }
}
