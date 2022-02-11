import NIOHTTP1

public protocol ResponseProtocol {
  var status: HTTPResponseStatus { get }
  var headers: HTTPHeaders { get }
}
