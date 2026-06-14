public import Foundation
import HTTPClient
import URLSessionHTTPClient
import MemberwiseInit

/// Endpoints that do not require an authenticated user (token lifecycle,
/// passkey/email challenges, public user lookup, and system documents).
@MemberwiseInit(.public)
public struct AuthAPI: APIEndpoint, Sendable {
  public var baseURL: URL = URL(string: "https://api.blindlog.me")!
  public var httpClient: URLSession = .shared

  // MARK: System

  func health() async throws {
    try await send(.get, "health")
  }

  func appleAppSiteAssociation() async throws -> AppleAppSiteAssociation {
    try await send(.get, ".well-known/apple-app-site-association")
  }

  // MARK: Authentication

  /// Issues a Base64URL-encoded passkey challenge.
  public func createChallenge() async throws -> String {
    try await send(.post, "challenge")
  }

  /// Creates an anonymous user and returns the initial tokens.
  public func guestAccount() async throws -> UserToken {
    try await send(.post, "user")
  }

  public func token(passkey request: CreatePasskeyTokenRequest) async throws -> UserToken {
    try await send(.post, "token/passkey", body: encode(request))
  }

  public func token(email request: CreateEmailTokenRequest) async throws -> UserToken {
    try await send(.post, "token/email", body: encode(request))
  }

  /// Starts email OTP login and returns the Base64URL-encoded challenge.
  public func startEmailLogin(email: String) async throws -> String {
    try await send(.post, "token/email/start", query: [URLQueryItem(name: "email", value: email)])
  }

  public func refreshToken(_ refreshToken: String) async throws -> UserToken {
    try await send(.post, "refreshToken", body: encode(RefreshTokenRequest(refreshToken: refreshToken)))
  }

  public func revokeToken(_ refreshToken: String) async throws {
    try await send(.post, "revokeToken", body: encode(RefreshTokenRequest(refreshToken: refreshToken)))
  }

  // MARK: Users

  /// Returns user records for the requested IDs.
  public func users(ids: [UUID]) async throws -> [User] {
    let value = ids.map(\.uuidString).joined(separator: ",")
    return try await send(.get, "users", query: [URLQueryItem(name: "ids", value: value)])
  }
}
