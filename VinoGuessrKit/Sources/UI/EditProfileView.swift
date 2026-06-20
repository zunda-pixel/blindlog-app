import SwiftUI
import OSLog
import PhotosUI
import API

private let logger = Logger(subsystem: "com.vinoguessr.app", category: "EditProfileView")

/// Lets the current user set their profile name and image. Uses `createProfile`
/// (which upserts the profile) and uploads a selected image first.
struct EditProfileView: View {
  @Environment(AccountStore.self) private var store
  @Environment(\.dismiss) private var dismiss

  @State private var name = ""
  @State private var existingImageURL: URL?
  @State private var pickedItem: PhotosPickerItem?
  @State private var imageData: Data?
  @State private var previewImage: SwiftUI.Image?

  @State private var phase: Phase = .loading
  @State private var errorMessage: String?

  private enum Phase: Equatable { case loading, editing, saving }

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
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") { Task { await save() } }
            .disabled(!isValid || phase == .saving)
        }
      }
    }
    .frame(minWidth: 420, minHeight: 460)
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
        PhotosPicker(selection: $pickedItem, matching: .images) {
          Label(imageData == nil ? "Select Image" : "Change Image", systemImage: "photo")
        }
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
