extension Networking {

  @inlinable
  public func rawResponse<E>(_ endpoint: E) async throws(NetworkingError) -> RawResponse where E: Endpoint {
    try await rawResponse(request(endpoint)).get()
  }

  @inlinable
  public func response<E>(_ endpoint: E) async throws(NetworkingError) -> EndpointResponse<E> where E: Endpoint, E.ResponseBody: Decodable {
    let rawResponse = try await rawResponse(endpoint)
    guard let body = rawResponse.body else {
      throw .emptyBody
    }
    return (
      rawResponse.response,
      self.decode(contentType: endpoint.acceptType, body: body)
    )
  }

  @inlinable
  public func response<E>(_ endpoint: E) async throws(NetworkingError) -> EndpointResponse<E> where E: Endpoint, E.ResponseBody: CustomResponseBody {
    let rawResponse = try await rawResponse(endpoint)
    guard let body = rawResponse.body else {
      throw .emptyBody
    }
    return (
      rawResponse.response,
      self.decode(body: body)
    )
  }

}
