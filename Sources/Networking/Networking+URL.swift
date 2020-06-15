import Foundation

extension Networking {
  @_transparent
  public func url<E: Endpoint>(for endpoint: E) -> URL {
    var components = urlComponents
    components.path = endpoint.path
    if components.queryItems == nil {
      components.queryItems = endpoint.queryItems
    } else {
      components.queryItems?.append(contentsOf: endpoint.queryItems)
    }
    return components.url!
  }
}
