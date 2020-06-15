import Foundation
@_exported import NIOHTTP1
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum NetworkingError: Error {
//  case emptyResponseBody //disable current
  case invalidStatusCode(Int)
}

open class URLSessionNetworking: Networking {

  public func executeRaw(_ request: URLRequest, completion: @escaping (RawResult) -> Void) {
    session.dataTask(with: request) { data, response, error in
      guard error == nil else {
        completion(.failure(error as! URLError))
        return
      }
      let res = response as! HTTPURLResponse
//      guard endpoint.acceptedStatusCode.contains(res.statusCode) else {
//        completion(.failure(NetworkingError.invalidStatusCode(res.statusCode)))
//        return
//      }
      completion(.success(.init(response: res, body: data ?? Data())))
    }.resume()
  }

  public typealias Response = HTTPURLResponse
  public typealias RawResponseBody = Data

  open var urlComponents: URLComponents
  public var commonHTTPHeaders: HTTPHeaders
  public let jsonDecoder: JSONDecoder
  public let jsonEncoder: JSONEncoder
  public let session: URLSession

  public init(session: URLSession) {
    self.session = session
    urlComponents = .init()
    commonHTTPHeaders = .init()
    urlComponents.queryItems = []
    jsonDecoder = .init()
    jsonEncoder = .init()
  }
}

#if canImport(Combine)
import Combine

@available(iOS 13, macOS 10.15, watchOS 6, tvOS 13, *)
extension URLSessionNetworking: PublishableNetworking {

  @_transparent
  public func rawPublisher<E>(_ endpoint: E) -> URLSession.DataTaskPublisher where E: Endpoint {
    session.dataTaskPublisher(for: try! request(endpoint))
  }

  public func publisher<E>(
    _ endpoint: E
  ) -> AnyPublisher<NetworkingResponse<Response, Result<E.ResponseBody, Error>>, Error> where E: Endpoint, E.ResponseBody: Decodable {
    session.dataTaskPublisher(for: try! request(endpoint))
      .tryMap { output in
        let res = output.response as! HTTPURLResponse
        guard endpoint.acceptedStatusCode.contains(res.statusCode) else {
          throw NetworkingError.invalidStatusCode(res.statusCode)
        }
        return .init(response: res, body: .init{try self.decode(endpoint, body: output.data)})
    }
    .eraseToAnyPublisher()
  }
}
#endif
