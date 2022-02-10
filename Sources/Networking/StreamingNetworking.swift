public protocol StreamNetworking: Networking {
  associatedtype StreamTask
  func stream<E>(_ endpoint: E, receiveCompletion: @escaping (Result<Void, Error>) -> Void, receiveValue: @escaping (RawResponseBody) -> Void) throws -> StreamTask where E: Endpoint
}

extension StreamNetworking {
  public func streamSegmented<E>(_ endpoint: E, receiveCompletion: @escaping (Result<Void, Error>) -> Void, receiveValue: @escaping (Result<E.ResponseBody, Error>) -> Void) throws -> StreamTask where E: Endpoint, E.ResponseBody: Decodable {
    try stream(endpoint, receiveCompletion: receiveCompletion, receiveValue: { rawResponse in
      receiveValue(.init(catching: {
        try self.decode(endpoint, body: rawResponse)
      }))
    })
  }
}
