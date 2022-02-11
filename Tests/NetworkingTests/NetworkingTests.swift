import XCTest
@testable import Networking
import os

@available(macOS 11.0, *)
final class NetworkingTests: XCTestCase {
  class TestURLSession: URLSessionNetworking {

    func execute(_ request: URLRequest) async throws -> RawResponse {
      if #available(macOS 12.0, *) {
        let (data, res) = try await session.data(for: request, delegate: nil)
        return (response: res as! HTTPURLResponse, body: data)
      } else {
        fatalError()
      }
    }

    var session: URLSession = .init(configuration: .ephemeral)
    #if NETWORKING_LOGGING
    var logger: Logger = .init()
    #endif
    var urlComponents: URLComponents = .init()

    var autoResume: Bool { true }

    var commonHTTPHeaders: HTTPHeaders = .init()

    init() {
      urlComponents.scheme = "https"
      urlComponents.host = "httpbin.org"
    }
  }

  let session = TestURLSession()

  func testBase() {
    struct RootEndpoint: Endpoint {

      var acceptType: ContentType { .json }

      var path: String { "/get" }

      typealias ResponseBody = RawStringResponse
    }
    try! session.executeRaw(RootEndpoint()) { response in
      print(try! response.get())
    }
    try! session.execute(RootEndpoint()) { response in
      print(try! response.get())

    }
    dispatchMain()
  }

  func testValidation() throws {
    try! session.execute(StatusCodes(code: 404)) { response in
      dump(response)
      try! XCTAssertThrowsError(try response.get()) { error in
        XCTAssertTrue(error is RawStringResponse)
        dump(error)
      }
    }
    dispatchMain()
  }
}
struct StatusNoOK: Error {
  let status: HTTPResponseStatus
}
protocol CustomValidationEndpoint: Endpoint {

}
extension CustomValidationEndpoint {
  func validate<N>(networking: N, response: N.RawResponse) throws where N : Networking {
    if response.response.status != .ok {
      throw try networking.decode(body: response.body) as RawStringResponse
    }
  }
}

struct StatusCodes: CustomValidationEndpoint {
  var acceptType: ContentType { .none }

  let code: Int
  var path: String { "/status/\(code)" }

  typealias ResponseBody = RawStringResponse
}

extension RawStringResponse: Error {}
