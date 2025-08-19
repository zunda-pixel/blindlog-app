import SwiftUI

struct EventListView: View {
  @Observable
  final class Model {
    var searchText = ""
    var events: [Event] = [
      .laVineeEbisu001,
      .laVineeEbisu002,
      .laVineeEbisu003,
      .laVineeEbisu004,
      .winemarketpartyEbisu,
    ]
  }

  @State var model = Model()

  var body: some View {
    NavigationStack {
      List {
        Section {
          ForEach(model.events) { event in
            CellView(event: event)
          }
        } header: {
          Text("Recent Events")
        }
      }
      .searchable(text: $model.searchText)
      .navigationTitle(Text("Events"))
      #if !os(macOS)
      .listStyle(.insetGrouped)
      #endif
    }
  }
}

#Preview {
  EventListView()
}
