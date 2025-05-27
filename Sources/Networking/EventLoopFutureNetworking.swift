import NIO
import Foundation

public protocol EventLoopFutureNetworking: Networking where Task == Void {

  var eventLoop: EventLoop { get }

  func rawFuture(_ request: Request) -> EventLoopFuture<RawResponse>
}

extension EventLoopFutureNetworking {
  @inlinable
  public func execute(_ request: Request, completion: @escaping @Sendable (RawResult) -> Void) -> Task {
    rawFuture(request).whenComplete { result in
      completion(result.mapError(NetworkingError.network))
    }
  }

//  @inlinable
//  public func waitRawResponse(_ request: Request, taskHandler: ((Task) -> Void)?) throws(NetworkingError) -> RawResponse {
//    do {
//      return try rawFuture(request).wait()
//    } catch {
//      throw .network(error)
//    }
//  }
}
