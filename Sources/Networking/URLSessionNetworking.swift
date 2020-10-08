import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol URLSessionNetworking: Networking
where Request == URLRequest, Response == HTTPURLResponse,
      RawResponseBody == Data, Task == URLSessionTask {

  var session: URLSession { get }

}

extension URLSessionNetworking {
  public func execute(_ request: URLRequest, completion: @escaping (RawResult) -> Void) -> Task {
    session.dataTask(with: request) { data, response, error in
      guard error == nil else {
        completion(.failure(error as! URLError))
        return
      }
      let res = response as! HTTPURLResponse
      completion(.success(.init(response: res, body: data ?? Data())))
    }
  }
}
