import SwiftUI

/// The app's root view. Owns the `AccountStore`, ensures a session exists on
/// launch (creating a guest account when necessary), and then shows the event
/// list with an account switcher in the toolbar.
public struct RootView: View {
  @State private var store = AccountStore()

  public init() {}

  public var body: some View {
    NavigationStack {
      content
    }
    .environment(store)
    .task { await store.bootstrap() }
  }

  @ViewBuilder
  private var content: some View {
    switch store.phase {
    case .loading:
      ProgressView("サインイン中…")
    case .failed(let message):
      ContentUnavailableView {
        Label("サインインに失敗しました", systemImage: "exclamationmark.triangle")
      } description: {
        Text(message)
      } actions: {
        Button("再試行") {
          Task { await store.bootstrap() }
        }
      }
    case .ready:
      EventListView()
        .toolbar { AccountSwitcherToolbar() }
    }
  }
}

#Preview {
  RootView()
}
