import SwiftUI
import MemberwiseInit

@MemberwiseInit(.public)
public struct Area: Identifiable, Hashable, Sendable, Codable {
  public var id: UUID
  public var parentId: UUID?
  public var name: String
  
  public var localizedNames: [String: String]
}

struct NewRecordView: View {
  @MemberwiseInit(.public)
  public struct Answer: Identifiable, Hashable, Sendable, Codable {
    public var id: UUID
    public var number: String
    public var vintage: Int
    public var productionArea: Area?
    public var grapes: [GrapePercentage]
    public var alcoholPercentage: Double
    public var acidity: Double = 0.5
    public var tannin: Double = 0.5
    public var minerality: Double = 0.5
    public var sweety: Double = 0.5
    public var colorIntensity: Double = 0.5
    public var note: AttributedString = .init()
  }

  @Observable
  final class Model {
    var event: Event?
    var answers: [Answer]
    var selectedAnswerId: Answer.ID?
    var isPresentedEventPicker: Bool = false
    
    init(defaultVintage: Int) {
      let answers: [Answer] = [
        .init(
          id: UUID(),
          number: "1",
          vintage: defaultVintage,
          productionArea: nil,
          grapes: [],
          alcoholPercentage: 0.13
        ),
        .init(
          id: UUID(),
          number: "2",
          vintage: defaultVintage,
          productionArea: nil,
          grapes: [],
          alcoholPercentage: 0.13
        ),
        .init(
          id: UUID(),
          number: "3",
          vintage: defaultVintage,
          productionArea: nil,
          grapes: [],
          alcoholPercentage: 0.13
        ),
      ]
      self.selectedAnswerId = answers.first!.id
      self.answers = answers
    }
  }

  @State var model: Model
  @Environment(\.dismiss) var dismiss
  
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
        HStack {
          Spacer()
          Button {
            dismiss()
          } label: {
            Label {
              Text("Done")
            } icon: {
              Image(systemName: "checkmark")
            }
          }
          .buttonStyle(.borderedProminent)
        }
        
        if let event = model.event {
          EventListView.CellView(event: event)
            .contentShape(.rect)
            .onTapGesture {
              model.isPresentedEventPicker.toggle()
            }
        } else {
          Button {
            model.isPresentedEventPicker.toggle()
          } label: {
            Group {
              if let eventName = model.event?.name {
                Text(eventName)
              } else {
                Text("Select Event")
              }
            }
            .font(.title3.bold())
            .frame(maxWidth: .infinity)
          }
          .buttonStyle(.borderedProminent)
        }

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
      .sheet(isPresented: $model.isPresentedEventPicker) {
        EventPicker(event: $model.event)
      }
    }
  }
}



#Preview {
  @Previewable @Environment(\.calendar) var calendar
  
  return NewRecordView(model: .init(defaultVintage: calendar.component(.year, from: .now)))
    .environment(\.locale, Locale(identifier: "ja"))
}
