@_exported import NIOHTTP1
import Foundation

public protocol Networking {
  associatedtype Request
  associatedtype Response
  associatedtype RawResponseBody = [UInt8]

  typealias RawResult = Result<NetworkingResponse<Response, RawResponseBody>, Error>
  typealias EndpointResult<E: Endpoint> = Result<NetworkingResponse<Response, Result<E.ResponseBody, Error>>, Error>

  var urlComponents: URLComponents { get }
  var commonHTTPHeaders: HTTPHeaders { get }
  var jsonDecoder: JSONDecoder { get }
  var jsonEncoder: JSONEncoder { get }

//  func validate(response: Response) throws

  func request<E>(_ endpoint: E) throws -> Request where E: Endpoint

  func decode<E>(_ endpoint: E, body: RawResponseBody) throws -> E.ResponseBody where E: Endpoint, E.ResponseBody: Decodable

  func executeRaw(
    _ request: Request,
    completion: @escaping (RawResult) -> Void
  )

  func execute<E>(
    _ endpoint: E,
    completion: @escaping (EndpointResult<E>) -> Void
  ) where E: Endpoint, E.ResponseBody: Decodable
}

extension Networking {
  @inlinable
  public var jsonDecoder: JSONDecoder { .init() }

  @inlinable
  public var jsonEncoder: JSONEncoder { .init() }

  @inlinable
  public func executeRaw<E>(
    _ endpoint: E,
    completion: @escaping (RawResult) -> Void
  ) where E: Endpoint {
    do {
      executeRaw(try request(endpoint), completion: completion)
    } catch {
      completion(.failure(error))
    }
  }

  @inlinable
  public func execute<E>(
    _ endpoint: E,
    completion: @escaping (EndpointResult<E>) -> Void
  ) where E: Endpoint, E.ResponseBody: Decodable {
    do {
      executeRaw(try request(endpoint)) { result in
        completion(result.map { rawResponse in
          .init(response: rawResponse.response, body: .init(catching: {try self.decode(endpoint, body: rawResponse.body)}))
        })
      }
    } catch {
      completion(.failure(error))
    }
  }

}
