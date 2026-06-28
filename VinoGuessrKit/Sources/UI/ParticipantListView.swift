import API
import OSLog
import SwiftUI

private let logger = Logger(subsystem: "com.vinoguessr.app", category: "ParticipantListView")

/// Shows an event's participants grouped by status. Organizer only.
struct ParticipantListView: View {
  @Environment(AccountStore.self) private var store

  let event: Event

  @State private var phase: Phase = .loading
  @State private var participants: [EventParticipant] = []
  @State private var names: [UUID: String] = [:]

  private enum Phase: Equatable { case loading, loaded, empty, failed(String) }

  /// Display order for the status sections.
  private static let statusOrder: [EventParticipantStatus] = [
    .registered, .waitlisted, .attended, .canceled,
  ]

  var body: some View {
    content
      .navigationTitle("Participants")
      .task { await load() }
  }

  @ViewBuilder
  private var content: some View {
    switch phase {
    case .loading:
      ProgressView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    case .empty:
      ContentUnavailableView(
        "No Participants",
        systemImage: "person.2",
        description: Text("No one has registered for this event yet.")
      )
    case let .failed(message):
      ContentUnavailableView {
        Label("Couldn’t Load Participants", systemImage: "exclamationmark.triangle")
      } description: {
        Text(message)
      } actions: {
        Button("Retry") { Task { await load() } }
      }
    case .loaded:
      List {
        ForEach(Self.statusOrder, id: \.self) { status in
          let group = participants.filter { $0.status == status }
          if !group.isEmpty {
            Section("\(status.displayName) (\(group.count))") {
              ForEach(group) { participant in
                Text(names[participant.userID] ?? Self.shortName(participant.userID))
              }
            }
          }
        }
      }
    }
  }

  private func load() async {
    do {
      let api = try await store.authenticatedAPI()
      let fetched = try await api.participants(eventID: event.id)
      participants = fetched
      phase = fetched.isEmpty ? .empty : .loaded
      if !fetched.isEmpty {
        names = await loadNames(for: fetched, using: api)
      }
    } catch {
      phase = .failed(String(describing: error))
      logger.error("Failed to load participants: \(String(describing: error))")
    }
  }

  private func loadNames(
    for participants: [EventParticipant],
    using api: API
  ) async -> [UUID: String] {
    let ids = Set(participants.map(\.userID))
    return await withTaskGroup(of: (UUID, String?).self) { group in
      for id in ids {
        group.addTask {
          let profile = try? await api.userProfile(userID: id)
          return (id, profile?.name)
        }
      }
      var result: [UUID: String] = [:]
      for await (id, name) in group {
        if let name { result[id] = name }
      }
      return result
    }
  }

  private static func shortName(_ id: UUID) -> String {
    "User \(id.uuidString.prefix(4))"
  }
}

extension EventParticipantStatus {
  var displayName: String {
    switch self {
    case .registered: "Registered"
    case .waitlisted: "Waitlisted"
    case .canceled: "Canceled"
    case .attended: "Attended"
    }
  }
}
