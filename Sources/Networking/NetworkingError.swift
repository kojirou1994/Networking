import Foundation

public enum NetworkingError: Error {
  case invalidURL(URLComponents)
}
