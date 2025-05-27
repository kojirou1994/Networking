import Foundation

public protocol CustomResponseBody: Sendable {
  init<D>(_ data: D) throws where D: DataProtocol
}

public extension Endpoint where ResponseBody == Void {
  var acceptType: ContentType { .none }
}

public extension Endpoint where ResponseBody: Decodable {
  var acceptType: ContentType { .json }
}
