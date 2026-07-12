import API
import OSLog
import SwiftUI

private let logger = Logger(subsystem: "com.vinoguessr.app", category: "AnswerQuestionView")

/// Lets a participant submit (or edit) their guess for a blind tasting
/// question: the wine's region, varieties, vintage, alcohol by volume, and an
/// optional note. Pre-fills from the user's existing response when present.
///
/// The wine selection lives in the stack-shared `WineAnswerDraft` (so the
/// region/variety pickers can be pushed via the `Router`); this view resets and
/// populates that draft when it loads.
struct AnswerQuestionView: View {
  @Environment(AccountStore.self) private var store
  @Environment(WineAnswerDraft.self) private var draft
  @Environment(\.dismiss) private var dismiss

  let event: Event
  let question: EventQuestion
  /// Called with the saved response so the question list can refresh its status.
  var onSubmitted: (EventQuestionResponse) -> Void

  @State private var note = ""

  @State private var existingResponse: EventQuestionResponse?

  // Reveal mode (after answers are published).
  @State private var correctAnswer: EventQuestionCorrectAnswer?
  @State private var scoreResult: Scoring.QuestionResult?

  @State private var isSubmitting = false
  @State private var submitError: String?

  private var catalog: WineCatalog { draft.catalog }

  /// Whether the organizer has published the answers and the publish time has
  /// passed, switching this screen from editable to read-only result mode.
  private var answersRevealed: Bool {
    event.answersPublishedAt.map { $0 <= .now } ?? false
  }

  var body: some View {
    Form {
      if let url = question.imageURL {
        Section {
          AsyncImage(url: url) { image in
            image.resizable().scaledToFit()
          } placeholder: {
            ProgressView()
          }
          .frame(maxWidth: .infinity)
        }
      }

      if let note = question.note, !note.isEmpty {
        Section("Note") {
          Text(note)
        }
      }

      if answersRevealed {
        resultSections
      } else {
        Section("Your Answer") {
          WineAnswerForm(onRetry: { Task { await loadCatalog() } })
          TextField("Note (optional)", text: $note, axis: .vertical)
            .lineLimit(2...5)
        }
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
    .navigationTitle("Question \(question.questionNumber)")
    .toolbar {
      if !answersRevealed {
        ToolbarItem(placement: .confirmationAction) {
          Button(existingResponse == nil ? "Submit" : "Save") {
            Task { await submit() }
          }
          .disabled(isSubmitting)
        }
      }
    }
    .task { await load() }
  }

  // MARK: Reveal mode

  @ViewBuilder
  private var resultSections: some View {
    if let result = scoreResult {
      Section("Score") {
        LabeledContent("Points earned", value: "\(result.pointsEarned)")
      }
    }

    Section("Your Answer") {
      if let response = existingResponse {
        answerRows(
          regionID: response.wineRegionID,
          varietyIDs: response.wineVarietyIDs,
          vintage: response.vintage,
          abv: response.alcoholByVolume,
          match: scoreResult
        )
      } else {
        Text("You didn’t answer this question.")
          .foregroundStyle(.secondary)
      }
    }

    Section("Correct Answer") {
      if let correctAnswer {
        answerRows(
          regionID: correctAnswer.wineRegionID,
          varietyIDs: correctAnswer.wineVarietyIDs,
          vintage: correctAnswer.vintage,
          abv: correctAnswer.alcoholByVolume,
          match: nil
        )
      } else {
        Text("No correct answer was set.")
          .foregroundStyle(.secondary)
      }
    }
  }

  @ViewBuilder
  private func answerRows(
    regionID: UUID?,
    varietyIDs: [UUID],
    vintage: Int32?,
    abv: Double?,
    match: Scoring.QuestionResult?
  ) -> some View {
    resultRow("Region", value: catalog.regionName(regionID) ?? "—", correct: match?.regionMatch)
    let varieties = catalog.varietyNames(varietyIDs)
    resultRow("Varieties", value: varieties.isEmpty ? "—" : varieties.joined(separator: ", "), correct: match?.varietyMatch)
    resultRow("Vintage", value: vintage.map { String($0) } ?? "—", correct: match?.vintageMatch)
    resultRow("Alcohol", value: abv.map { "\($0)%" } ?? "—", correct: match?.abvMatch)
  }

  @ViewBuilder
  private func resultRow(_ label: String, value: String, correct: Bool?) -> some View {
    LabeledContent(label) {
      HStack(spacing: 6) {
        Text(value)
        if let correct {
          Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
            .foregroundStyle(correct ? .green : .red)
        }
      }
    }
  }

  private func load() async {
    // The draft is shared across the stack, so clear any selection left over
    // from a previously answered question before populating this one.
    draft.selectedRegionID = nil
    draft.selectedVarietyIDs = []
    draft.vintageText = ""
    draft.abvText = ""
    note = ""

    await loadCatalog()
    guard let api = try? await store.authenticatedAPI() else { return }
    existingResponse = (try? await api.myResponseIfExists(eventID: event.id, questionID: question.id)) ?? nil

    if answersRevealed {
      correctAnswer = (try? await api.correctAnswerIfAvailable(eventID: event.id, questionID: question.id)) ?? nil
      if let response = existingResponse, let correctAnswer {
        scoreResult = Scoring.score(
          response: response,
          correct: correctAnswer,
          regions: catalog.regions,
          rules: event.regionScoreRules
        )
      }
    } else if let response = existingResponse {
      draft.selectedRegionID = response.wineRegionID
      draft.selectedVarietyIDs = Set(response.wineVarietyIDs)
      draft.vintageText = response.vintage.map { String($0) } ?? ""
      draft.abvText = response.alcoholByVolume.map { String($0) } ?? ""
      note = response.note ?? ""
    }
  }

  private func loadCatalog() async {
    draft.catalogState = .loading
    do {
      draft.catalog = try await WineCatalog.load(using: store)
      draft.catalogState = .loaded
    } catch {
      draft.catalogState = .failed
      logger.error("Failed to load wine catalog: \(String(describing: error))")
    }
  }

  private func submit() async {
    submitError = nil
    isSubmitting = true
    do {
      let api = try await store.authenticatedAPI()
      let trimmedNote = note.trimmingCharacters(in: .whitespaces)
      let request = CreateEventQuestionResponseRequest(
        wineRegionID: draft.selectedRegionID,
        vintage: Int32(draft.vintageText.trimmingCharacters(in: .whitespaces)),
        alcoholByVolume: Double(draft.abvText.trimmingCharacters(in: .whitespaces)),
        note: trimmedNote.isEmpty ? nil : trimmedNote,
        wineVarietyIDs: Array(draft.selectedVarietyIDs)
      )

      let response: EventQuestionResponse
      if existingResponse == nil {
        response = try await api.submitResponse(eventID: event.id, questionID: question.id, request)
        logger.info("Submitted response for question \(question.id.uuidString).")
      } else {
        response = try await api.updateMyResponse(eventID: event.id, questionID: question.id, request)
        logger.info("Updated response for question \(question.id.uuidString).")
      }

      onSubmitted(response)
      dismiss()
    } catch {
      submitError = String(describing: error)
      logger.error("Failed to submit response: \(String(describing: error))")
      isSubmitting = false
    }
  }
}

#Preview {
  @Previewable @State var store = AccountStore()
  @Previewable @State var draft = PreviewSamples.draft

  NavigationStack {
    AnswerQuestionView(event: PreviewSamples.event, question: PreviewSamples.question) { _ in }
  }
  .environment(store)
  .environment(draft)
}
