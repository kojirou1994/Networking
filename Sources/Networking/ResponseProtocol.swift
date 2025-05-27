import NIOHTTP1

public protocol ResponseProtocol: Sendable {
  var status: HTTPResponseStatus { get }
  var headers: HTTPHeaders { get }
}
