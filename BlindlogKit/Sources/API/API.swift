import Foundation
import HTTPClient
import URLSessionHTTPClient

struct API {
  var baseURL = URL(string: "https://api.blindlog.me")!
  var httpClient = URLSession.shared
  var token: String
  
  func events() async throws -> [Event] {
    let request = HTTPRequest(
      method: .get,
      url: baseURL.appending(path: "events"),
      headerFields: [
        .authorization: "Bearer \(token)",
      ]
    )
    
    let (data, response) = try await httpClient.data(for: request)

    guard response.status.kind == .successful else {
      throw AuthAPIError.unexpectedStatus(response.status)
    }

    return try JSONDecoder().decode([Event].self, from: data)
  }
}

struct AuthAPI {
  var baseURL = URL(string: "https://api.blindlog.me")!
  var httpClient = URLSession.shared
  
  func guestAccount() async throws -> UserToken {
    let request = HTTPRequest(
      method: .post,
      url: baseURL.appending(path: "user")
    )
    
    let (data, response) = try await httpClient.data(for: request)

    guard response.status.kind == .successful else {
      throw AuthAPIError.unexpectedStatus(response.status)
    }

    return try JSONDecoder().decode(UserToken.self, from: data)
  }
}

enum AuthAPIError: Error {
  case unexpectedStatus(HTTPResponse.Status)
}

struct UserToken: Sendable, Codable, Hashable {
  var userID: UUID
  var token: String
  var tokenExpiredDate: Date
  var refreshToken: String
  var refreshTokenExpiredDate: Date
}

struct Event: Sendable, Codable, Hashable, Identifiable {
  var id: UUID
  var title: String
}
