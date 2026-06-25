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
    // Bearer tokens are device-specific secrets, so use the `…ThisDeviceOnly`
    // accessibility: the items are excluded from encrypted backups and never
    // migrate to a restored or new device. `.afterFirstUnlock` (vs `.whenUnlocked`)
    // still allows reads while the device is locked, e.g. during background refresh.
    self.valet = Valet.valet(
      withExplicitlySet: Identifier(nonEmpty: "me.blindlog.vinoguessr.tokens")!,
      accessibility: .afterFirstUnlockThisDeviceOnly
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
