import SwiftUI
import OSLog
import CoreLocation
import PhotosUI
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
  @State private var coordinate: GeoCoordinate?
  @State private var startsAt = Date().addingTimeInterval(86_400)
  @State private var endsAt = Date().addingTimeInterval(86_400 + 7_200)
  @State private var visibility: EventVisibility = .public
  @State private var capacityText = ""
  @State private var publishImmediately = true

  // Pricing
  @State private var entryFeeText = ""
  @State private var feeCurrencyCode = "JPY"

  // Image
  @State private var pickedItem: PhotosPickerItem?
  @State private var imageData: Data?

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
          Button(role: .cancel) { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(role: .confirm) {
            Task { await submit() }
          }
          .disabled(!isValid || phase == .submitting)
        }
      }
    }
    .task { await loadProfileState() }
    .onChange(of: pickedItem) { _, item in
      Task { await loadImage(item) }
    }
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
        NavigationLink {
          VenueLocationPickerView(coordinate: $coordinate, onSelect: applySelection)
        } label: {
          LabeledContent("Location", value: coordinateSummary)
        }
      }

      Section("Schedule") {
        DatePicker("Starts", selection: $startsAt)
        DatePicker("Ends", selection: $endsAt, in: startsAt...)
      }

      Section("Pricing") {
        TextField("Entry fee (optional)", text: $entryFeeText)
        TextField("Currency code", text: $feeCurrencyCode)
      }

      Section("Image") {
        PhotosPicker("Select Image", selection: $pickedItem, matching: .images)
        if let imageData, let image = PlatformImage(data: imageData) {
          Image(image)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 160)
          Button("Remove Image", role: .destructive) {
            self.imageData = nil
            pickedItem = nil
          }
        }
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

  private var coordinateSummary: String {
    guard let coordinate else { return "Not set" }
    return String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
  }

  /// Parses the entered fee into a `Money`, scaling to the currency's minor
  /// units (e.g. 0 fraction digits for JPY, 2 for USD). Returns nil when blank.
  private var entryFee: Money? {
    let trimmed = entryFeeText.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty, let amount = Decimal(string: trimmed) else { return nil }
    let code = feeCurrencyCode.trimmingCharacters(in: .whitespaces).uppercased()
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = code
    let digits = max(0, formatter.maximumFractionDigits)
    let scaled = amount * pow(Decimal(10), digits)
    let minor = NSDecimalNumber(decimal: scaled).int64Value
    return Money(minorAmount: minor, currencyCode: code)
  }

  private func loadImage(_ item: PhotosPickerItem?) async {
    guard let item else { imageData = nil; return }
    imageData = try? await item.loadTransferable(type: Data.self)
  }

  /// Fills the address fields from a chosen search result, filling empty fields
  /// and always updating the country code.
  private func applySelection(_ selection: VenueSelection) {
    if addressLine1.trimmingCharacters(in: .whitespaces).isEmpty,
       let line = selection.addressLine1, !line.isEmpty {
      addressLine1 = line
    }
    if let iso = selection.countryCode {
      countryCode = iso
    }
    if venueName.trimmingCharacters(in: .whitespaces).isEmpty, let name = selection.name {
      venueName = name
    }
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

      var imageID: UUID?
      if let imageData {
        imageID = try await api.uploadImage(imageData)
      }

      let request = CreateEventRequest(
        title: title.trimmingCharacters(in: .whitespaces),
        body: descriptionText.trimmingCharacters(in: .whitespaces),
        imageID: imageID,
        venueName: venueName.trimmingCharacters(in: .whitespaces),
        venueAddress: PostalAddress(
          addressLine1: addressLine1.trimmingCharacters(in: .whitespaces),
          countryCode: countryCode.trimmingCharacters(in: .whitespaces).uppercased()
        ),
        venueCoordinate: coordinate,
        eventPeriod: DateTimePeriod(startsAt: startsAt, endsAt: endsAt),
        capacity: Int32(capacityText.trimmingCharacters(in: .whitespaces)),
        entryFee: entryFee,
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

#if os(macOS)
typealias PlatformImage = NSImage
#else
typealias PlatformImage = UIImage
#endif

extension SwiftUI.Image {
  init(_ image: PlatformImage) {
    #if os(macOS)
    self.init(nsImage: image)
    #else
    self.init(uiImage: image)
    #endif
  }
}
