import XCTest
@testable import Networking

final class NetworkingTests: XCTestCase {
  class TestURLSession: URLSessionNetworking {
    var session: URLSession = .init(configuration: .ephemeral)

    var urlComponents: URLComponents = .init()

    var commonHTTPHeaders: HTTPHeaders = .init()

    init() {
      urlComponents.scheme = "http"
      urlComponents.host = "baidu.com"
    }
  }

  let session = TestURLSession()

  func testBase() {
    struct RootEndpoint: Endpoint {
      var acceptType: ContentType { .none }

      var path: String { "/" }

      typealias ResponseBody = RawStringResponse
    }
    try! session.executeRaw(RootEndpoint()) { response in
      print(try! response.get())

    }.resume()
    try! session.execute(RootEndpoint()) { response in
      print(try! response.get())

    }.resume()
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 2))
  }
}
