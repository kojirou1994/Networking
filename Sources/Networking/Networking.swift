@_exported import NIOHTTP1
import Foundation
#if canImport(DictionaryCoding)
import DictionaryCoding
#endif
#if NETWORKING_LOGGING
import os
#endif

public protocol Networking: Sendable {
  associatedtype Request
  associatedtype Response: ResponseProtocol
  associatedtype Task = Void

  associatedtype RawResponseBody: Sendable = [UInt8]

  // body is nil when no body returned
  typealias RawResponse = NetworkingResponse<Response, RawResponseBody?>
  typealias RawResult = Result<RawResponse, NetworkingError>

  typealias EndpointResponse<E: Endpoint> = NetworkingResponse<Response, Result<E.ResponseBody, NetworkingError>>
  typealias EndpointResult<E: Endpoint> = Result<EndpointResponse<E>, NetworkingError>

  var urlComponents: URLComponents { get }
  var commonHTTPHeaders: HTTPHeaders { get }
  /// Used when response body is Decodable and acceptType is json
  var jsonDecoder: JSONDecoder { get }
  var jsonEncoder: JSONEncoder { get }

  #if canImport(DictionaryCoding)
  var dictionaryEncoder: DictionaryEncoder { get }
  #endif

  #if NETWORKING_LOGGING
  @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
  var logger: Logger { get }
  #endif

  func request<E>(_ endpoint: E) throws(NetworkingError) -> Request where E: Endpoint

  /// decode Decodable response
  func decode<ResponseBody>(contentType: ContentType, body: RawResponseBody) -> Result<ResponseBody, NetworkingError> where ResponseBody: Decodable
  /// decode custom response
  func decode<ResponseBody>(body: RawResponseBody) -> Result<ResponseBody, NetworkingError> where ResponseBody: CustomResponseBody

  @discardableResult
  func execute(_ request: Request, completion: @escaping @Sendable (RawResult) -> Void) -> Task

  /// async version of execute(_:completion:)
  func rawResponse(_ request: Request) async -> RawResult

  /// Block the current thread and wait
//  func waitRawResponse(_ request: Request, taskHandler: ((Task) -> Void)?) throws(NetworkingError) -> RawResponse
}

// MARK: Default implementations
extension Networking {
  @inlinable
  public var jsonDecoder: JSONDecoder { .init() }

  @inlinable
  public var jsonEncoder: JSONEncoder { .init() }

  #if canImport(DictionaryCoding)
  @inlinable
  public var dictionaryEncoder: DictionaryEncoder { .init() }
  #endif

  @available(*, unavailable)
  public func waitRawResponse(_ request: Request, taskHandler: ((Task) -> Void)?) throws(NetworkingError) -> RawResponse {
    nonisolated(unsafe)
    var result: RawResult!
    nonisolated(unsafe)
    var taskFinished = false
    let condition = NSCondition()
    condition.lock()

    let task = execute(request) { serverResult in
      condition.lock()
      result = serverResult
      taskFinished = true
      condition.signal()
      condition.unlock()
    }
    taskHandler?(task)

    while !taskFinished {
      condition.wait()
    }
    condition.unlock()

    return try result.get()
  }
}
