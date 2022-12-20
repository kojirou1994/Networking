import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension HTTPURLResponse: ResponseProtocol {
  public var status: HTTPResponseStatus {
    .init(statusCode: statusCode)
  }

  public var headers: HTTPHeaders {
    var result = HTTPHeaders()
    allHeaderFields.forEach { kv in
      result.add(name: kv.key as! String, value: kv.value as! String)
    }
    return result
  }

}

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
  public func execute(_ request: Request, completion: @escaping (RawResult) -> Void) -> Task {
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
      completion(.success((response: res, body: data ?? Data())))
    }
    if autoResume {
      task.resume()
    }
    return task
  }

  public func rawResponse(_ request: Request) async throws -> RawResponse {
    #if canImport(Darwin)
    if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *) {
      let (data, response) = try await session.data(for: request)
      return (response as! HTTPURLResponse, data)
    }
    #endif
    assert(autoResume)
    return try await withCheckedThrowingContinuation { continuation in
      execute(request) { result in
        continuation.resume(with: result)
      }
    }
  }
}
