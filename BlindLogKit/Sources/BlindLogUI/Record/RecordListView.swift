import SwiftUI

struct RecordListView: View {
  @Environment(\.calendar) var calendar
  @Observable
  final class Model {
    var records: [Record] = []
    var searchText = ""
    var isPresentedNewRecordSheet: Bool = false
  }

  @State var model: Model = Model()

  struct CellView: View {
    var record: Record
    var body: some View {
      Text("\(record.id)")
    }
  }

  var body: some View {
    NavigationStack {
      List {
        ForEach(model.records) { record in
          CellView(record: record)
        }
      }
      .navigationTitle(Text("BlindLog"))
      .searchable(text: $model.searchText)
      .safeAreaInset(edge: .bottom) {
        HStack {
          Spacer()

          Button {
            model.isPresentedNewRecordSheet.toggle()
          } label: {
            Label {
              Text("Add New Record")
            } icon: {
              Image(systemName: "plus")
                .imageScale(.large)
                .bold()
            }
            .labelStyle(.iconOnly)
            .padding(10)
          }
          .buttonBorderShape(.circle)
          .buttonStyle(.glassProminent)
          .padding()
        }
      }
      .sheet(isPresented: $model.isPresentedNewRecordSheet) {
        NewRecordView(model: .init(defaultVintage: calendar.component(.year, from: .now)))
      }
    }
  }
}

#Preview {
  RecordListView()
}

struct Record: Identifiable, Hashable, Sendable {
  var id: UUID
  var event: Event
  var answer: [Answer]
}
