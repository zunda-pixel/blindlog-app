import API
import OSLog
import SwiftUI

private let logger = Logger(subsystem: "com.vinoguessr.app", category: "QuestionListView")

/// Lists an event's questions. Participants tap a question to submit their
/// answer; the organizer can add new questions and edit existing ones.
struct QuestionListView: View {
  @Environment(AccountStore.self) private var store
  @Environment(ErrorState.self) private var errorState
  @Environment(Router.self) private var router

  let event: Event

  @State private var phase: Phase = .loading
  @State private var questions: [EventQuestion] = []
  @State private var myResponses: [UUID: EventQuestionResponse] = [:]
  @State private var scores: [UUID: Int32] = [:]
  @State private var isAddingQuestion = false
  @State private var editingTarget: EditTarget?

  private enum Phase: Equatable { case loading, loaded, empty, failed(String) }

  /// An organizer's edit target: the question plus its current correct answer
  /// (fetched on tap, since there is a dedicated GET for it).
  private struct EditTarget: Identifiable {
    var question: EventQuestion
    var answer: CreateEventQuestionCorrectAnswerRequest?
    var id: UUID { question.id }
  }

  private var isOrganizer: Bool {
    store.currentAccountID == event.organizerUserID
  }

  private var answersRevealed: Bool {
    event.answersPublishedAt.map { $0 <= .now } ?? false
  }

  private var nextQuestionNumber: Int32 {
    (questions.map(\.questionNumber).max() ?? 0) + 1
  }

  var body: some View {
    content
      .navigationTitle("Questions")
      .toolbar {
        if isOrganizer {
          ToolbarItem(placement: .primaryAction) {
            Button("Add", systemImage: "plus") { isAddingQuestion = true }
          }
        }
      }
      .task { await load() }
      .onChange(of: router.items) { _, items in
        // Returning from the pushed answer screen: refresh the answered/score
        // status (the answer view no longer reports back through a closure).
        if items.last == .questions(event) {
          Task { await load() }
        }
      }
      .sheet(isPresented: $isAddingQuestion) {
        CreateQuestionView(eventID: event.id, suggestedNumber: nextQuestionNumber) { _, _ in
          Task { await load() }
        }
        .environment(store)
      }
      .sheet(item: $editingTarget) { target in
        CreateQuestionView(
          eventID: event.id,
          suggestedNumber: target.question.questionNumber,
          editing: (target.question, target.answer)
        ) { _, _ in
          Task { await load() }
        }
        .environment(store)
      }
  }

  @ViewBuilder
  private var content: some View {
    switch phase {
    case .loading:
      ProgressView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    case .empty:
      ContentUnavailableView(
        "No Questions",
        systemImage: "questionmark.circle",
        description: Text(isOrganizer ? "Add a question to get started." : "The organizer hasn’t added any questions yet.")
      )
    case let .failed(message):
      ContentUnavailableView {
        Label("Couldn’t Load Questions", systemImage: "exclamationmark.triangle")
      } description: {
        Text(message)
      } actions: {
        Button("Retry") { Task { await load() } }
      }
    case .loaded:
      List(questions) { question in
        row(for: question)
      }
    }
  }

  @ViewBuilder
  private func row(for question: EventQuestion) -> some View {
    if isOrganizer {
      Button {
        Task { await beginEditing(question) }
      } label: {
        rowLabel(for: question)
      }
      .buttonStyle(.plain)
    } else {
      Button {
        router.items.append(.answerQuestion(event, question))
      } label: {
        rowLabel(for: question)
      }
      .buttonStyle(.plain)
    }
  }

  @ViewBuilder
  private func rowLabel(for question: EventQuestion) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack {
        Text("Question \(question.questionNumber)")
          .font(.headline)
        Spacer()
        if !isOrganizer {
          if answersRevealed {
            if let points = scores[question.id] {
              Text("\(points) pts")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            }
          } else if myResponses[question.id] != nil {
            Label("Answered", systemImage: "checkmark.circle.fill")
              .labelStyle(.iconOnly)
              .foregroundStyle(.green)
          } else {
            Text("Not answered")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
      if let note = question.note, !note.isEmpty {
        Text(note)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }
    }
    .contentShape(.rect)
  }

  private func load() async {
    do {
      let api = try await store.authenticatedAPI()
      let fetched = try await api.questions(eventID: event.id)
        .sorted { $0.questionNumber < $1.questionNumber }
      questions = fetched
      phase = fetched.isEmpty ? .empty : .loaded

      // Participants: load answered status concurrently.
      if !isOrganizer, !fetched.isEmpty {
        myResponses = await loadMyResponses(for: fetched, using: api)
        if answersRevealed {
          scores = await loadScores(for: fetched, using: api)
        }
      }
    } catch {
      phase = .failed(String(describing: error))
      logger.error("Failed to load questions: \(String(describing: error))")
    }
  }

  private func loadMyResponses(
    for questions: [EventQuestion],
    using api: API
  ) async -> [UUID: EventQuestionResponse] {
    await withTaskGroup(of: (UUID, EventQuestionResponse?).self) { group in
      for question in questions {
        group.addTask {
          let response = try? await api.myResponseIfExists(eventID: event.id, questionID: question.id)
          return (question.id, response ?? nil)
        }
      }
      var result: [UUID: EventQuestionResponse] = [:]
      for await (id, response) in group {
        if let response { result[id] = response }
      }
      return result
    }
  }

  /// Computes each answered question's points from the correct answer and the
  /// event's region scoring rules (the backend has no results endpoint).
  private func loadScores(
    for questions: [EventQuestion],
    using api: API
  ) async -> [UUID: Int32] {
    guard let regions = try? await api.wineRegions() else { return [:] }
    let eventID = event.id
    let rules = event.regionScoreRules
    let responses = myResponses
    return await withTaskGroup(of: (UUID, Int32).self) { group in
      for question in questions {
        guard let response = responses[question.id] else { continue }
        group.addTask {
          let correct = (try? await api.correctAnswerIfAvailable(eventID: eventID, questionID: question.id)) ?? nil
          guard let correct else { return (question.id, 0) }
          let result = Scoring.score(response: response, correct: correct, regions: regions, rules: rules)
          return (question.id, result.pointsEarned)
        }
      }
      var result: [UUID: Int32] = [:]
      for await (id, points) in group { result[id] = points }
      return result
    }
  }

  private func beginEditing(_ question: EventQuestion) async {
    var answer: CreateEventQuestionCorrectAnswerRequest?
    if let api = try? await store.authenticatedAPI(),
       let existing = try? await api.correctAnswerIfAvailable(eventID: event.id, questionID: question.id) {
      answer = CreateEventQuestionCorrectAnswerRequest(
        wineRegionID: existing.wineRegionID,
        vintage: existing.vintage,
        alcoholByVolume: existing.alcoholByVolume,
        wineVarietyIDs: existing.wineVarietyIDs
      )
    }
    editingTarget = EditTarget(question: question, answer: answer)
  }
}
