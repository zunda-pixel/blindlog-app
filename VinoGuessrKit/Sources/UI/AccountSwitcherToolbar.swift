import SwiftUI
import AuthenticationServices
import API

/// A toolbar menu for switching between accounts, adding another guest
/// account, signing in with a passkey, and signing out of the current one.
struct AccountSwitcherToolbar: ToolbarContent {
  @Environment(AccountStore.self) private var store
  @Environment(ErrorState.self) private var errorState
  @Environment(\.authorizationController) private var authorizationController

  var body: some ToolbarContent {
    ToolbarItem(placement: .primaryAction) {
      Menu {
        ForEach(store.accounts) { account in
          Button {
            store.switchTo(account.userID)
          } label: {
            Label(
              account.displayName,
              systemImage: account.userID == store.currentAccountID
                ? "checkmark.circle.fill"
                : "person.circle"
            )
          }
        }

        Divider()

        Button("Add Guest Account", systemImage: "plus") {
          Task {
            do {
              try await store.addGuestAccount()
            } catch {
              errorState.report(error)
            }
          }
        }

        Button("Sign in with Passkey", systemImage: "person.badge.key") {
          Task { await signInWithPasskey() }
        }

        if let current = store.currentAccountID {
          Button("Sign Out", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
            Task { await store.signOut(current) }
          }
        }
      } label: {
        Label(
          store.currentAccount?.displayName ?? "Account",
          systemImage: "person.crop.circle"
        )
      }
    }
  }

  private func signInWithPasskey() async {
    do {
      let auth = AuthAPI()
      let challenge = try await auth.createAuthenticationChallenge()
      let request = try Passkey.assertionRequest(challenge: challenge)
      let result = try await authorizationController.performRequest(request)
      let tokenRequest = try Passkey.tokenRequest(from: result, challenge: challenge)
      let token = try await auth.token(passkey: tokenRequest)
      let me = try? await API(token: token.token).me()
      try store.addAccount(token: token, displayName: me?.userProfile?.name ?? "Passkey Account")
    } catch {
      errorState.report(error)
    }
  }
}
