import SwiftUI
import OSLog
import API

private let logger = Logger(subsystem: "com.vinoguessr.app", category: "EventListView")

/// Loads and displays the list of events for the current account. Reloads
/// automatically when the active account changes, lets the user create a new
/// event, and pushes an event's detail (where questions can be added).
struct EventListView: View {
  @Environment(AccountStore.self) private var store
  @Environment(Router.self) private var router
  
  @State private var events: [Event] = []
  @State private var loadState: LoadState = .loading
  @State private var isCreatingEvent = false

  enum LoadState: Equatable {
    case loading
    case loaded
    case empty
    case failed(String)
  }

  var body: some View {
    Group {
      switch loadState {
      case .loading:
        ProgressView()
      case .empty:
        ContentUnavailableView {
          Label("No Events", systemImage: "calendar")
        } actions: {
          Button("Create Event") { isCreatingEvent = true }
        }
      case .failed(let message):
        ContentUnavailableView {
          Label("Couldn’t Load Events", systemImage: "wifi.slash")
        } description: {
          Text(message)
        } actions: {
          Button("Retry") {
            Task { await load() }
          }
        }
      case .loaded:
        List(events) { event in
          Button {
            router.items.append(.event(event))
          } label: {
            EventRow(event: event)
              .frame(maxWidth: .infinity, alignment: .leading)
              .contentShape(.rect)
          }
          .buttonStyle(.plain)
        }
      }
    }
    .navigationTitle("Events")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button("New Event", systemImage: "plus") {
          isCreatingEvent = true
        }
      }
    }
    .sheet(isPresented: $isCreatingEvent) {
      CreateEventView { event in
        Task { await load() }
        router.items.append(.event(event))
      }
      .environment(store)
    }
    .task(id: store.currentAccountID) { await load() }
  }

  private func load() async {
    // Only show the full-screen spinner on the first load; subsequent reloads
    // (e.g. returning from a detail screen) refresh silently so the existing
    // list stays visible instead of flashing empty.
    if events.isEmpty {
      loadState = .loading
    }
    do {
      let api = try await store.authenticatedAPI()
      let result = try await api.events()
      events = result
      loadState = result.isEmpty ? .empty : .loaded
      logger.info("Loaded \(result.count) event(s).")
    } catch {
      if events.isEmpty {
        loadState = .failed(String(describing: error))
      }
      logger.error("Failed to load events: \(String(describing: error))")
    }
  }
}
