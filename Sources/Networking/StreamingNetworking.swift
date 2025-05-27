public protocol StreamNetworking: Networking {
  associatedtype StreamTask
  func stream<E>(_ endpoint: E, receiveCompletion: @escaping @Sendable (Result<Void, Error>) -> Void, receiveValue: @escaping @Sendable (RawResponseBody) -> Void) throws -> StreamTask where E: Endpoint
}

extension StreamNetworking {
  public func streamSegmented<E>(_ endpoint: E, receiveCompletion: @escaping @Sendable (Result<Void, Error>) -> Void, receiveValue: @escaping @Sendable (Result<E.ResponseBody, Error>) -> Void) throws -> StreamTask where E: Endpoint, E.ResponseBody: Decodable {
    let acceptType = endpoint.acceptType
    return try stream(endpoint, receiveCompletion: receiveCompletion, receiveValue: { rawResponse in
      receiveValue(.init(catching: {
        try self.decode(contentType: acceptType, body: rawResponse)
      }))
    })
  }
}

public extension StreamNetworking {
  func segmentsStream<E>(_ endpoint: E) -> AsyncThrowingStream<E.ResponseBody, Error> where E: Endpoint, E.ResponseBody: Decodable & Sendable {
    .init { continuation in
      do {
        _ = try streamSegmented(endpoint, receiveCompletion: { completion in
          let err: Error?
          switch completion {
          case .success: err = nil
          case .failure(let error): err = error
          }
          continuation.finish(throwing: err)
        }, receiveValue: { result in
          continuation.yield(with: result)
        })
      } catch {
        continuation.finish(throwing: error)
      }
    }
  }
}
