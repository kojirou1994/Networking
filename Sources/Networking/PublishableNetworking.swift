#if canImport(Combine)
import Combine

@available(OSX 10.15, *) public protocol PublishableNetworking: Networking {
  func publisher<E>(
    _ endpoint: E
  ) -> AnyPublisher<NetworkingResponse<Response, Result<E.ResponseBody, Error>>, Error> where E: Endpoint, E.ResponseBody: Decodable
}
#endif
