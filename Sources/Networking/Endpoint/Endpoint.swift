@_exported import struct Foundation.URLQueryItem

public protocol Endpoint {
  associatedtype RequestBody = Void
  associatedtype ResponseBody = Void
  /// Note: path must begin with "/"
  var path: String { get }
  var body: RequestBody { get }
  var method: HTTPMethod { get }
  ///Expected response type
  var acceptType: ContentType { get }
  /// Request content type
  var contentType: ContentType { get }
  var queryItems: [URLQueryItem] { get }
  var headers: HTTPHeaders { get }
  func validate<N: Networking>(networking: N, response: N.RawResponse) throws
}

public extension Endpoint {
  @inlinable
  var queryItems: [URLQueryItem] { [] }

  @inlinable
  var headers: HTTPHeaders { .init() }

  @inlinable
  func validate<N: Networking>(networking: N, response: N.RawResponse) throws {}
}

extension Endpoint {

  public func check() {
    #if DEBUG
    if method == .GET, contentType != .none {
      assertionFailure("GET request should have no body")
    }
    if acceptType != .none {
      assert(ResponseBody.self != Void.self, "if acceptType is none, ResponseBody must be Void.")
    }
    #endif
  }
}
