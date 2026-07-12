import SwiftUI
import API

/// Shows an event's details. The organizer can edit the event and manage its
/// questions; other users can register to participate and answer questions.
struct EventDetailView: View {
  @Environment(AccountStore.self) private var store
  @Environment(ErrorState.self) private var errorState
  @Environment(Router.self) private var router

  @State private var event: Event
  @State private var organizer: UserProfile?
  @State private var isEditingEvent = false
  @State private var joined = false
  @State private var isJoining = false
  @State private var isUpdatingEvent = false
  @State private var confirmPublishAnswers = false
  @State private var confirmCancelEvent = false
  @State private var confirmCancelRegistration = false

  init(event: Event) {
    _event = State(initialValue: event)
  }

  private var isOrganizer: Bool {
    store.currentAccountID == event.organizerUserID
  }

  private var answersPublished: Bool { event.answersPublishedAt != nil }
  private var eventCanceled: Bool { event.canceledAt != nil }

  var body: some View {
    Form {
      Section("Details") {
        LabeledContent("Title", value: event.title)
        if !event.body.isEmpty {
          LabeledContent("Description", value: event.body)
        }
        LabeledContent("Visibility", value: event.visibility.displayName)
        if let capacity = event.capacity {
          LabeledContent("Capacity", value: "\(capacity)")
        }
        if let entryFee = event.entryFee {
          LabeledContent("Entry fee", value: feeText(entryFee))
        }
        if eventCanceled {
          Label("Canceled", systemImage: "xmark.circle.fill")
            .foregroundStyle(.red)
        }
      }

      if let organizer {
        Section("Organizer") {
          HStack(spacing: 12) {
            if let url = organizer.imageURL {
              AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
              } placeholder: {
                ProgressView()
              }
              .frame(width: 40, height: 40)
              .clipShape(.circle)
            } else {
              Image(systemName: "person.crop.circle")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundStyle(.secondary)
            }
            Text(organizer.name)
          }
        }
      }

      Section("Venue") {
        LabeledContent("Name", value: event.venueName)
        LabeledContent("Address", value: event.venueAddress.addressLine1)
      }

      Section("Schedule") {
        LabeledContent("Starts") {
          Text(event.eventPeriod.startsAt, format: .dateTime)
        }
        LabeledContent("Ends") {
          Text(event.eventPeriod.endsAt, format: .dateTime)
        }
        if let registration = event.registrationPeriod {
          LabeledContent("Registration opens") {
            Text(registration.startsAt, format: .dateTime)
          }
          LabeledContent("Registration closes") {
            Text(registration.endsAt, format: .dateTime)
          }
        }
      }

      if !isOrganizer, !eventCanceled {
        Section {
          if joined {
            Label("Registered", systemImage: "checkmark.circle.fill")
              .foregroundStyle(.green)
            Button("Cancel Registration", role: .destructive) {
              confirmCancelRegistration = true
            }
            .disabled(isJoining)
          } else {
            Button {
              Task { await join() }
            } label: {
              if isJoining {
                ProgressView()
              } else {
                Text("Join Event")
              }
            }
            .disabled(isJoining)
          }
        }
      }

      Section {
        Button {
          router.items.append(.questions(event))
        } label: {
          Label("Questions", systemImage: "list.number")
        }
      }

      if isOrganizer {
        Section("Manage") {
          Button {
            router.items.append(.participants(event))
          } label: {
            Label("Participants", systemImage: "person.2")
          }

          if answersPublished {
            Label("Answers published", systemImage: "checkmark.seal.fill")
              .foregroundStyle(.green)
          } else {
            Button("Publish Answers", systemImage: "checkmark.seal") {
              confirmPublishAnswers = true
            }
            .disabled(isUpdatingEvent)
          }

          if !eventCanceled {
            Button("Cancel Event", systemImage: "xmark.circle", role: .destructive) {
              confirmCancelEvent = true
            }
            .disabled(isUpdatingEvent)
          }
        }
      }
    }
    .formStyle(.grouped)
    .navigationTitle(event.title)
    .toolbar(.hidden, for: .tabBar)
    .toolbar {
      if isOrganizer {
        ToolbarItem(placement: .primaryAction) {
          Button("Edit", systemImage: "pencil") {
            isEditingEvent = true
          }
        }
      }
    }
    .task { await loadOrganizer() }
    .task { await loadParticipation() }
    .sheet(isPresented: $isEditingEvent) {
      CreateEventView(editing: event) { updated in
        event = updated
      }
      .environment(store)
      .environment(errorState)
    }
    .confirmationDialog(
      "Publish answers to all participants?",
      isPresented: $confirmPublishAnswers,
      titleVisibility: .visible
    ) {
      Button("Publish Answers") {
        Task { await updateEvent { $0.answersPublishedAt = Date() } }
      }
    }
    .confirmationDialog(
      "Cancel this event?",
      isPresented: $confirmCancelEvent,
      titleVisibility: .visible
    ) {
      Button("Cancel Event", role: .destructive) {
        Task { await updateEvent { $0.canceledAt = Date() } }
      }
    }
    .confirmationDialog(
      "Cancel your registration?",
      isPresented: $confirmCancelRegistration,
      titleVisibility: .visible
    ) {
      Button("Cancel Registration", role: .destructive) {
        Task { await cancelRegistration() }
      }
    }
  }

  /// Formats a `Money` value using the currency's locale conventions.
  private func feeText(_ money: Money) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = money.currencyCode.rawValue
    let digits = max(0, formatter.maximumFractionDigits)
    let amount = Decimal(money.minorAmount) / pow(Decimal(10), digits)
    return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "\(money.minorAmount)"
  }

  private func loadOrganizer() async {
    guard let api = try? await store.authenticatedAPI() else { return }
    organizer = try? await api.userProfile(userID: event.organizerUserID)
  }

  private func loadParticipation() async {
    guard !isOrganizer, let userID = store.currentAccountID else { return }
    guard let api = try? await store.authenticatedAPI(),
          let events = try? await api.participatingEvents(userID: userID) else { return }
    joined = events.contains { $0.id == event.id }
  }

  private func join() async {
    isJoining = true
    defer { isJoining = false }
    do {
      _ = try await store.authenticatedAPI().registerParticipant(eventID: event.id)
      joined = true
    } catch {
      errorState.report(error)
    }
  }

  private func cancelRegistration() async {
    isJoining = true
    defer { isJoining = false }
    do {
      _ = try await store.authenticatedAPI()
        .updateMyParticipation(eventID: event.id, UpdateEventParticipantRequest(status: .canceled))
      joined = false
    } catch {
      errorState.report(error)
    }
  }

  /// Applies a mutation to an update request built from the current event and
  /// PUTs it, refreshing the displayed event. Used for organizer actions such
  /// as publishing answers or canceling the event.
  private func updateEvent(_ mutate: (inout CreateEventRequest) -> Void) async {
    isUpdatingEvent = true
    defer { isUpdatingEvent = false }
    do {
      var request = event.updateRequest
      mutate(&request)
      event = try await store.authenticatedAPI().updateEvent(id: event.id, request)
    } catch {
      errorState.report(error)
    }
  }
}

#Preview {
  @Previewable @State var store = AccountStore()
  @Previewable @State var errorState = ErrorState()
  @Previewable @State var router = Router()

  NavigationStack {
    EventDetailView(event: PreviewSamples.event)
  }
  .environment(store)
  .environment(errorState)
  .environment(router)
}

extension Event {
  /// A `CreateEventRequest` mirroring this event's current state, so a single
  /// field can be changed and PUT without dropping the others.
  var updateRequest: CreateEventRequest {
    CreateEventRequest(
      title: title,
      body: body,
      imageID: imageID,
      venueName: venueName,
      venueAddress: venueAddress,
      venueCoordinate: venueCoordinate,
      registrationPeriod: registrationPeriod,
      eventPeriod: eventPeriod,
      answersPublishedAt: answersPublishedAt,
      capacity: capacity,
      entryFee: entryFee,
      visibility: visibility,
      publishedAt: publishedAt,
      canceledAt: canceledAt,
      regionScoreRules: regionScoreRules.map {
        CreateEventRegionScoreRuleRequest(wineRegionTypeID: $0.wineRegionTypeID, points: $0.points)
      }
    )
  }
}
