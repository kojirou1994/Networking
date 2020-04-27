import NIOHTTP1

public struct NetworkingResponse<R, Body> {
  public let response: R
  public let body: Body

  public init(response: R, body: Body) {
    self.response = response
    self.body = body
  }
}

public protocol Networking {
  associatedtype Request
  associatedtype Response
  associatedtype RawResponseBody = [UInt8]

  func request<E>(_ endpoint: E) -> Request where E: Endpoint

  func executeRaw<E>(_ endpoint: E, completion: @escaping (Result<NetworkingResponse<Response, RawResponseBody>, Error>) -> Void) where E: Endpoint

  func execute<E>(_ endpoint: E, completion: @escaping (Result<NetworkingResponse<Response, E.ResponseBody>, Error>) -> Void) where E: Endpoint
  }

  #if canImport(Combine)
  import Combine

  @available(OSX 10.15, *)
  public protocol NetworkingPublishable: Networking {
    func publisher<E>(_ endpoint: E) -> AnyPublisher<NetworkingResponse<Response, E.ResponseBody>, Error> where E: Endpoint
  }
#endif
