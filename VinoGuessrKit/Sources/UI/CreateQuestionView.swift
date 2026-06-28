import SwiftUI
import OSLog
import PhotosUI
import API

private let logger = Logger(subsystem: "com.vinoguessr.app", category: "CreateQuestionView")

/// A form for adding a question (a tasting flight) to an event, along with its
/// optional correct answer: the wine's region, varieties, vintage, and alcohol
/// by volume. The answer is persisted via `createCorrectAnswer` after the
/// question is created, and only when at least one answer field is filled in.
struct CreateQuestionView: View {
  @Environment(AccountStore.self) private var store
  @Environment(\.dismiss) private var dismiss

  let eventID: UUID
  /// The number suggested for this question (typically the next in sequence).
  let suggestedNumber: Int32
  /// When set, the form edits this existing question (and its answer) instead
  /// of creating a new one.
  let editing: (question: EventQuestion, answer: CreateEventQuestionCorrectAnswerRequest?)?
  /// Called with the saved question and the correct-answer request that was
  /// submitted for it (nil when no answer fields were filled).
  var onCreated: (EventQuestion, CreateEventQuestionCorrectAnswerRequest?) -> Void

  // Question
  @State private var numberText: String
  @State private var note = ""

  // Correct answer
  @State private var selectedRegionID: UUID?
  @State private var selectedVarietyIDs: Set<UUID> = []
  @State private var vintageText = ""
  @State private var abvText = ""

  // Wine master data
  @State private var catalog = WineCatalog()
  @State private var catalogState: WineAnswerForm.CatalogState = .loading

  // Image
  @State private var pickedItem: PhotosPickerItem?
  @State private var imageData: Data?
  @State private var existingImageID: UUID?
  @State private var removeExistingImage = false

  @State private var isSubmitting = false
  @State private var submitError: String?

  init(
    eventID: UUID,
    suggestedNumber: Int32,
    editing: (question: EventQuestion, answer: CreateEventQuestionCorrectAnswerRequest?)? = nil,
    onCreated: @escaping (EventQuestion, CreateEventQuestionCorrectAnswerRequest?) -> Void
  ) {
    self.eventID = eventID
    self.suggestedNumber = suggestedNumber
    self.editing = editing
    self.onCreated = onCreated
    _numberText = State(initialValue: String(editing?.question.questionNumber ?? suggestedNumber))
    _note = State(initialValue: editing?.question.note ?? "")
    _selectedRegionID = State(initialValue: editing?.answer?.wineRegionID)
    _selectedVarietyIDs = State(initialValue: Set(editing?.answer?.wineVarietyIDs ?? []))
    _vintageText = State(initialValue: editing?.answer?.vintage.map { String($0) } ?? "")
    _abvText = State(initialValue: editing?.answer?.alcoholByVolume.map { String($0) } ?? "")
    _existingImageID = State(initialValue: editing?.question.imageID)
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("Question") {
          TextField("Number", text: $numberText)
          TextField("Note (optional)", text: $note, axis: .vertical)
            .lineLimit(3...6)
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
          } else if existingImageID != nil, !removeExistingImage {
            LabeledContent("Current image", value: "Attached")
            Button("Remove Image", role: .destructive) {
              removeExistingImage = true
            }
          }
        }

        Section("Correct Answer (optional)") {
          WineAnswerForm(
            catalog: catalog,
            catalogState: catalogState,
            onRetry: { Task { await loadCatalog() } },
            selectedRegionID: $selectedRegionID,
            selectedVarietyIDs: $selectedVarietyIDs,
            vintageText: $vintageText,
            abvText: $abvText
          )
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
      .disabled(isSubmitting)
      .navigationTitle(editing == nil ? "New Question" : "Edit Question")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(role: .cancel) { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(editing == nil ? "Add" : "Save") {
            Task { await submit() }
          }
          .disabled(!isValid || isSubmitting)
        }
      }
      .task { await loadCatalog() }
      .onChange(of: pickedItem) { _, item in
        Task { await loadImage(item) }
      }
    }
  }

  private func loadImage(_ item: PhotosPickerItem?) async {
    guard let item else { imageData = nil; return }
    imageData = try? await item.loadTransferable(type: Data.self)
  }

  private var isValid: Bool {
    Int32(numberText.trimmingCharacters(in: .whitespaces)).map { $0 > 0 } ?? false
  }

  private var hasAnswerInput: Bool {
    selectedRegionID != nil
      || !selectedVarietyIDs.isEmpty
      || !vintageText.trimmingCharacters(in: .whitespaces).isEmpty
      || !abvText.trimmingCharacters(in: .whitespaces).isEmpty
  }

  private func loadCatalog() async {
    catalogState = .loading
    do {
      catalog = try await WineCatalog.load(using: store)
      catalogState = .loaded
    } catch {
      catalogState = .failed
      logger.error("Failed to load wine catalog: \(String(describing: error))")
    }
  }

  private func submit() async {
    guard let number = Int32(numberText.trimmingCharacters(in: .whitespaces)) else { return }
    submitError = nil
    isSubmitting = true
    do {
      let api = try await store.authenticatedAPI()

      // Upload a newly picked image; otherwise keep the existing one (edit
      // mode), unless the organizer chose to detach it.
      var imageID: UUID? = removeExistingImage ? nil : existingImageID
      if let imageData {
        imageID = try await api.uploadImage(imageData)
      }

      let trimmedNote = note.trimmingCharacters(in: .whitespaces)
      let questionRequest = CreateEventQuestionRequest(
        questionNumber: number,
        imageID: imageID,
        note: trimmedNote.isEmpty ? nil : trimmedNote
      )

      let question: EventQuestion
      if let editing {
        question = try await api.updateQuestion(eventID: eventID, questionID: editing.question.id, questionRequest)
        logger.info("Updated question \(question.id.uuidString).")
      } else {
        question = try await api.createQuestion(eventID: eventID, questionRequest)
        logger.info("Created question \(question.id.uuidString).")
      }

      var answerRequest: CreateEventQuestionCorrectAnswerRequest?
      if hasAnswerInput {
        let request = CreateEventQuestionCorrectAnswerRequest(
          wineRegionID: selectedRegionID,
          vintage: Int32(vintageText.trimmingCharacters(in: .whitespaces)),
          alcoholByVolume: Double(abvText.trimmingCharacters(in: .whitespaces)),
          wineVarietyIDs: Array(selectedVarietyIDs)
        )
        if editing?.answer != nil {
          _ = try await api.updateCorrectAnswer(eventID: eventID, questionID: question.id, request)
        } else {
          _ = try await api.createCorrectAnswer(eventID: eventID, questionID: question.id, request)
        }
        answerRequest = request
      }

      onCreated(question, answerRequest ?? editing?.answer)
      dismiss()
    } catch {
      submitError = String(describing: error)
      logger.error("Failed to save question/answer: \(String(describing: error))")
      isSubmitting = false
    }
  }
}
