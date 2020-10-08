public struct NetworkingResponse<R, Body> {
  public let response: R
  public let body: Body

  public init(response: R, body: Body) {
    self.response = response
    self.body = body
  }
}

import Foundation

extension NetworkingResponse: CustomStringConvertible where R == HTTPURLResponse {
  public var description: String {
    """
    statusCode: \(response.statusCode)
    headers:
    \((response.allHeaderFields as! [String: String]).sorted { $0.key < $1.key}.map { "  \"\($0.key)\": \"\($0.value)\""}.joined(separator: "\n"))
    body: \(body)
    """
  }
}
