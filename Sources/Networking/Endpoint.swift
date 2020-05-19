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
  var acceptedStatusCode: Range<Int> { get }
}

public extension Endpoint {
  var method: HTTPMethod { .GET }
  var acceptType: ContentType { .json }
  var queryItems: [URLQueryItem] { [] }
  var headers: HTTPHeaders { .init() }
  var acceptedStatusCode: Range<Int> { 200..<300 }
}

public extension Endpoint where RequestBody == EmptyBody {
  var body: EmptyBody { .init() }
  var contentType: ContentType { .empty }
}

public struct EmptyBody: Codable {
  public init() {}
}
