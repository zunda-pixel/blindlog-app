import SwiftUI

struct EventPicker: View {
  @Binding var event: Event?
  
  @Observable
  final class Model {
    var events: [Event] = [
      .laVineeEbisu001,
      .laVineeEbisu002,
      .laVineeEbisu003,
      .laVineeEbisu004,
      .winemarketpartyEbisu,
    ]
  }

  var model = Model()

  var body: some View {
    NavigationStack {
      List(selection: $event) {
        Section {
          ForEach(model.events) { event in
            EventListView.CellView(event: event)
              .tag(event)
          }
        } header: {
          Text("Recent Events")
        }

      }
      .navigationTitle(Text("Select Event"))
      #if !os(macOS)
      .listStyle(.insetGrouped)
      #endif
    }
  }
}
