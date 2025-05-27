import Foundation
@_exported import Networking
@_exported import AsyncHTTPClient
import NIO

extension HTTPClient.Response: ResponseProtocol {}

public protocol AsyncHTTPClientNetworking: EventLoopFutureNetworking
where Request == HTTPClient.Request, Response == HTTPClient.Response, RawResponseBody == ByteBuffer {

  var http: HTTPClient { get }

}

extension AsyncHTTPClientNetworking {

  @inlinable
  public func rawFuture(_ request: Request) -> EventLoopFuture<RawResponse> {
    http.execute(request: request).map { response in
      return (response: response, body: response.body)
    }
  }

  @inlinable
  public var eventLoop: EventLoop {
    http.eventLoopGroup.next()
  }

  @available(macOS 10.15, *)
  @inlinable
  public func rawResponse(_ request: Request) async -> RawResult {
    await withCheckedContinuation { continuation in
      rawFuture(request).whenComplete { result in
        continuation.resume(returning: result.mapError(NetworkingError.network))
      }
    }
  }

}


