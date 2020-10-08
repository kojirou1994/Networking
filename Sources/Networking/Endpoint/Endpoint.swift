import Foundation

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
//  var acceptedStatusCode: Range<Int> { get }
}

public extension Endpoint {
  var queryItems: [URLQueryItem] { [] }
  var headers: HTTPHeaders { .init() }
}

extension Endpoint {
  @_transparent
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
