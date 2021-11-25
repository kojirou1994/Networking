@_exported import Multipart

public protocol CustomRequestBody {
  func write<D: MutableCollection & RandomAccessCollection & RangeReplaceableCollection>(to data: inout D) throws where D.Element == UInt8
}

public protocol MultipartRequestBody {
  var multipart: Multipart { get }
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

public extension Endpoint where RequestBody: MultipartRequestBody {
  var method: HTTPMethod { .POST }
  var contentType: ContentType { .none }
}
