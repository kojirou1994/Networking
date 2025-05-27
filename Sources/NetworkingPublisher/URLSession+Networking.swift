import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Networking

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
  ) -> AnyPublisher<NetworkingResponse<Response, Result<E.ResponseBody, NetworkingError>>, Error> where E: Endpoint, E.ResponseBody: Decodable {
    session.dataTaskPublisher(for: try! request(endpoint))
      .tryMap { output in
        let res = output.response as! HTTPURLResponse
        return (response: res, body: self.decode(contentType: endpoint.acceptType, body: output.data))
      }
      .eraseToAnyPublisher()
  }
}
#endif
