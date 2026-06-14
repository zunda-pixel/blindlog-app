import Foundation
import Defaults

/// Non-sensitive metadata describing a stored account.
///
/// The bearer tokens themselves live in the Keychain (see `TokenKeychain`);
/// this type only carries information that is safe to keep in `UserDefaults`
/// so the app can list and label accounts without unlocking the Keychain.
public struct AccountMetadata: Codable, Hashable, Identifiable, Sendable, Defaults.Serializable {
  public var userID: UUID
  public var displayName: String
  public var isGuest: Bool

  public var id: UUID { userID }

  public init(userID: UUID, displayName: String, isGuest: Bool) {
    self.userID = userID
    self.displayName = displayName
    self.isGuest = isGuest
  }
}

extension Defaults.Keys {
  /// The list of known accounts, in the order they were added.
  static let accounts = Key<[AccountMetadata]>("accounts", default: [])
  /// The account currently in use, if any.
  static let currentAccountID = Key<UUID?>("currentAccountID", default: nil)
}
