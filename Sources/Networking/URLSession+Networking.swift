import Foundation
@_exported import NIOHTTP1
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum NetworkingError: Error {
//  case emptyResponseBody //disable current
  case invalidStatusCode(Int)
}

public protocol URLSessionNetworking: Networking
where Request == URLRequest, Response == HTTPURLResponse, RawResponseBody == Data {

  var session: URLSession { get }

}

public extension URLSessionNetworking {
  func executeRaw(_ request: URLRequest, completion: @escaping (RawResult) -> Void) {
    session.dataTask(with: request) { data, response, error in
      guard error == nil else {
        completion(.failure(error as! URLError))
        return
      }
      let res = response as! HTTPURLResponse
      completion(.success(.init(response: res, body: data ?? Data())))
    }.resume()
  }
}

#if canImport(Combine)
import Combine

@available(iOS 13, macOS 10.15, watchOS 6, tvOS 13, *)
public protocol PublishableURLSessionNetworking: URLSessionNetworking, PublishableNetworking {

}

@available(iOS 13, macOS 10.15, watchOS 6, tvOS 13, *)
extension PublishableURLSessionNetworking {

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
        return .init(response: res, body: .init{try self.decode(endpoint, body: output.data)})
      }
      .eraseToAnyPublisher()
  }
}
#endif
