import AsyncHTTPClient
import Networking
import Foundation
import NIOHTTP1
import NIOFoundationCompat
import NIO

open class AsyncHTTPClientNetworking: Networking {
    public typealias Response = HTTPClient.Response

    open var urlComponents: URLComponents
    public let jsonDecoder: JSONDecoder
    public let jsonEncoder: JSONEncoder
    public let client: HTTPClient

    public init(client: HTTPClient) {
        self.client = client
        urlComponents = .init()
        urlComponents.queryItems = []
        jsonDecoder = .init()
        jsonEncoder = .init()
    }

    @usableFromInline
    func request<E>(_ endpoint: E) throws -> HTTPClient.Request where E: Endpoint {
        var c = urlComponents
        c.path = endpoint.path
        c.queryItems?.append(contentsOf: endpoint.queryItems)

//        var headers = HTTPHeaders()
//        headers.add(name: "Accept", value: endpoint.acceptType.rawValue)
//        if endpoint.method != .GET {
//            headers.add(name: "Content-Type", value: endpoint.contentType.rawValue)
//        }
//        headers.add(contentsOf: endpoint.headers)

        let body: HTTPClient.Body?
        switch endpoint.contentType {
        case .json:
            body = .data(try jsonEncoder.encode(endpoint.body))
        case .empty: body = nil
        }
        let url = c.url!
        let request = try HTTPClient.Request(url: url, method: endpoint.method, body: body)
        return request
    }

    @usableFromInline
    func decode<E>(_ endpoint: E, body: ByteBuffer) throws -> E.ResponseBody where E: Endpoint {
        switch endpoint.acceptType {
        case .json:
            return try jsonDecoder.decode(E.ResponseBody.self, from: body)
        case .empty: fatalError()
        }
    }

    public func execute<E>(_ endpoint: E, completion: @escaping (Result<NetworkingResponse<E, Response>, Error>) -> Void) where E : Endpoint {
        execute(endpoint).whenComplete(completion)
    }

    public func execute<E>(_ endpoint: E) -> EventLoopFuture<NetworkingResponse<E, Response>> where E : Endpoint {
        do {
            return client.execute(request: try request(endpoint))
                .flatMapThrowing{ (response) -> NetworkingResponse<E, Response> in
//                    var b = response.body!
                    //                    print(b.readString(length: b.readableBytes))
                    guard endpoint.acceptedStatusCode.contains(numericCast(response.status.code)) else {
                        throw NetworkingError.invalidStatusCode(numericCast(response.status.code))
                    }

                    if E.ResponseBody.self == EmptyBody.self {
                        return .init(response: response, body: EmptyBody() as! E.ResponseBody)
                    }

                    guard let body = response.body, body.readableBytes > 0 else {
                        throw NetworkingError.emptyResponseBody
                    }

                    return .init(response: response, body: try self.decode(endpoint, body: body))
            }
        } catch {
            return client.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
}
