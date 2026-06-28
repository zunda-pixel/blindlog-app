import Foundation
import Observation
import SwiftUI
import API

/// Drives value-based push navigation for a single `NavigationStack`. Views read
/// the router from the environment and append an `Item` to push a screen; the
/// stack's `.navigationDestination(for: Router.Item.self)` resolves each item to
/// a destination view (see `RouterDestinationView`).
@Observable
final class Router {
  var items: [Item] = []

  enum Item: Hashable {
    case event(Event)
    case questions(Event)
    case participants(Event)
    case answerQuestion(Event, EventQuestion)
    case wineRegionPicker
    case wineVarietyPicker
  }
}

/// Builds the destination view for a routed `Router.Item` in the main (tab)
/// navigation stacks. Environment values (`AccountStore`, `ErrorState`,
/// `Router`, `WineAnswerDraft`) flow in from the stack root, so each destination
/// is constructed without explicit dependencies.
struct RouterDestinationView: View {
  let item: Router.Item

  var body: some View {
    switch item {
    case .event(let event):
      EventDetailView(event: event)
    case .questions(let event):
      QuestionListView(event: event)
    case .participants(let event):
      ParticipantListView(event: event)
    case .answerQuestion(let event, let question):
      AnswerQuestionView(event: event, question: question, onSubmitted: { _ in })
    case .wineRegionPicker:
      WineRegionPickerView()
    case .wineVarietyPicker:
      WineVarietyPickerView()
    }
  }
}

extension View {
  /// Installs the main navigation graph for a tab's `NavigationStack`.
  func routerDestinations() -> some View {
    navigationDestination(for: Router.Item.self) { item in
      RouterDestinationView(item: item)
    }
  }
}
