@_exported import NIOHTTP1
import Foundation

public protocol Networking {
  associatedtype Request
  associatedtype Response
  associatedtype RawResponseBody = [UInt8]

  typealias RawResult = Result<NetworkingResponse<Response, RawResponseBody>, Error>
  typealias EndpointResult<E: Endpoint> = Result<NetworkingResponse<Response, Result<E.ResponseBody, Error>>, Error>

  var urlComponents: URLComponents { get set }
  var commonHTTPHeaders: HTTPHeaders { get set }
  var jsonDecoder: JSONDecoder { get }
  var jsonEncoder: JSONEncoder { get }

//  func validate(response: Response) throws

  func request<E>(_ endpoint: E) throws -> Request where E: Endpoint

  func decode<E>(_ endpoint: E, body: RawResponseBody) throws -> E.ResponseBody
  where E: Endpoint, E.ResponseBody: Decodable

  func customDecode<E>(_ endpoint: E, body: RawResponseBody) throws -> E.ResponseBody
  where E: Endpoint, E.ResponseBody: CustomResponseBody

  func executeRaw(_ request: Request, completion: @escaping (RawResult) -> Void)

}

extension Networking {
  @inlinable
  public var jsonDecoder: JSONDecoder { .init() }

  @inlinable
  public var jsonEncoder: JSONEncoder { .init() }

  @inlinable
  public func executeRaw<E>(_ endpoint: E, completion: @escaping (RawResult) -> Void) where E: Endpoint {
    do {
      executeRaw(try request(endpoint), completion: completion)
    } catch {
      completion(.failure(error))
    }
  }

  @inlinable
  public func execute<E>(_ endpoint: E, completion: @escaping (EndpointResult<E>) -> Void)
  where E: Endpoint, E.ResponseBody: Decodable {
    executeRaw(endpoint) { result in
      completion(result.map { rawResponse in
        .init(response: rawResponse.response, body: .init(catching: {try self.decode(endpoint, body: rawResponse.body)}))
      })
    }
  }

  @inlinable
  public func customExecute<E>(_ endpoint: E, completion: @escaping (EndpointResult<E>) -> Void)
  where E: Endpoint, E.ResponseBody: CustomResponseBody {
    executeRaw(endpoint) { result in
      completion(result.map { rawResponse in
        .init(response: rawResponse.response, body: .init(catching: {try self.customDecode(endpoint, body: rawResponse.body)}))
      })
    }
  }

}
