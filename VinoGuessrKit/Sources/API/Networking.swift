import Foundation
import HTTPClient
import URLSessionHTTPClient
import HTTPTypesFoundation

/// Shared transport behavior for the Blindlog API clients.
///
/// Conforming types provide a `baseURL` and an `httpClient`; this extension
/// builds requests, sends them, and validates the response status, following
/// the same conventions used throughout the package (default `JSONEncoder`
/// and `JSONDecoder`, whose default date strategy is seconds since the 2001
/// reference date — what the Blindlog API uses for its `number` date fields).
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
      let body = String(decoding: data, as: UTF8.self)
      throw AuthAPIError.unexpectedStatus(response.status, body: body)
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
    return try JSONDecoder().decode(Response.self, from: data)
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
  ///
  /// Dates use the `JSONEncoder` default strategy (seconds since the 2001
  /// reference date), which is what the Blindlog API itself uses for its
  /// `number` date fields.
  func encode<Body: Encodable>(_ value: Body) throws -> Data {
    try JSONEncoder().encode(value)
  }
}
