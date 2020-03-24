import Foundation

public enum NetworkingError: Error {
    case emptyResponseBody
    case invalidStatusCode(Int)
}

open class URLSessionNetworking: Networking {
    public typealias Response = HTTPURLResponse

    open var urlComponents: URLComponents
    public let jsonDecoder: JSONDecoder
    public let jsonEncoder: JSONEncoder
    public let session: URLSession

    public init(session: URLSession) {
        self.session = session
        urlComponents = .init()
        urlComponents.queryItems = []
        jsonDecoder = .init()
        jsonEncoder = .init()
    }

    @usableFromInline
    func request<E>(_ endpoint: E) -> URLRequest where E: Endpoint {
        var c = urlComponents
        c.path = endpoint.path
        c.queryItems?.append(contentsOf: endpoint.queryItems)
        var request = URLRequest(url: c.url!)
        request.httpMethod = endpoint.method.rawValue
        request.setValue(endpoint.acceptType.rawValue, forHTTPHeaderField: "Accept")
        if endpoint.method != .GET {
            request.setValue(endpoint.contentType.rawValue, forHTTPHeaderField: "Content-Type")
        }
        endpoint.headers.forEach { element in
            request.setValue(element.value, forHTTPHeaderField: element.name)
        }
        switch endpoint.contentType {
        case .json:
            request.httpBody = try! jsonEncoder.encode(endpoint.body)
        case .empty: break
        }
        return request
    }

    @usableFromInline
    func decode<E>(_ endpoint: E, data: Data) throws -> E.ResponseBody where E: Endpoint {
        switch endpoint.acceptType {
        case .json:
            return try jsonDecoder.decode(E.ResponseBody.self, from: data)
        case .empty:
            fatalError()
        }
    }

    public func execute<E>(_ endpoint: E, completion: @escaping (Result<NetworkingResponse<E, HTTPURLResponse>, Error>) -> Void) where E : Endpoint {
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
            if E.ResponseBody.self == EmptyBody.self {
                completion(.success(.init(response: res, body: EmptyBody() as! E.ResponseBody)))
                return
            }
            guard let data = data, !data.isEmpty else {
                completion(.failure(NetworkingError.emptyResponseBody))
                return
            }
            do {
                let body = try self.decode(endpoint, data: data)
                completion(.success(.init(response: res, body: body)))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

#if canImport(Combine)
import Combine

@available(iOS 13, macOS 10.15, watchOS 6, tvOS 13, *)
extension URLSessionNetworking: NetworkingPublishable {
    public func publisher<E>(_ endpoint: E) -> AnyPublisher<NetworkingResponse<E, HTTPURLResponse>, Error> where E : Endpoint {
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
