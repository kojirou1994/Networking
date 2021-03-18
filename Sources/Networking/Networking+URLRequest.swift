import Foundation
import NIO
import NIOFoundationCompat
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension Networking {
  public func wwwFormUrlEncodedBody<T: Encodable>(for body: T) throws -> String {
    let dictionary = try dictionaryEncoder.encode(body) as [String: Any]
    var queries = URLComponents()
    queries.queryItems = dictionary.map { element in
      .init(name: element.key, value: String(describing: element.value))
    }
    return queries.percentEncodedQuery!
  }
}

// MARK:  Default implementation for encoding
extension Networking where Request == URLRequest {
  public func request<E>(_ endpoint: E) throws -> Request where E: Endpoint {
    try _request(endpoint)
  }

  public func request<E>(_ endpoint: E) throws -> Request where E: Endpoint, E.RequestBody: Encodable {
    var request = try _request(endpoint)
    switch endpoint.contentType {
    case .json: request.httpBody = try jsonEncoder.encode(endpoint.body)
    case .none: break // Already checked
    case .wwwFormUrlEncoded:
      request.httpBody = .init(try wwwFormUrlEncodedBody(for: endpoint.body).utf8)
    }
    return request
  }

  public func request<E>(_ endpoint: E) throws -> Request where E: Endpoint, E.RequestBody: CustomRequestBody {
    var request = try _request(endpoint)
    var body = Data()
    try endpoint.body.write(to: &body)
    request.httpBody = body
    return request
  }

  public func request<E>(_ endpoint: E) throws -> Request where E: Endpoint, E.RequestBody: MultipartRequestBody {
    var request = try _request(endpoint)
    request.setMultipartBody(endpoint.body.multipart)
    return request
  }
  
  public func request<E>(_ endpoint: E) throws -> Request where E: Endpoint, E.RequestBody: StreamRequestBody {
    fatalError("Unimplemented")
  }

  func _request<E>(_ endpoint: E) throws -> Request where E: Endpoint {
    endpoint.check()
    var request = try URLRequest(url: url(for: endpoint))
    request.httpMethod = endpoint.method.rawValue
    if endpoint.contentType != .none {
      request.setValue(endpoint.contentType.headerValue, forHTTPHeaderField: "Content-Type")
    }
    if endpoint.acceptType != .none {
      request.setValue(endpoint.acceptType.headerValue, forHTTPHeaderField: "Accept")
    }
    commonHTTPHeaders.forEach { element in
      request.addValue(element.value, forHTTPHeaderField: element.name)
    }
    endpoint.headers.forEach { element in
      request.addValue(element.value, forHTTPHeaderField: element.name)
    }
    return request
  }

}

