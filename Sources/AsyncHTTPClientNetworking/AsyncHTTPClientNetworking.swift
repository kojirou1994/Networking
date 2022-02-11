import Foundation
@_exported import Networking
@_exported import AsyncHTTPClient
import NIO

extension HTTPClient.Response: ResponseProtocol {}

public protocol AsyncHTTPClientNetworking: EventLoopFutureNetworking, StreamNetworking
where Request == HTTPClient.Request, Response == HTTPClient.Response, RawResponseBody == ByteBufferView,
      StreamTask == HTTPClient.Task<Void> {

  var http: HTTPClient { get }

}

extension AsyncHTTPClientNetworking {

  @inlinable
  public func eventLoopFuture(_ request: Request) -> EventLoopFuture<NetworkingResponse<Response, RawResponseBody>> {
    client.execute(request: request).map { response in
      let body = response.body ?? ByteBuffer(.init())
      return (response: response,
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
