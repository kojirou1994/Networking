extension HTTPResponseStatus: @retroactive Comparable {
  public static func < (lhs: HTTPResponseStatus, rhs: HTTPResponseStatus) -> Bool {
    lhs.code < rhs.code
  }
}
