public protocol StreamNetworking: Networking {
  associatedtype StreamTask
  func stream<E>(_ endpoint: E, receiveCompletion: @escaping @Sendable (Result<Void, NetworkingError>) -> Void, receiveValue: @escaping @Sendable (RawResponseBody) -> Void) throws(NetworkingError) -> StreamTask where E: Endpoint
}

extension StreamNetworking {
  public func streamSegmented<E>(_ endpoint: E, receiveCompletion: @escaping @Sendable (Result<Void, NetworkingError>) -> Void, receiveValue: @escaping @Sendable (Result<E.ResponseBody, NetworkingError>) -> Void) throws(NetworkingError) -> StreamTask where E: Endpoint, E.ResponseBody: Decodable {
    let acceptType = endpoint.acceptType
    return try stream(endpoint, receiveCompletion: receiveCompletion, receiveValue: { rawResponse in
      receiveValue(self.decode(contentType: acceptType, body: rawResponse))
    })
  }
}

public extension StreamNetworking {
//  func segmentsStream<E>(_ endpoint: E) -> AsyncThrowingStream<E.ResponseBody, NetworkingError> where E: Endpoint, E.ResponseBody: Decodable & Sendable {
//    .init { continuation in
//      do throws(NetworkingError) {
//        _ = try streamSegmented(endpoint, receiveCompletion: { completion in
//          switch completion {
//          case .success:
//            continuation.finish()
//          case .failure(let error):
//            continuation.finish(throwing: error)
//          }
//        }, receiveValue: { result in
//          continuation.yield(with: result)
//        })
//      } catch {
//        continuation.finish(throwing: error)
//      }
//    }
//  }
}
