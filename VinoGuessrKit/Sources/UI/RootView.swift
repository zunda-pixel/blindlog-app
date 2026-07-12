import SwiftUI
import API

/// The app's root view. Owns the `AccountStore`, ensures a session exists on
/// launch (creating a guest account when necessary), and then shows the event
/// list with an account switcher in the toolbar.
public struct RootView: View {
  @State private var store = AccountStore()
  @State private var errorState = ErrorState()
  @State private var eventListRouter = Router()
  @State private var mypageRouter = Router()
  @State private var eventListDraft = WineAnswerDraft()
  @State private var mypageDraft = WineAnswerDraft()

  public init() {}

  public var body: some View {
    @Bindable var errorState = errorState
    content
      .environment(store)
      .environment(errorState)
      .alert("Error", isPresented: $errorState.isPresenting) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(errorState.message ?? "")
      }
      .buttonStyle(.plain)
      .listStyle(.plain)
      .textSelection(.enabled)
      .scrollEdgeEffectStyle(.soft, for: .top)
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
      tabs
    }
  }

  private var tabs: some View {
    TabView {
      Tab("Events", systemImage: "calendar") {
        NavigationStack(path: $eventListRouter.items) {
          EventListView()
            .routerDestinations()
        }
        .environment(eventListRouter)
        .environment(eventListDraft)
      }

      Tab("My Page", systemImage: "person.crop.circle") {
        NavigationStack(path: $mypageRouter.items) {
          MyPageView()
            .routerDestinations()
        }
        .environment(mypageRouter)
        .environment(mypageDraft)
      }
    }
  }
}

#Preview {
  RootView()
}
