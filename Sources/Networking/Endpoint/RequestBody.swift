import Foundation

public protocol CustomRequestBody {
  func write<D>(to data: inout D) throws where D: DataProtocol
}

public protocol MultipartRequestBody {

}

public protocol StreamRequestBody {

}

public extension Endpoint where RequestBody == Void {
  var body: Void { fatalError("Should never be called") }
  var method: HTTPMethod { .GET }
  var contentType: ContentType { .none }
}

public extension Endpoint where RequestBody: Encodable {
  var method: HTTPMethod { .POST }
  var contentType: ContentType { .json }
}
