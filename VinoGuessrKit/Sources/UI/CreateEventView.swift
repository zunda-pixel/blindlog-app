import SwiftUI
import OSLog
import API

private let logger = Logger(subsystem: "com.vinoguessr.app", category: "CreateEventView")

/// A form for creating a new event. Because organizing an event requires the
/// account to have a profile, this view first checks `me()` and, when no
/// profile exists, collects an organizer name and creates the profile as part
/// of submission.
struct CreateEventView: View {
  @Environment(AccountStore.self) private var store
  @Environment(\.dismiss) private var dismiss

  /// Called with the created event after a successful submission.
  var onCreated: (Event) -> Void

  // Profile
  @State private var needsProfile = false
  @State private var organizerName = ""

  // Event fields
  @State private var title = ""
  @State private var descriptionText = ""
  @State private var venueName = ""
  @State private var addressLine1 = ""
  @State private var countryCode = "JP"
  @State private var startsAt = Date().addingTimeInterval(86_400)
  @State private var endsAt = Date().addingTimeInterval(86_400 + 7_200)
  @State private var visibility: EventVisibility = .public
  @State private var capacityText = ""
  @State private var publishImmediately = true

  @State private var phase: Phase = .loading
  @State private var submitError: String?

  private enum Phase: Equatable { case loading, editing, submitting }

  var body: some View {
    NavigationStack {
      Group {
        switch phase {
        case .loading:
          ProgressView()
        case .editing, .submitting:
          form
        }
      }
      .navigationTitle("New Event")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Create") {
            Task { await submit() }
          }
          .disabled(!isValid || phase == .submitting)
        }
      }
    }
    .task { await loadProfileState() }
  }

  private var form: some View {
    Form {
      if needsProfile {
        Section("Organizer Profile") {
          TextField("Your name", text: $organizerName)
          Text("A profile is required to organize events.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      Section("Details") {
        TextField("Title", text: $title)
        TextField("Description", text: $descriptionText, axis: .vertical)
          .lineLimit(3...6)
      }

      Section("Venue") {
        TextField("Venue name", text: $venueName)
        TextField("Address", text: $addressLine1)
        TextField("Country code", text: $countryCode)
      }

      Section("Schedule") {
        DatePicker("Starts", selection: $startsAt)
        DatePicker("Ends", selection: $endsAt, in: startsAt...)
      }

      Section("Options") {
        Picker("Visibility", selection: $visibility) {
          ForEach(EventVisibility.allCases, id: \.self) { option in
            Text(option.displayName).tag(option)
          }
        }
        TextField("Capacity (optional)", text: $capacityText)
        Toggle("Publish immediately", isOn: $publishImmediately)
      }

      if let submitError {
        Section {
          Text(submitError)
            .foregroundStyle(.red)
            .font(.callout)
        }
      }
    }
    .formStyle(.grouped)
    .disabled(phase == .submitting)
  }

  private var isValid: Bool {
    let profileOK = !needsProfile || !organizerName.trimmingCharacters(in: .whitespaces).isEmpty
    return profileOK
      && !title.trimmingCharacters(in: .whitespaces).isEmpty
      && !descriptionText.trimmingCharacters(in: .whitespaces).isEmpty
      && !venueName.trimmingCharacters(in: .whitespaces).isEmpty
      && !addressLine1.trimmingCharacters(in: .whitespaces).isEmpty
      && !countryCode.trimmingCharacters(in: .whitespaces).isEmpty
      && endsAt > startsAt
  }

  private func loadProfileState() async {
    do {
      let api = try await store.authenticatedAPI()
      let me = try await api.me()
      if let name = me.userProfile?.name {
        organizerName = name
        needsProfile = false
      } else {
        needsProfile = true
      }
    } catch {
      // If we can't determine the profile, assume one is needed; the server
      // will reject duplicates harmlessly is not guaranteed, so default to
      // showing the field.
      needsProfile = true
      logger.error("Could not load profile state: \(String(describing: error))")
    }
    phase = .editing
  }

  private func submit() async {
    submitError = nil
    phase = .submitting
    do {
      let api = try await store.authenticatedAPI()

      if needsProfile {
        let name = organizerName.trimmingCharacters(in: .whitespaces)
        _ = try await api.createProfile(CreateUserProfileRequest(name: name))
        store.setCurrentDisplayName(name)
        needsProfile = false
      }

      let request = CreateEventRequest(
        title: title.trimmingCharacters(in: .whitespaces),
        body: descriptionText.trimmingCharacters(in: .whitespaces),
        venueName: venueName.trimmingCharacters(in: .whitespaces),
        venueAddress: PostalAddress(
          addressLine1: addressLine1.trimmingCharacters(in: .whitespaces),
          countryCode: countryCode.trimmingCharacters(in: .whitespaces).uppercased()
        ),
        eventPeriod: DateTimePeriod(startsAt: startsAt, endsAt: endsAt),
        capacity: Int32(capacityText.trimmingCharacters(in: .whitespaces)),
        visibility: visibility,
        publishedAt: publishImmediately ? Date() : nil
      )

      let event = try await api.createEvent(request)
      logger.info("Created event \(event.id.uuidString).")
      onCreated(event)
      dismiss()
    } catch {
      submitError = String(describing: error)
      logger.error("Failed to create event: \(String(describing: error))")
      phase = .editing
    }
  }
}

extension EventVisibility {
  var displayName: String {
    switch self {
    case .public: "Public"
    case .unlisted: "Unlisted"
    case .private: "Private"
    }
  }
}
