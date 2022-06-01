extension Networking {

  @inlinable
  public func rawResponse<E>(_ endpoint: E) async throws -> RawResponse where E: Endpoint {
    try await rawResponse(request(endpoint))
  }

  @inlinable
  public func response<E>(_ endpoint: E) async throws -> EndpointResponse<E> where E: Endpoint, E.ResponseBody: Decodable {
    let rawResponse = try await rawResponse(endpoint)
    return (
      rawResponse.response,
      .init { try self.decode(contentType: endpoint.acceptType, body: rawResponse.body) }
    )
  }

  @inlinable
  public func response<E>(_ endpoint: E) async throws -> EndpointResponse<E> where E: Endpoint, E.ResponseBody: CustomResponseBody {
    let rawResponse = try await rawResponse(endpoint)
    return (
      rawResponse.response,
      .init { try self.decode(body: rawResponse.body) }
    )
  }

}
