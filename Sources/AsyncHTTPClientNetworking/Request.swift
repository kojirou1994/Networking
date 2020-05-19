import Foundation

extension Networking where Request == HTTPClient.Request {

  public func request<E>(_ endpoint: E) throws -> Request where E: Endpoint {
    var components = urlComponents
    components.path = endpoint.path
    components.queryItems?.append(contentsOf: endpoint.queryItems)

    var headers = HTTPHeaders()
    headers.add(name: "Accept", value: endpoint.acceptType.rawValue)
    if endpoint.method != .GET {
      headers.add(name: "Content-Type", value: endpoint.contentType.rawValue)
    }
    headers.add(contentsOf: commonHTTPHeaders)
    headers.add(contentsOf: endpoint.headers)

    let body: HTTPClient.Body?
    switch endpoint.contentType {
    case .json:
      body = .data(try! jsonEncoder.encode(endpoint.body))
    case .empty: body = nil
    }
    let url = components.url!
    let request = try HTTPClient.Request(url: url, method: endpoint.method, body: body)
    return request
  }

}
