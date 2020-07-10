import Foundation

public protocol Endpoint {
  associatedtype RequestBody: Encodable = EmptyBody
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
  var method: HTTPMethod { .GET }
  var queryItems: [URLQueryItem] { [] }
  var headers: HTTPHeaders { .init() }
//  var acceptedStatusCode: Range<Int> { 200..<300 }
}

public protocol CustomResponseBody {
  init<D>(_ data: D) throws where D: DataProtocol
}

public extension Endpoint where RequestBody == EmptyBody {
  var body: EmptyBody { fatalError("Should never be called") }
  var contentType: ContentType { .none }
}

public extension Endpoint where ResponseBody == Void {
  var acceptType: ContentType { .none }
}

public extension Endpoint where ResponseBody: Decodable {
  var acceptType: ContentType { .json }
}

public struct EmptyBody: Codable {
  public init() {}
}

extension Endpoint {
  @_transparent
  public func check() {
    #if DEBUG
    if method == .GET, contentType != .none {
      assertionFailure("GET request should have no body")
    }
    #endif
  }
}
