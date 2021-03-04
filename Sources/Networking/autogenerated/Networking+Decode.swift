
// #############################################################################
// #                                                                           #
// #            DO NOT EDIT THIS FILE; IT IS AUTOGENERATED.                    #
// #                                                                           #
// #############################################################################


import Foundation
import NIO
import NIOFoundationCompat

// MARK:  Default implementation for decoding
extension Networking where RawResponseBody == Data {

  @inlinable
  public func decode<E>(_ endpoint: E, body: RawResponseBody) throws -> E.ResponseBody
  where E: Endpoint, E.ResponseBody: Decodable {
    switch endpoint.acceptType {
    case .json:
      return try jsonDecoder.decode(E.ResponseBody.self, from: body)
    case .none: fatalError("Should never be called")
    case .wwwFormUrlEncoded:
      fatalError("Unsupported")
    }
  }

  @inlinable
  public func decode<E>(_ endpoint: E, body: RawResponseBody) throws -> E.ResponseBody
  where E: Endpoint, E.ResponseBody: CustomResponseBody {
    try .init(body)
  }

}
// MARK:  Default implementation for decoding
extension Networking where RawResponseBody == ByteBuffer {

  @inlinable
  public func decode<E>(_ endpoint: E, body: RawResponseBody) throws -> E.ResponseBody
  where E: Endpoint, E.ResponseBody: Decodable {
    switch endpoint.acceptType {
    case .json:
      return try jsonDecoder.decode(E.ResponseBody.self, from: body)
    case .none: fatalError("Should never be called")
    case .wwwFormUrlEncoded:
      fatalError("Unsupported")
    }
  }

  @inlinable
  public func decode<E>(_ endpoint: E, body: RawResponseBody) throws -> E.ResponseBody
  where E: Endpoint, E.ResponseBody: CustomResponseBody {
    try .init(body.viewBytes(at: body.readerIndex, length: body.readerIndex) ?? ByteBufferView())
  }

}
// MARK:  Default implementation for decoding
extension Networking where RawResponseBody == ByteBufferView {

  @inlinable
  public func decode<E>(_ endpoint: E, body: RawResponseBody) throws -> E.ResponseBody
  where E: Endpoint, E.ResponseBody: Decodable {
    switch endpoint.acceptType {
    case .json:
      return try jsonDecoder.decode(E.ResponseBody.self, from: .init(body))
    case .none: fatalError("Should never be called")
    case .wwwFormUrlEncoded:
      fatalError("Unsupported")
    }
  }

  @inlinable
  public func decode<E>(_ endpoint: E, body: RawResponseBody) throws -> E.ResponseBody
  where E: Endpoint, E.ResponseBody: CustomResponseBody {
    try .init(body)
  }

}