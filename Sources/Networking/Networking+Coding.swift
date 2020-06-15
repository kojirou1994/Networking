import Foundation
import NIO
import NIOFoundationCompat
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension Endpoint {
  func checkError() {

  }
}

// MARK:  Default implementation for encoding
extension Networking where Request == URLRequest {

  public func request<E>(_ endpoint: E) throws -> Request where E: Endpoint {
    endpoint.check()
    var request = URLRequest(url: url(for: endpoint))
    request.httpMethod = endpoint.method.rawValue
    if endpoint.method != .GET {
      request.setValue(endpoint.contentType.rawValue, forHTTPHeaderField: "Content-Type")
    }
    if endpoint.acceptType != .none {
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
    case .none: break
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
    case .none: fatalError()
    }
  }

  @inlinable public func customDecode<E>(_ endpoint: E, body: RawResponseBody) throws -> E.ResponseBody where E: Endpoint, E.ResponseBody: CustomResponseBody {
    try .init(body)
  }

}

extension Networking where RawResponseBody == ByteBuffer {

  @inlinable public func decode<E>(_ endpoint: E, body: RawResponseBody) throws -> E.ResponseBody
  where E: Endpoint, E.ResponseBody: Decodable {
    switch endpoint.acceptType {
    case .json: return try jsonDecoder.decode(E.ResponseBody.self, from: body)
    case .none: fatalError()
    }
  }

  @inlinable public func customDecode<E>(_ endpoint: E, body: RawResponseBody) throws -> E.ResponseBody where E: Endpoint, E.ResponseBody: CustomResponseBody {
    try .init(body.viewBytes(at: body.readerIndex, length: body.readerIndex) ?? ByteBufferView())
  }

}
extension Networking where RawResponseBody == ByteBufferView {

  @inlinable public func decode<E>(_ endpoint: E, body: RawResponseBody) throws -> E.ResponseBody
    where E: Endpoint, E.ResponseBody: Decodable {
      switch endpoint.acceptType {
      case .json: return try jsonDecoder.decode(E.ResponseBody.self, from: .init(body))
      case .none: fatalError()
      }
  }

  @inlinable public func customDecode<E>(_ endpoint: E, body: RawResponseBody) throws -> E.ResponseBody where E: Endpoint, E.ResponseBody: CustomResponseBody {
    try .init(body)
  }

}
