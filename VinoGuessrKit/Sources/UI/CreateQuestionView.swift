import SwiftUI
import OSLog
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
  /// Called with the created question after a successful submission.
  var onCreated: (EventQuestion) -> Void

  // Question
  @State private var numberText: String
  @State private var note = ""

  // Correct answer
  @State private var selectedRegionID: UUID?
  @State private var selectedVarietyIDs: Set<UUID> = []
  @State private var vintageText = ""
  @State private var abvText = ""

  // Wine master data
  @State private var regions: [WineRegion] = []
  @State private var varieties: [WineVariety] = []
  @State private var catalogState: CatalogState = .loading

  @State private var isSubmitting = false
  @State private var submitError: String?

  private enum CatalogState: Equatable { case loading, loaded, failed }

  init(
    eventID: UUID,
    suggestedNumber: Int32,
    onCreated: @escaping (EventQuestion) -> Void
  ) {
    self.eventID = eventID
    self.suggestedNumber = suggestedNumber
    self.onCreated = onCreated
    _numberText = State(initialValue: String(suggestedNumber))
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("Question") {
          TextField("Number", text: $numberText)
          TextField("Note (optional)", text: $note, axis: .vertical)
            .lineLimit(3...6)
        }

        Section("Correct Answer (optional)") {
          answerRows
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
      .navigationTitle("New Question")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Add") {
            Task { await submit() }
          }
          .disabled(!isValid || isSubmitting)
        }
      }
      .task { await loadCatalog() }
    }
  }

  @ViewBuilder
  private var answerRows: some View {
    switch catalogState {
    case .loading:
      HStack {
        Text("Region")
        Spacer()
        ProgressView()
      }
    case .failed:
      HStack {
        Text("Couldn’t load wine data")
          .foregroundStyle(.secondary)
        Spacer()
        Button("Retry") { Task { await loadCatalog() } }
      }
    case .loaded:
      NavigationLink {
        WineRegionPickerView(regions: regions, selection: $selectedRegionID)
      } label: {
        LabeledContent("Region", value: selectedRegionName)
      }

      NavigationLink {
        WineVarietyPickerView(varieties: varieties, selection: $selectedVarietyIDs)
      } label: {
        LabeledContent("Varieties", value: selectedVarietiesSummary)
      }
    }

    TextField("Vintage (year)", text: $vintageText)
    TextField("Alcohol by volume (%)", text: $abvText)
  }

  private var selectedRegionName: String {
    guard let id = selectedRegionID, let region = regions.first(where: { $0.id == id }) else {
      return "None"
    }
    return region.name
  }

  private var selectedVarietiesSummary: String {
    if selectedVarietyIDs.isEmpty { return "None" }
    let names = varieties
      .filter { selectedVarietyIDs.contains($0.id) }
      .map(\.name)
      .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    return names.joined(separator: ", ")
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
      let api = try await store.authenticatedAPI()
      async let regionsResult = api.wineRegions()
      async let varietiesResult = api.wineVarieties()
      regions = try await regionsResult
      varieties = try await varietiesResult
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
      let trimmedNote = note.trimmingCharacters(in: .whitespaces)
      let question = try await api.createQuestion(
        eventID: eventID,
        CreateEventQuestionRequest(
          questionNumber: number,
          note: trimmedNote.isEmpty ? nil : trimmedNote
        )
      )
      logger.info("Created question \(question.id.uuidString) for event \(eventID.uuidString).")

      if hasAnswerInput {
        let request = CreateEventQuestionCorrectAnswerRequest(
          wineRegionID: selectedRegionID,
          vintage: Int32(vintageText.trimmingCharacters(in: .whitespaces)),
          alcoholByVolume: Double(abvText.trimmingCharacters(in: .whitespaces)),
          wineVarietyIDs: Array(selectedVarietyIDs)
        )
        _ = try await api.createCorrectAnswer(eventID: eventID, questionID: question.id, request)
        logger.info("Created correct answer for question \(question.id.uuidString).")
      }

      onCreated(question)
      dismiss()
    } catch {
      submitError = String(describing: error)
      logger.error("Failed to create question/answer: \(String(describing: error))")
      isSubmitting = false
    }
  }
}
