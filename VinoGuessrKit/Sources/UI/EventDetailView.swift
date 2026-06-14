import SwiftUI
import API

/// Shows an event's details. When the current account is the organizer, it can
/// add questions to the event.
///
/// Note: the API exposes no endpoint to list an event's existing questions, so
/// this screen shows only the questions added during the current session.
struct EventDetailView: View {
  @Environment(AccountStore.self) private var store

  let event: Event

  @State private var addedQuestions: [EventQuestion] = []
  @State private var isAddingQuestion = false

  private var isOrganizer: Bool {
    store.currentAccountID == event.organizerUserID
  }

  private var nextQuestionNumber: Int32 {
    (addedQuestions.map(\.questionNumber).max() ?? 0) + 1
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

      if isOrganizer {
        Section("Questions") {
          if addedQuestions.isEmpty {
            Text("No questions added yet.")
              .foregroundStyle(.secondary)
          } else {
            ForEach(addedQuestions) { question in
              VStack(alignment: .leading, spacing: 2) {
                Text("Question \(question.questionNumber)")
                  .font(.headline)
                if let note = question.note, !note.isEmpty {
                  Text(note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
              }
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
    .sheet(isPresented: $isAddingQuestion) {
      CreateQuestionView(eventID: event.id, suggestedNumber: nextQuestionNumber) { question in
        addedQuestions.append(question)
      }
      .environment(store)
    }
  }
}
