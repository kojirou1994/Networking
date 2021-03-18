import Foundation

extension Networking {
  @_transparent
  public func url<E: Endpoint>(for endpoint: E) -> URL {
    var components = urlComponents
    let path = endpoint.path
    if !path.isEmpty {
      if components.path.isEmpty {
        assert(path.first == "/", "path must begin with '/'.")
        components.path = endpoint.path
      } else {
        components.path.append(endpoint.path)
      }
    }
    if components.queryItems == nil {
      components.queryItems = endpoint.queryItems
    } else {
      components.queryItems?.append(contentsOf: endpoint.queryItems)
    }
    return components.url!
  }
}
