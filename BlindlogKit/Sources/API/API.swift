import Foundation
import HTTPClient
import URLSessionHTTPClient

struct API {
  var baseURL = URL(string: "https://api.blindlog.me")!
  
}

struct AuthAPI {
  var baseURL = URL(string: "https://api.blindlog.me")!
  
  func guestAccount() async throws -> UserToken {
    let (response, bodyData) = try await HTTP.post(
      url: baseURL.appending(path: "user"),
      bodyData: Data(),
      collectUpTo: 1024 * 1024
    )

    guard response.status.kind == .successful else {
      throw AuthAPIError.unexpectedStatus(response.status)
    }

    return try JSONDecoder().decode(UserToken.self, from: bodyData)
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
