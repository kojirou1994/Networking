public struct NetworkingResponse<R, Body> {
  public let response: R
  public let body: Body

  public init(
    response: R,
    body: Body
  ) {
    self.response = response
    self.body = body
  }
}
