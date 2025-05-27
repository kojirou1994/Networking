import Foundation

public enum NetworkingError: Error, Sendable {
  case invalidURL(URLComponents)
  case encode(any Error)
  case network(any Error)
  case emptyBody
  case validation(any Error)
  case decode(any Error)
}
