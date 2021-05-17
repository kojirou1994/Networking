#if canImport(Combine)
import Combine
import Networking

@available(iOS 13, macOS 10.15, watchOS 6, tvOS 13, *)
public protocol PublishableNetworking: Networking {

  associatedtype RawPublisher: Publisher

  func rawPublisher<E>(_ endpoint: E) -> RawPublisher where E: Endpoint

  func publisher<E>(
    _ endpoint: E
  ) -> AnyPublisher<NetworkingResponse<Response, Result<E.ResponseBody, Error>>, Error> where E: Endpoint, E.ResponseBody: Decodable
}
#endif
