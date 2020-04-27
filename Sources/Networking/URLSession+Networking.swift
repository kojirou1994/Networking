import Foundation
import NIOHTTP1

public enum NetworkingError: Error {
  case emptyResponseBody
  case invalidStatusCode(Int)
}

open class URLSessionNetworking: Networking {
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

  public func request<E>(_ endpoint: E) -> URLRequest where E: Endpoint {
    var components = urlComponents
    components.path = endpoint.path
    components.queryItems?.append(contentsOf: endpoint.queryItems)
    var request = URLRequest(url: components.url!)
    request.httpMethod = endpoint.method.rawValue
    request.setValue(endpoint.contentType.rawValue, forHTTPHeaderField: "Content-Type")
    if endpoint.method != .GET {
      request.setValue(endpoint.acceptType.rawValue, forHTTPHeaderField: "Accept")
    }
    commonHTTPHeaders.forEach { element in
      request.addValue(element.value, forHTTPHeaderField: element.name)
    }
    endpoint.headers.forEach { element in
      request.addValue(element.value, forHTTPHeaderField: element.name)
    }
    switch endpoint.contentType {
    case .json:
      request.httpBody = try! jsonEncoder.encode(endpoint.body)
    case .empty: break
    }
    return request
  }

  @inlinable
  func decode<E>(_ endpoint: E, data: Data) throws -> E.ResponseBody where E: Endpoint {
    switch endpoint.acceptType {
    case .json:
      return try jsonDecoder.decode(E.ResponseBody.self, from: data)
    case .empty:
      fatalError()
    }
  }

  public func executeRaw<E>(_ endpoint: E, completion: @escaping (Result<NetworkingResponse<HTTPURLResponse, Data>, Error>) -> Void) where E : Endpoint {
    session.dataTask(with: request(endpoint)) { data, response, error in
      guard error == nil else {
        completion(.failure(error as! URLError))
        return
      }
      let res = response as! HTTPURLResponse
      guard endpoint.acceptedStatusCode.contains(res.statusCode) else {
        completion(.failure(NetworkingError.invalidStatusCode(res.statusCode)))
        return
      }
      completion(.success(.init(response: res, body: data ?? Data())))
    }.resume()
  }

  public func execute<E>(_ endpoint: E, completion: @escaping (Result<NetworkingResponse<HTTPURLResponse, E.ResponseBody>, Error>) -> Void) where E : Endpoint {
    executeRaw(endpoint) { result in
      completion(result.flatMap { rawResponse in
        .init {
          if E.ResponseBody.self == EmptyBody.self {
            return .init(response: rawResponse.response, body: EmptyBody() as! E.ResponseBody)
          }

          guard !rawResponse.body.isEmpty else {
            throw NetworkingError.emptyResponseBody
          }

          return .init(response: rawResponse.response, body: try self.decode(endpoint, data: rawResponse.body))
        }
      })
    }
  }
}

#if canImport(Combine)
import Combine

@available(iOS 13, macOS 10.15, watchOS 6, tvOS 13, *)
extension URLSessionNetworking: NetworkingPublishable {
  public func publisher<E>(_ endpoint: E) -> AnyPublisher<NetworkingResponse<HTTPURLResponse, E.ResponseBody>, Error> where E : Endpoint {
    session.dataTaskPublisher(for: request(endpoint))
      .tryMap { output in
        let res = output.response as! HTTPURLResponse
        guard endpoint.acceptedStatusCode.contains(res.statusCode) else {
          throw NetworkingError.invalidStatusCode(res.statusCode)
        }
        if E.ResponseBody.self == EmptyBody.self {
          return .init(response: res, body: EmptyBody() as! E.ResponseBody)
        }
        if output.data.isEmpty {
          throw NetworkingError.emptyResponseBody
        }
        return try .init(response: res, body: self.decode(endpoint, data: output.data))
    }
    .eraseToAnyPublisher()
  }
}
#endif
