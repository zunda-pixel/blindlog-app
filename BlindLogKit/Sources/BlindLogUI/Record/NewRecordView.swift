import SwiftUI

struct Area: Identifiable, Hashable, Sendable, Codable {
  var id: UUID
  var parentId: UUID?
  var name: String
  
  var localizedNames: [String: String]
}

struct NewRecordView: View {
  struct Answer: Identifiable, Hashable, Sendable, Codable {
    var id: UUID
    var number: String
    var vintage: Int
    var productionArea: Area?
    var grapes: [GrapePercentage]
    var alcoholPercentage: Double
    var note: AttributedString = .init()
  }

  @Observable
  final class Model {
    var event: Event?
    var answers: [Answer]
    var selectedAnswerId: Answer.ID?

    init() {
      let vintage = Calendar.current.component(.year, from: .now)
      let answers: [Answer] = [
        .init(
          id: UUID(),
          number: "1",
          vintage: vintage - 1,
          productionArea: nil,
          grapes: [],
          alcoholPercentage: 11.0
        ),
        .init(
          id: UUID(),
          number: "2",
          vintage: vintage - 2,
          productionArea: nil,
          grapes: [],
          alcoholPercentage: 12.0
        ),
        .init(
          id: UUID(),
          number: "3",
          vintage: vintage - 3,
          productionArea: nil,
          grapes: [],
          alcoholPercentage: 13.0
        ),
      ]
      self.selectedAnswerId = answers.first!.id
      self.answers = answers
    }
  }

  @State var model = Model()

  var body: some View {
    TabView(selection: $model.selectedAnswerId) {
      ForEach($model.answers) { answer in
        AnswerEditor(answer: answer)
          .tag(answer.wrappedValue.id)
      }
    }
    #if !os(macOS)
    .tabViewStyle(.page(indexDisplayMode: .never))
    #endif
    .safeAreaInset(edge: .top) {
      VStack(alignment: .leading, spacing: 30) {
        Button {

        } label: {
          Text("Select Event")
            .font(.title3.bold())
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)

        Picker(selection: $model.selectedAnswerId) {
          ForEach(model.answers) { answer in
            Text(answer.number)
              .tag(answer.id)
          }
        } label: {
          Text("Answers")
        }
        .pickerStyle(.segmented)
      }
      .padding(20)
    }
  }
}

struct AnswerEditor: View {
  @State var isPresentedAreaPicker = false
  @Binding var answer: NewRecordView.Answer
  @Environment(\.locale) var locale
  
  var body: some View {
    List {
      Section {
        Button {
          isPresentedAreaPicker.toggle()
        } label: {
          if let area = answer.productionArea {
            Text(area.localizedNames[locale.language.languageCode?.identifier ?? ""] ?? area.name)
          } else {
            Text("Select Production Area")
          }
        }
        .sheet(isPresented: $isPresentedAreaPicker) {
          ProductAreaPicker(area: $answer.productionArea)
        }
      } header: {
        Text("Production Area")
      }

      Section {
        TextField(value: $answer.vintage, formatter: NumberFormatter()) {
          Text("Vintage")
        }
        .textContentType(.birthdateYear)
        #if !os(macOS)
        .keyboardType(.numberPad)
        #endif
      } header: {
        Text("Vintage")
      }

      Section {
        ForEach(answer.grapes) { grape in
          HStack {
            LabeledContent {
              Text(grape.grape.name)
            } label: {
              Text("Name")
            }

            LabeledContent {
              Text("\(grape.percent * 100)%")
            } label: {
              Text("Percent")
            }
          }
        }
      } header: {
        Text("Grapes")
      }
      .sectionActions {
        Button {

        } label: {
          Text("Add Grape")
        }
        .contentShape(.rect)
      }

      Section("Note") {
        TextEditor(text: $answer.note)
          .frame(minHeight: 200)
      }
    }
    .scrollDismissesKeyboard(.immediately)
  }
}
