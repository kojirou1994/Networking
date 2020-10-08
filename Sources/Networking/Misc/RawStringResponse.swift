import Foundation

public struct RawStringResponse: CustomResponseBody, CustomStringConvertible {
  public let string: String
  public init<D>(_ data: D) throws where D : DataProtocol {
    string = .init(decoding: data, as: UTF8.self)
  }

  public var description: String { string }
}
