import Foundation
import NIO
import NIOFoundationCompat
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import AnyEncodable

#if canImport(DictionaryCoding)
import DictionaryCoding
extension DictionaryEncoder {
  public func encodeWWWFormUrlEncodedBody<T: Encodable>(_ v: T) throws -> String {
    let dictionary = try encode(v) as [String: Any]
    guard !dictionary.isEmpty else {
      return ""
    }
    var queries = URLComponents()
    queries.queryItems = dictionary.map { element in
      .init(name: element.key, value: String(describing: element.value))
    }
    return queries.percentEncodedQuery!
  }
}
#endif

extension Networking {
  public func wwwFormUrlEncodedBody<T: Encodable>(for body: T) throws -> String {
    #if canImport(DictionaryCoding)
    try dictionaryEncoder.encodeWWWFormUrlEncodedBody(body)
    #else
    fatalError()
    #endif
  }
}

// MARK:  Default implementation for encoding
extension Networking where Request == URLRequest {

  public func request<E>(_ endpoint: E) throws -> Request where E: Endpoint {
    var request = try baseRequest(endpoint)
    guard E.RequestBody.self != Void.self else {
      return request
    }
    if let encodable = endpoint.body as? Encodable {
      let body = AnyEncodable(encodable)
      switch endpoint.contentType {
      case .json: request.httpBody = try jsonEncoder.encode(body)
      case .none: break // Already checked
      case .wwwFormUrlEncoded:
        request.httpBody = .init(try wwwFormUrlEncodedBody(for: body).utf8)
      }
      #if NETWORKING_LOGGING
      if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
        logger.debug("Encoded URLRequest Body: \(String(decoding: request.httpBody!, as: UTF8.self))")
      }
      #endif
    } else if let custom = endpoint.body as? CustomRequestBody {
      var body = Data()
      try custom.write(to: &body)
      #if NETWORKING_LOGGING
      if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
        logger.debug("Custom URLRequest Body")
      }
      #endif
      request.httpBody = body
    } else if let multipart = endpoint.body as? MultipartRequestBody {
      request.setMultipartBody(multipart.multipart)
      #if NETWORKING_LOGGING
      if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
        logger.debug("Multipart URLRequest Body")
      }
      #endif
    } else if let stream = endpoint.body as? StreamRequestBody {
      fatalError("Unimplemented stream \(stream)")
    } else {
      fatalError("Unsupported RequestBody type: \(E.self)")
    }
    return request
  }

  func baseRequest<E>(_ endpoint: E) throws -> Request where E: Endpoint {
    endpoint.check()
    #if NETWORKING_LOGGING
    if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
      logger.debug("Creating new URLRequest")
    }
    #endif
    let url = try url(for: endpoint)
    #if NETWORKING_LOGGING
    if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
      logger.debug("New URLRequest URL: \(url)")
    }
    #endif
    var request = URLRequest(url: url)

    request.httpMethod = endpoint.method.rawValue
    #if NETWORKING_LOGGING
    if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
      logger.debug("URLRequest Method: \(endpoint.method.rawValue)")
    }
    #endif

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
    #if NETWORKING_LOGGING
    if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
      logger.debug("URLRequest Headers: \(request.allHTTPHeaderFields!)")
    }
    #endif
    return request
  }

}

