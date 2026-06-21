import SwiftUI
import API

/// Shows an event's details. The organizer can edit the event, add and edit
/// questions; other users can register to participate.
///
/// Note: the API exposes no endpoint to list an event's existing questions, so
/// the questions section shows only the questions added during this session.
struct EventDetailView: View {
  @Environment(AccountStore.self) private var store
  @Environment(ErrorState.self) private var errorState

  /// A question created this session, paired with the correct answer that was
  /// submitted for it (so it can be re-edited; there is no GET to fetch it).
  struct AddedQuestion: Identifiable {
    var question: EventQuestion
    var answer: CreateEventQuestionCorrectAnswerRequest?
    var id: UUID { question.id }
  }

  @State private var event: Event
  @State private var organizer: UserProfile?
  @State private var addedQuestions: [AddedQuestion] = []
  @State private var isAddingQuestion = false
  @State private var editingQuestion: AddedQuestion?
  @State private var isEditingEvent = false
  @State private var joined = false
  @State private var isJoining = false

  init(event: Event) {
    _event = State(initialValue: event)
  }

  private var isOrganizer: Bool {
    store.currentAccountID == event.organizerUserID
  }

  private var nextQuestionNumber: Int32 {
    (addedQuestions.map(\.question.questionNumber).max() ?? 0) + 1
  }

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
      }

      if !isOrganizer {
        Section {
          if joined {
            Label("Registered", systemImage: "checkmark.circle.fill")
              .foregroundStyle(.green)
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

      if isOrganizer {
        Section("Questions") {
          if addedQuestions.isEmpty {
            Text("No questions added yet.")
              .foregroundStyle(.secondary)
          } else {
            ForEach(addedQuestions) { added in
              Button {
                editingQuestion = added
              } label: {
                VStack(alignment: .leading, spacing: 2) {
                  Text("Question \(added.question.questionNumber)")
                    .font(.headline)
                  if let note = added.question.note, !note.isEmpty {
                    Text(note)
                      .font(.subheadline)
                      .foregroundStyle(.secondary)
                  }
                }
                .contentShape(.rect)
              }
              .buttonStyle(.plain)
            }
          }

          Button("Add Question", systemImage: "plus") {
            isAddingQuestion = true
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
    .sheet(isPresented: $isAddingQuestion) {
      CreateQuestionView(eventID: event.id, suggestedNumber: nextQuestionNumber) { question, answer in
        addedQuestions.append(AddedQuestion(question: question, answer: answer))
      }
      .environment(store)
    }
    .sheet(item: $editingQuestion) { added in
      CreateQuestionView(
        eventID: event.id,
        suggestedNumber: added.question.questionNumber,
        editing: (added.question, added.answer)
      ) { question, answer in
        if let index = addedQuestions.firstIndex(where: { $0.id == question.id }) {
          addedQuestions[index] = AddedQuestion(question: question, answer: answer)
        }
      }
      .environment(store)
    }
    .sheet(isPresented: $isEditingEvent) {
      CreateEventView(editing: event) { updated in
        event = updated
      }
      .environment(store)
      .environment(errorState)
    }
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
}
