import Foundation
import NIO
import NIOFoundationCompat
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK:  Default implementation for encoding
extension Networking where Request == URLRequest {

  public func request<E>(_ endpoint: E) throws -> Request where E: Endpoint {
    var components = urlComponents
    components.path = endpoint.path
    if components.queryItems == nil {
      components.queryItems = endpoint.queryItems
    }
    else {
      components.queryItems?.append(contentsOf: endpoint.queryItems)
    }
    var request = URLRequest(url: components.url!)
    request.httpMethod = endpoint.method.rawValue
    request.setValue(endpoint.contentType.rawValue, forHTTPHeaderField: "Content-Type")
    #if DEBUG
    if endpoint.method == .GET, endpoint.contentType != .empty {
      print("Invalid endpoint:\(endpoint), non-empty body in GET request!")
    }
    #endif
    if endpoint.method != .GET {
      request.setValue(endpoint.acceptType.rawValue, forHTTPHeaderField: "Accept")
    }
    commonHTTPHeaders.forEach { element in
      request.addValue(element.value, forHTTPHeaderField: element.name)
    }
    endpoint.headers.forEach { element in
      request.addValue(element.value, forHTTPHeaderField: element.name)
    }
    switch endpoint.contentType {
    case .json: request.httpBody = try jsonEncoder.encode(endpoint.body)
    case .empty: break
    }
    return request
  }

}

// MARK:  Default implementation for decoding
extension Networking where RawResponseBody == Data {

  @inlinable public func decode<E>(_ endpoint: E, body: RawResponseBody) throws -> E.ResponseBody
  where E: Endpoint, E.ResponseBody: Decodable {
    switch endpoint.acceptType {
    case .json: return try jsonDecoder.decode(E.ResponseBody.self, from: body)
    case .empty: fatalError()
    }
  }

}

extension Networking where RawResponseBody == ByteBuffer {

  @inlinable public func decode<E>(_ endpoint: E, body: RawResponseBody) throws -> E.ResponseBody
  where E: Endpoint, E.ResponseBody: Decodable {
    switch endpoint.acceptType {
    case .json: return try jsonDecoder.decode(E.ResponseBody.self, from: body)
    case .empty: fatalError()
    }
  }

}
