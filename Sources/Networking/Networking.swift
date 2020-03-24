import NIOHTTP1

public struct NetworkingResponse<E: Endpoint, R> {
    public init(response: R, body: E.ResponseBody) {
        self.response = response
        self.body = body
    }

    public let response: R
    public let body: E.ResponseBody
}

public protocol Networking {
    associatedtype Response
    func execute<E>(_ endpoint: E, completion: @escaping (Result<NetworkingResponse<E, Response>, Error>) -> Void) where E: Endpoint
}

#if canImport(Combine)
import Combine

@available(OSX 10.15, *)
public protocol NetworkingPublishable: Networking {
    func publisher<E>(_ endpoint: E) -> AnyPublisher<NetworkingResponse<E, Response>, Error> where E: Endpoint
}
#endif
