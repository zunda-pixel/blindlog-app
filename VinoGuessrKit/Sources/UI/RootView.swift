import SwiftUI
import API

/// The app's root view. Owns the `AccountStore`, ensures a session exists on
/// launch (creating a guest account when necessary), and then shows the event
/// list with an account switcher in the toolbar.
public struct RootView: View {
  @State private var store = AccountStore()
  @State private var path: [Event] = []
  @State private var isEditingProfile = false

  public init() {}

  public var body: some View {
    NavigationStack(path: $path) {
      content
    }
    .environment(store)
    .task { await store.bootstrap() }
  }

  @ViewBuilder
  private var content: some View {
    switch store.phase {
    case .loading:
      ProgressView("Signing in…")
    case .failed(let message):
      ContentUnavailableView {
        Label("Sign-in failed", systemImage: "exclamationmark.triangle")
      } description: {
        Text(message)
      } actions: {
        Button("Retry") {
          Task { await store.bootstrap() }
        }
      }
    case .ready:
      EventListView(path: $path)
        .toolbar {
          AccountSwitcherToolbar()
          ToolbarItem(placement: .primaryAction) {
            Button("Edit Profile", systemImage: "person.text.rectangle") {
              isEditingProfile = true
            }
          }
        }
        .sheet(isPresented: $isEditingProfile) {
          EditProfileView()
            .environment(store)
        }
    }
  }
}

#Preview {
  RootView()
}
