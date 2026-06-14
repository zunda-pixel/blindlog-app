import SwiftUI
import API

/// Loads and displays the list of events for the current account. Reloads
/// automatically when the active account changes.
struct EventListView: View {
  @Environment(AccountStore.self) private var store

  @State private var events: [Event] = []
  @State private var loadState: LoadState = .loading

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
        ContentUnavailableView("イベントがありません", systemImage: "calendar")
      case .failed(let message):
        ContentUnavailableView {
          Label("イベントを読み込めませんでした", systemImage: "wifi.slash")
        } description: {
          Text(message)
        } actions: {
          Button("再試行") {
            Task { await load() }
          }
        }
      case .loaded:
        List(events) { event in
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
    .navigationTitle("イベント")
    .task(id: store.currentAccountID) { await load() }
  }

  private func load() async {
    loadState = .loading
    do {
      let api = try await store.authenticatedAPI()
      let result = try await api.events()
      events = result
      loadState = result.isEmpty ? .empty : .loaded
    } catch {
      loadState = .failed(String(describing: error))
    }
  }
}
