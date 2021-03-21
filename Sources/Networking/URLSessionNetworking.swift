import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol URLSessionNetworking: Networking
where Request == URLRequest, Response == HTTPURLResponse,
      RawResponseBody == Data, Task == URLSessionTask {

  var session: URLSession { get }

  /// auto call URLSessionTask.resume()
  var autoResume: Bool { get }

}

extension URLSessionNetworking {

  @inlinable
  public var autoResume: Bool {
    false
  }

  @discardableResult
  public func execute(_ request: URLRequest, completion: @escaping (RawResult) -> Void) -> Task {
    let task = session.dataTask(with: request) { data, response, error in
      guard error == nil else {
        #if NETWORKING_LOGGING
        if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
          logger.error("URLRequest execute failed! Error: \((error as! URLError).localizedDescription)")
        }
        #endif
        completion(.failure(error as! URLError))
        return
      }
      let res = response as! HTTPURLResponse
      #if NETWORKING_LOGGING
      if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
        logger.debug("URLRequest execute successed!")
        logger.debug("Response status code: \(res.statusCode)")
        logger.debug("Response headers: \(res.allHeaderFields)")
        logger.debug("Response body: \(data?.count ?? 0) bytes")
      }
      #endif
      completion(.success(.init(response: res, body: data ?? Data())))
    }
    if autoResume {
      task.resume()
    }
    return task
  }
}
