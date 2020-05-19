import NIO

public protocol EventLoopFutureNetworking: Networking {

  var eventLoop: EventLoop {get}

  func rawEventLoopFuture(_ request: Request) -> EventLoopFuture<NetworkingResponse<Response, RawResponseBody>>
}

extension EventLoopFutureNetworking {

  @inlinable
  public func rawEventLoopFuture<E>(_ endpoint: E) -> EventLoopFuture<NetworkingResponse<Response, RawResponseBody>> where E : Endpoint {
    do {
      return rawEventLoopFuture(try request(endpoint))
    } catch {
      return eventLoop.makeFailedFuture(error)
    }
  }

  @inlinable
  public func executeRaw(_ request: Request, completion: @escaping (RawResult) -> Void) {
    rawEventLoopFuture(request).whenComplete(completion)
  }

  public func eventLoopFuture<E>(_ endpoint: E) -> EventLoopFuture<NetworkingResponse<Response, Result<E.ResponseBody, Error>>> where E : Endpoint, E.ResponseBody: Decodable {
    rawEventLoopFuture(endpoint)
      .map { rawResponse in
        .init(response: rawResponse.response, body: .init{try self.decode(endpoint, body: rawResponse.body)})
    }
  }
}
