import Foundation

extension Networking {
  
  public func url<E: Endpoint>(for endpoint: E) throws(NetworkingError) -> URL {
    var components = urlComponents
    
    do {
      let path = endpoint.path
      if !path.isEmpty {
        if components.path.isEmpty {
          assert(path.first == "/", "path must begin with '/'.")
          components.path = endpoint.path
        } else {
          components.path.append(endpoint.path)
        }
      }
    }

    do {
      let queryItems = endpoint.queryItems
      if !queryItems.isEmpty {
        if components.queryItems == nil {
          components.queryItems = queryItems
        } else {
          components.queryItems?.append(contentsOf: queryItems)
        }
      }
    }

    guard let url = components.url else {
      throw .invalidURL(components)
    }
    return url
  }
}
