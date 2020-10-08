import Foundation
import Networking

public struct VaporPage<T>: Decodable where T: Decodable {
  public let items: [T]
  public let metadata: VaporPageMetadata
}

public struct VaporPageMetadata: Decodable {
  public let page: Int
  public let per: Int
  public let total: Int
}

public struct VaporPaging<Base>: Endpoint
where Base: Endpoint, Base.ResponseBody: Decodable {

  /// Page number to request. Starts at `1`.
  public let page: Int
  /// Max items per page.
  public let itemsPerPage: Int
  public let base: Base

  public init(_ base: Base, page: Int, itemsPerPage: Int) {
    self.page = page
    self.itemsPerPage = itemsPerPage
    self.base = base
  }

  public var body: Base.RequestBody { base.body }
  public var method: HTTPMethod { base.method }
  public var path: String { base.path }
  public var contentType: ContentType { base.contentType }
  public var acceptType: ContentType { base.acceptType }
  public var headers: HTTPHeaders { base.headers }
  public var queryItems: [URLQueryItem] {
    base.queryItems
      + [.init(name: "page", value: page.description),
         .init(name: "per", value: itemsPerPage.description)]
  }

  public typealias ResponseBody = VaporPage<Base.ResponseBody>

}
