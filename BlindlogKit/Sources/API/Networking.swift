import Foundation
import HTTPClient
import URLSessionHTTPClient

/// An error thrown when the Blindlog API returns a non-successful status.
enum AuthAPIError: Error {
  case unexpectedStatus(HTTPResponse.Status)
}

/// Shared transport behavior for the Blindlog API clients.
///
/// Conforming types provide a `baseURL` and an `httpClient`; this extension
/// builds requests, sends them, and validates the response status, following
/// the same conventions used throughout the package (default `JSONEncoder`
/// and `JSONDecoder`, dates decoded as epoch values).
protocol APIEndpoint {
  var baseURL: URL { get }
  var httpClient: URLSession { get }
}

extension APIEndpoint {
  /// Sends a request and returns the raw response body after validating the status.
  ///
  /// - Parameters:
  ///   - method: The HTTP method to use.
  ///   - path: The path appended to `baseURL`.
  ///   - query: Optional query items to append to the URL.
  ///   - token: Optional bearer token; when present an `Authorization` header is added.
  ///   - body: Optional JSON body; when present the request is sent as an upload.
  func execute(
    _ method: HTTPRequest.Method,
    _ path: String,
    query: [URLQueryItem] = [],
    token: String? = nil,
    body: Data? = nil
  ) async throws -> Data {
    var headerFields = HTTPFields()
    if let token {
      headerFields[.authorization] = "Bearer \(token)"
    }
    if body != nil {
      headerFields[.contentType] = "application/json"
    }

    var url = baseURL.appending(path: path)
    if !query.isEmpty {
      url.append(queryItems: query)
    }

    let request = HTTPRequest(method: method, url: url, headerFields: headerFields)

    let data: Data
    let response: HTTPResponse
    if let body {
      (data, response) = try await httpClient.upload(for: request, from: body)
    } else {
      (data, response) = try await httpClient.data(for: request)
    }

    guard response.status.kind == .successful else {
      throw AuthAPIError.unexpectedStatus(response.status)
    }

    return data
  }

  /// Sends a request and decodes the response body as `Response`.
  func send<Response: Decodable>(
    _ method: HTTPRequest.Method,
    _ path: String,
    query: [URLQueryItem] = [],
    token: String? = nil,
    body: Data? = nil
  ) async throws -> Response {
    let data = try await execute(method, path, query: query, token: token, body: body)
    return try Self.jsonDecoder.decode(Response.self, from: data)
  }

  /// Sends a request and ignores the response body.
  func send(
    _ method: HTTPRequest.Method,
    _ path: String,
    query: [URLQueryItem] = [],
    token: String? = nil,
    body: Data? = nil
  ) async throws {
    _ = try await execute(method, path, query: query, token: token, body: body)
  }

  /// Encodes a value as a JSON request body.
  func encode<Body: Encodable>(_ value: Body) throws -> Data {
    try Self.jsonEncoder.encode(value)
  }

  /// The Blindlog API represents dates as Unix epoch seconds, so dates are
  /// encoded and decoded with `.secondsSince1970` rather than the
  /// `JSONCoder` default (seconds since the 2001 reference date).
  static var jsonDecoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .secondsSince1970
    return decoder
  }

  static var jsonEncoder: JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .secondsSince1970
    return encoder
  }
}
