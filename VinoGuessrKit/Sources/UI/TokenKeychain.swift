import Foundation
import Valet
import API

/// Secure, per-account storage for `UserToken` values backed by the Keychain.
///
/// Tokens are keyed by the account's `userID` so multiple accounts can be
/// stored side by side. The blob uses the default `JSONCoder` settings, which
/// is fine because it never travels to the server — only this type reads it
/// back.
struct TokenKeychain: Sendable {
  private let valet: Valet

  init() {
    // `withExplicitlySet` is the macOS-recommended factory: the service
    // identifier may be surfaced to the user in Keychain Access.
    self.valet = Valet.valet(
      withExplicitlySet: Identifier(nonEmpty: "me.blindlog.vinoguessr.tokens")!,
      accessibility: .afterFirstUnlock
    )
  }

  /// Returns `true` when the Keychain is reachable. Useful as a fast diagnostic
  /// for entitlement/signing misconfiguration.
  func canAccessKeychain() -> Bool {
    valet.canAccessKeychain()
  }

  func save(_ token: UserToken) throws {
    let data = try JSONEncoder().encode(token)
    try valet.setObject(data, forKey: token.userID.uuidString)
  }

  func token(for userID: UUID) -> UserToken? {
    guard let data = try? valet.object(forKey: userID.uuidString) else { return nil }
    return try? JSONDecoder().decode(UserToken.self, from: data)
  }

  func remove(_ userID: UUID) {
    try? valet.removeObject(forKey: userID.uuidString)
  }
}
