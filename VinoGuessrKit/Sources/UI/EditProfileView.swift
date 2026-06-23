import SwiftUI
import OSLog
import PhotosUI
import AuthenticationServices
import API

private let logger = Logger(subsystem: "com.vinoguessr.app", category: "EditProfileView")

/// Lets the current user set their profile name and image. Uses `createProfile`
/// (which upserts the profile) and uploads a selected image first.
struct EditProfileView: View {
  @Environment(AccountStore.self) private var store
  @Environment(\.dismiss) private var dismiss
  @Environment(\.authorizationController) private var authorizationController

  @State private var name = ""
  @State private var existingImageURL: URL?
  @State private var pickedItem: PhotosPickerItem?
  @State private var imageData: Data?
  @State private var previewImage: SwiftUI.Image?

  @State private var phase: Phase = .loading
  @State private var errorMessage: String?

  @State private var passkeyBusy = false
  @State private var passkeyStatus: String?

  // Email management
  @State private var emails: [Email] = []
  @State private var newEmail = ""
  @State private var otp = ""
  @State private var emailStage: EmailStage = .idle
  @State private var emailBusy = false

  private enum Phase: Equatable { case loading, editing, saving }
  private enum EmailStage: Equatable { case idle, codeSent }

  var body: some View {
    NavigationStack {
      Group {
        switch phase {
        case .loading:
          ProgressView()
        case .editing, .saving:
          form
        }
      }
      .navigationTitle("Profile")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(role: .cancel) { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(role: .confirm) { Task { await save() } }
            .disabled(!isValid || phase == .saving)
        }
      }
    }
    .task { await load() }
    .onChange(of: pickedItem) { _, item in
      Task { await loadImage(item) }
    }
  }

  private var form: some View {
    Form {
      Section("Name") {
        TextField("Display name", text: $name)
      }

      Section("Image") {
        PhotosPicker("Select Image", selection: $pickedItem, matching: .images)
        if let previewImage {
          previewImage
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 160)
        } else if let existingImageURL {
          AsyncImage(url: existingImageURL) { image in
            image.resizable().scaledToFit()
          } placeholder: {
            ProgressView()
          }
          .frame(maxHeight: 160)
        }
      }

      Section("Passkey") {
        Button("Add Passkey") { Task { await addPasskey() } }
          .disabled(passkeyBusy)
        if passkeyBusy {
          ProgressView()
        } else if let passkeyStatus {
          Text(passkeyStatus)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      Section("Emails") {
        if emails.isEmpty {
          Text("No emails.")
            .foregroundStyle(.secondary)
        } else {
          ForEach(emails, id: \.email) { email in
            Text(email.email)
          }
        }

        switch emailStage {
        case .idle:
          TextField("Add email", text: $newEmail)
          Button("Send Code") { Task { await sendCode() } }
            .disabled(emailBusy || newEmail.trimmingCharacters(in: .whitespaces).isEmpty)
        case .codeSent:
          TextField("Verification code", text: $otp)
          HStack {
            Button("Verify") { Task { await verifyEmail() } }
              .disabled(emailBusy || otp.trimmingCharacters(in: .whitespaces).isEmpty)
            Spacer()
            Button("Cancel", role: .cancel) {
              emailStage = .idle
              otp = ""
            }
          }
        }

        if emailBusy {
          ProgressView()
        }
      }

      if let errorMessage {
        Section {
          Text(errorMessage)
            .foregroundStyle(.red)
            .font(.callout)
        }
      }
    }
    .formStyle(.grouped)
    .disabled(phase == .saving)
  }

  private var isValid: Bool {
    !name.trimmingCharacters(in: .whitespaces).isEmpty
  }

  private func load() async {
    do {
      let api = try await store.authenticatedAPI()
      let me = try await api.me()
      name = me.userProfile?.name ?? ""
      existingImageURL = me.userProfile?.imageURL
      emails = me.emails
    } catch {
      logger.error("Failed to load profile: \(String(describing: error))")
    }
    phase = .editing
  }

  private func loadImage(_ item: PhotosPickerItem?) async {
    guard let item else {
      imageData = nil
      previewImage = nil
      return
    }
    imageData = try? await item.loadTransferable(type: Data.self)
    previewImage = try? await item.loadTransferable(type: SwiftUI.Image.self)
  }

  private func addPasskey() async {
    errorMessage = nil
    passkeyStatus = nil
    guard let userID = store.currentAccountID else { return }
    passkeyBusy = true
    defer { passkeyBusy = false }
    do {
      let challenge = try await AuthAPI().createChallenge()
      let trimmedName = name.trimmingCharacters(in: .whitespaces)
      let request = try Passkey.registrationRequest(
        challenge: challenge,
        name: trimmedName.isEmpty ? "VinoGuessr" : trimmedName,
        userID: userID
      )
      let result = try await authorizationController.performRequest(request)
      let payload = try Passkey.addPasskey(from: result)
      let api = try await store.authenticatedAPI()
      try await api.addPasskey(payload, challenge: challenge)
      passkeyStatus = "Passkey registered."
      logger.info("Registered passkey for \(userID.uuidString).")
    } catch {
      errorMessage = String(describing: error)
      logger.error("Failed to register passkey: \(String(describing: error))")
    }
  }

  private func sendCode() async {
    errorMessage = nil
    emailBusy = true
    defer { emailBusy = false }
    do {
      let api = try await store.authenticatedAPI()
      try await api.startEmailVerification(email: newEmail.trimmingCharacters(in: .whitespaces))
      emailStage = .codeSent
    } catch {
      errorMessage = String(describing: error)
    }
  }

  private func verifyEmail() async {
    errorMessage = nil
    emailBusy = true
    defer { emailBusy = false }
    do {
      let api = try await store.authenticatedAPI()
      try await api.confirmEmail(
        ConfirmEmailRequest(
          email: newEmail.trimmingCharacters(in: .whitespaces),
          otp: otp.trimmingCharacters(in: .whitespaces)
        )
      )
      let me = try await api.me()
      emails = me.emails
      newEmail = ""
      otp = ""
      emailStage = .idle
    } catch {
      errorMessage = String(describing: error)
    }
  }

  private func save() async {
    errorMessage = nil
    phase = .saving
    do {
      let api = try await store.authenticatedAPI()
      var imageID: UUID?
      if let imageData {
        imageID = try await api.uploadImage(imageData)
      }
      let trimmed = name.trimmingCharacters(in: .whitespaces)
      _ = try await api.createProfile(CreateUserProfileRequest(name: trimmed, imageID: imageID))
      store.setCurrentDisplayName(trimmed)
      logger.info("Saved profile.")
      dismiss()
    } catch {
      errorMessage = String(describing: error)
      logger.error("Failed to save profile: \(String(describing: error))")
      phase = .editing
    }
  }
}
