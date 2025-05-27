import Networking

public struct InvalidHTTPStatus: Error {
  @inlinable
  internal init(status: HTTPResponseStatus, headers: HTTPHeaders) {
    self.status = status
    self.headers = headers
  }

  public let status: HTTPResponseStatus
  public let headers: HTTPHeaders
}

public protocol StatusValidatedEndpoint: Endpoint {
  var validStatusCodes: Range<HTTPResponseStatus> { get }
}

extension StatusValidatedEndpoint {
  @inlinable
  public var validStatusCodes: Range<HTTPResponseStatus> {
    .ok..<HTTPResponseStatus(statusCode: 300)
  }

  @inlinable
  public func validate<N: Networking>(networking: N, response: NetworkingResponse<some ResponseProtocol, N.RawResponseBody?>) throws {
    // the body is ignored
    if !validStatusCodes.contains(response.response.status) {
      throw InvalidHTTPStatus(status: response.response.status, headers: response.response.headers)
    }
  }
}
