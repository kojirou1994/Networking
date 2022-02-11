@_exported import NIOHTTP1
import Foundation
import DictionaryCoding
import os

public protocol Networking {
  associatedtype Request
  associatedtype Response: ResponseProtocol
  associatedtype Task = Void

  associatedtype RawResponseBody = [UInt8]

  typealias RawResponse = NetworkingResponse<Response, RawResponseBody>
  typealias RawResult = Result<RawResponse, Error>

  typealias EndpointResponse<E: Endpoint> = NetworkingResponse<Response, Result<E.ResponseBody, Error>>
  typealias EndpointResult<E: Endpoint> = Result<EndpointResponse<E>, Error>

  var urlComponents: URLComponents { get }
  var commonHTTPHeaders: HTTPHeaders { get }
  /// Used when response body is Decodable and acceptType is json
  var jsonDecoder: JSONDecoder { get }
  var jsonEncoder: JSONEncoder { get }
  var dictionaryEncoder: DictionaryEncoder { get }

  #if NETWORKING_LOGGING
  @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
  var logger: Logger { get }
  #endif

  func request<E>(_ endpoint: E) throws -> Request where E: Endpoint
  func request<E>(_ endpoint: E) throws -> Request where E: Endpoint, E.RequestBody: Encodable

  /// decode Decodable response
  func decode<E>(_ endpoint: E, body: RawResponseBody) throws -> E.ResponseBody where E: Endpoint, E.ResponseBody: Decodable
  /// decode custom response
  func decode<E>(_ endpoint: E, body: RawResponseBody) throws -> E.ResponseBody where E: Endpoint, E.ResponseBody: CustomResponseBody

  @discardableResult
  func execute(_ request: Request, completion: @escaping (RawResult) -> Void) -> Task

//  #if compiler(>=5.5.2)
//  func execute(_ request: Request) async throws -> RawResponse
//  #endif

  func executeAndWait(_ request: Request, taskHandler: ((Task) -> Void)?) -> RawResult
}

extension Networking {
  @inlinable
  public var jsonDecoder: JSONDecoder { .init() }

  @inlinable
  public var jsonEncoder: JSONEncoder { .init() }

  @inlinable
  public var dictionaryEncoder: DictionaryEncoder { .init() }
}
