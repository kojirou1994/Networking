import XCTest
@testable import Networking
import os

@available(macOS 11.0, *)
final class NetworkingTests: XCTestCase {
  class TestURLSession: URLSessionNetworking {

    var session: URLSession = .init(configuration: .ephemeral)
    #if NETWORKING_LOGGING
    var logger: Logger = .init()
    #endif
    var urlComponents: URLComponents = .init()

    var autoResume: Bool { true }

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

      var path: String { "" }

      typealias ResponseBody = RawStringResponse
    }
    try! session.executeRaw(RootEndpoint()) { response in
//      print(try! response.get())

    }
    try! session.execute(RootEndpoint()) { response in
//      print(try! response.get())

    }
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 2))
  }
}
