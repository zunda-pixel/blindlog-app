import SwiftUI

/// A toolbar menu for switching between accounts, adding another guest
/// account, and signing out of the current one.
struct AccountSwitcherToolbar: ToolbarContent {
  @Environment(AccountStore.self) private var store

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
          Task { try? await store.addGuestAccount() }
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
}
