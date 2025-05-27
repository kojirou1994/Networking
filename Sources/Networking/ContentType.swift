public enum ContentType: Sendable {
  case none
  case json
  case wwwFormUrlEncoded

  public var headerValue: String {
    switch self {
    case .none:
      assertionFailure("Invalid")
      return ""
    case .json:
      return "application/json"
    case .wwwFormUrlEncoded:
      return "application/x-www-form-urlencoded"
    }
  }
}
