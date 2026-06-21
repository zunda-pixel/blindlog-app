import Foundation
import Observation
import OSLog
import API
import Defaults

private let logger = Logger(subsystem: "com.vinoguessr.app", category: "AccountStore")

/// Errors surfaced by `AccountStore` that the UI can present.
public enum AccountError: Error, Sendable {
  case noCurrentAccount
  case sessionExpired(UUID)
  case guestCreationFailed
}

/// Manages the set of signed-in accounts and the currently-active one.
///
/// Tokens are stored securely in the Keychain (`TokenKeychain`) keyed by
/// `userID`; the account index and current selection live in `Defaults`. The
/// store is the single entry point the UI uses to obtain an authenticated
/// `API`, transparently refreshing the access token when it has expired.
@Observable
@MainActor
public final class AccountStore {
  public enum Phase: Sendable, Equatable {
    case loading
    case ready
    case failed(String)
  }

  public private(set) var phase: Phase = .loading
  public private(set) var accounts: [AccountMetadata] = []
  public private(set) var currentAccountID: UUID?

  private let keychain = TokenKeychain()
  private let auth: AuthAPI
  private let now: @Sendable () -> Date

  /// - Parameters:
  ///   - auth: The unauthenticated API client. Injectable for testing.
  ///   - now: Clock used for token-expiry comparisons. Injectable for testing.
  public init(
    auth: AuthAPI = AuthAPI(),
    now: @escaping @Sendable () -> Date = { .now }
  ) {
    self.auth = auth
    self.now = now
  }

  public var currentAccount: AccountMetadata? {
    accounts.first { $0.userID == currentAccountID }
  }

  // MARK: Lifecycle

  /// Restores persisted state and guarantees a usable session, creating a guest
  /// account when none is available. Call once on launch.
  public func bootstrap() async {
    phase = .loading
    accounts = Defaults[.accounts]
    currentAccountID = Defaults[.currentAccountID]

    // Heal a stale selection whose token is missing from the Keychain.
    if let id = currentAccountID, keychain.token(for: id) == nil {
      currentAccountID = nil
    }
    if currentAccountID == nil {
      currentAccountID = accounts.first { keychain.token(for: $0.userID) != nil }?.userID
    }

    if currentAccountID == nil {
      logger.info("No stored session; creating a guest account.")
      do {
        try await addGuestAccount()
      } catch {
        phase = .failed("Could not create a guest account.")
        logger.error("Guest account creation failed: \(String(describing: error))")
        return
      }
    } else {
      logger.info("Restored existing session for account \(self.currentAccountID?.uuidString ?? "?").")
    }
    phase = .ready
    logger.info("Bootstrap ready with \(self.accounts.count) account(s).")
  }

  // MARK: Account management

  /// Creates a fresh anonymous account and makes it current.
  @discardableResult
  public func addGuestAccount() async throws -> AccountMetadata {
    let token = try await createGuestToken()
    try keychain.save(token)
    let meta = AccountMetadata(
      userID: token.userID,
      displayName: Self.guestDisplayName(for: token.userID),
      isGuest: true
    )
    accounts.append(meta)
    currentAccountID = token.userID
    persist()
    return meta
  }

  /// Stores a token obtained from an external sign-in (e.g. passkey) as an
  /// account and makes it current. Updates the entry if the account already
  /// exists.
  public func addAccount(token: UserToken, displayName: String, isGuest: Bool = false) throws {
    try keychain.save(token)
    if let index = accounts.firstIndex(where: { $0.userID == token.userID }) {
      accounts[index].displayName = displayName
      accounts[index].isGuest = isGuest
    } else {
      accounts.append(AccountMetadata(userID: token.userID, displayName: displayName, isGuest: isGuest))
    }
    currentAccountID = token.userID
    persist()
  }

  /// Updates the display name (and clears the guest flag) of the current
  /// account, e.g. after a profile has been created.
  public func setCurrentDisplayName(_ name: String) {
    guard let id = currentAccountID,
          let index = accounts.firstIndex(where: { $0.userID == id }) else { return }
    accounts[index].displayName = name
    accounts[index].isGuest = false
    persist()
  }

  public func switchTo(_ id: UUID) {
    guard accounts.contains(where: { $0.userID == id }),
          keychain.token(for: id) != nil else { return }
    currentAccountID = id
    persist()
  }

  /// Revokes (best effort) and removes an account. If it was the last account,
  /// a new guest is created so the app always has a usable session.
  public func signOut(_ id: UUID) async {
    if let token = keychain.token(for: id) {
      try? await auth.revokeToken(token.refreshToken)
    }
    keychain.remove(id)
    accounts.removeAll { $0.userID == id }
    if currentAccountID == id {
      currentAccountID = accounts.first?.userID
    }
    persist()

    if currentAccountID == nil {
      _ = try? await addGuestAccount()
    }
  }

  // MARK: Authenticated access

  /// Returns an authenticated `API` for the current account, refreshing the
  /// access token first if it has expired.
  public func authenticatedAPI() async throws -> API {
    guard let id = currentAccountID, var token = keychain.token(for: id) else {
      throw AccountError.noCurrentAccount
    }
    // Refresh a little early to avoid races near the expiry boundary.
    if token.tokenExpiredDate <= now().addingTimeInterval(30) {
      token = try await refresh(token, for: id)
    }
    return API(token: token.token)
  }

  // MARK: Private

  private func refresh(_ token: UserToken, for id: UUID) async throws -> UserToken {
    guard token.refreshTokenExpiredDate > now() else {
      throw AccountError.sessionExpired(id)
    }
    let fresh = try await auth.refreshToken(token.refreshToken)
    try keychain.save(fresh)
    return fresh
  }

  /// Creates a guest token, retrying a couple of times since `POST /user` is
  /// known to intermittently return 500 under load.
  private func createGuestToken() async throws -> UserToken {
    var lastError: (any Error)?
    for attempt in 0..<3 {
      do {
        return try await auth.guestAccount()
      } catch {
        lastError = error
        if attempt < 2 {
          try? await Task.sleep(for: .milliseconds(300 * (attempt + 1)))
        }
      }
    }
    throw lastError ?? AccountError.guestCreationFailed
  }

  private func persist() {
    Defaults[.accounts] = accounts
    Defaults[.currentAccountID] = currentAccountID
  }

  private static func guestDisplayName(for userID: UUID) -> String {
    let suffix = userID.uuidString.prefix(4)
    return "Guest (\(suffix))"
  }
}
