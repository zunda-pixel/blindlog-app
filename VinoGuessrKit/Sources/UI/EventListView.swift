import SwiftUI
import OSLog
import API

private let logger = Logger(subsystem: "com.vinoguessr.app", category: "EventListView")

/// Loads and displays the list of events for the current account. Reloads
/// automatically when the active account changes, lets the user create a new
/// event, and pushes an event's detail (where questions can be added).
struct EventListView: View {
  @Environment(AccountStore.self) private var store
  @Binding var path: [Event]

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
          NavigationLink(value: event) {
            VStack(alignment: .leading, spacing: 4) {
              Text(event.title)
                .font(.headline)
              Text(event.venueName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
              Text(event.eventPeriod.startsAt, style: .date)
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
          }
        }
      }
    }
    .navigationTitle("Events")
    .navigationDestination(for: Event.self) { event in
      EventDetailView(event: event)
    }
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
        path.append(event)
      }
      .environment(store)
    }
    .task(id: store.currentAccountID) { await load() }
  }

  private func load() async {
    loadState = .loading
    do {
      let api = try await store.authenticatedAPI()
      let result = try await api.events()
      events = result
      loadState = result.isEmpty ? .empty : .loaded
      logger.info("Loaded \(result.count) event(s).")
    } catch {
      loadState = .failed(String(describing: error))
      logger.error("Failed to load events: \(String(describing: error))")
    }
  }
}
