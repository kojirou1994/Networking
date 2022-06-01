import NIO
import Foundation

public protocol EventLoopFutureNetworking: Networking where Task == Void {

  var eventLoop: EventLoop { get }

  func eventLoopFuture(_ request: Request) -> EventLoopFuture<RawResponse>
}

extension EventLoopFutureNetworking {
  @inlinable
  public func execute(_ request: Request, completion: @escaping (RawResult) -> Void) -> Task {
    eventLoopFuture(request).whenComplete(completion)
  }

  @inlinable
  public func waitRawResponse(_ request: Request, taskHandler: ((Task) -> Void)?) throws -> RawResponse {
    try eventLoopFuture(request).wait()
  }
}
