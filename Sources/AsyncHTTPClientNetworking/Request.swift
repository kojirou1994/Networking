import Foundation

extension Networking where Request == HTTPClient.Request {

  public func request<E>(_ endpoint: E) throws -> Request where E: Endpoint {
    endpoint.check()
    var headers = HTTPHeaders()
    if endpoint.method != .GET {
      headers.add(name: "Content-Type", value: endpoint.contentType.rawValue)
    }
    if endpoint.acceptType != .none {
      headers.add(name: "Accept", value: endpoint.acceptType.rawValue)
    }
    headers.add(contentsOf: commonHTTPHeaders)
    headers.add(contentsOf: endpoint.headers)

    let body: HTTPClient.Body?
    switch endpoint.contentType {
    case .json:
      body = .data(try! jsonEncoder.encode(endpoint.body))
    case .none: body = nil
    }
    let request = try HTTPClient.Request(url: url(for: endpoint), method: endpoint.method, headers: headers, body: body)
    return request
  }

}
