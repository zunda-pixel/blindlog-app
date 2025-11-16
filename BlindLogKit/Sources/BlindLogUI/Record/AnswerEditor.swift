import SwiftUI

struct AnswerEditor: View {
  @State var isPresentedAreaPicker = false
  @State var isPresentedMultiGrapePicker = false
  @Binding var answer: NewRecordView.Answer
  @Environment(\.locale) var locale
  @State var newGrape: Grape?
  @Environment(\.calendar) var calendar
  
  var productionAreaSection: some View {
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
  }
  
  var vintageSection: some View {
    Section {
      Picker(selection: $answer.vintage) {
        let distantPastYear = calendar.component(.year, from: .distantPast)
        let distantFutureYear = calendar.component(.year, from: .distantFuture)
        let range = Range(uncheckedBounds: (distantPastYear, distantFutureYear))
        
        ForEach(range, id: \.self) { i in
          Text(calendar.date(from: DateComponents(year: i))!, format: .dateTime.year())
            .tag(i)
        }
      } label: {
        Text("Vintage")
      }
      .pickerStyle(.menu)
    } header: {
      Text("Vintage")
    }
  }
  
  var grapesSection: some View {
    Section {
      ForEach($answer.grapes) { grape in
        HStack {
          Text(grape.wrappedValue.grape.localizedNames[locale.language.languageCode?.identifier ?? ""] ?? grape.wrappedValue.grape.name)
          Spacer()
          TextField(
            value: grape.percent,
            format: .percent.precision(.fractionLength(1)),
            prompt:  Text(0.12, format: .percent)
          ) {
            Text("Percent")
          }
          .frame(maxWidth: 70)
          .textFieldStyle(.roundedBorder)
          #if !os(macOS)
          .keyboardType(.numberPad)
          #endif
        }
        .contextMenu {
          Button(role: .destructive) {
            answer.grapes.removeAll(where: { $0.id == grape.id })
          }
        }
      }
    } header: {
      Text("Grapes")
    }
    .sectionActions {
      Button {
        isPresentedMultiGrapePicker.toggle()
      } label: {
        Text(answer.grapes.isEmpty ? "Select Grape" : "Add Grape")
      }
      .contentShape(.rect)
      .sheet(isPresented: $isPresentedMultiGrapePicker) {
        guard let newGrape else { return }
        guard answer.grapes.contains(where: { $0.grape.id == newGrape.id }) == false else { return }
        answer.grapes.append(.init(id: UUID(), grape: newGrape, percent: 1.00))
      } content: {
        GrapePicker(grape: $newGrape)
      }
    }
  }
  
  var alcoholSection: some View {
    Section {
      HStack {
        TextField(
          value: $answer.alcoholPercentage,
          format: .percent.precision(.fractionLength(1)),
          prompt:  Text(0.12, format: .percent)
        ) {
          Text("Alcohol Percentage")
        }
        .textFieldStyle(.roundedBorder)
        #if !os(macOS)
        .keyboardType(.decimalPad)
        #endif
        Stepper(value: $answer.alcoholPercentage, step: 0.005) {
          Text("Alcohol Percentage")
        }
          .labelsHidden()
      }
    } header: {
      Text("Alcohol Percentage")
    }
  }
  
  var otherDetailSection: some View {
    Section {
      LabeledContent {
        HStack {
          Slider(value: $answer.colorIntensity, in: 0...1, step: 0.1)
          Text(answer.colorIntensity, format: .percent.precision(.fractionLength(1)))
        }
      } label: {
        HStack {
          Text("Color Intensity")
          Spacer()
        }
      }
      
      LabeledContent {
        HStack {
          Slider(value: $answer.acidity, in: 0...1, step: 0.1)
          Text(answer.acidity, format: .percent.precision(.fractionLength(1)))
        }
      } label: {
        HStack {
          Text("Acidity")
          Spacer()
        }
      }
      
      LabeledContent {
        HStack {
          Slider(value: $answer.tannin, in: 0...1, step: 0.1)
          Text(answer.tannin, format: .percent.precision(.fractionLength(1)))
        }
      } label: {
        HStack {
          Text("Tannin")
          Spacer()
        }
      }
      
      LabeledContent {
        HStack {
          Slider(value: $answer.minerality, in: 0...1, step: 0.1)
          Text(answer.minerality, format: .percent.precision(.fractionLength(1)))
        }
      } label: {
        HStack {
          Text("Minerality")
          Spacer()
        }
      }
      
      LabeledContent {
        HStack {
          Slider(value: $answer.sweety, in: 0...1, step: 0.1)
          Text(answer.sweety, format: .percent.precision(.fractionLength(1)))
        }
      } label: {
        HStack {
          Text("Sweety")
          Spacer()
        }
      }
    } header: {
      Text("Detail")
    }
  }
  
  var noteSection: some View {
    Section {
      TextEditor(text: $answer.note)
        .frame(minHeight: 200)
    } header: {
      Text("Note")
    }
  }
  
  var body: some View {
    List {
      productionAreaSection

      grapesSection
      
      vintageSection
      
      alcoholSection
      
      otherDetailSection
      
      noteSection
    }
    .scrollDismissesKeyboard(.immediately)
    #if !os(macOS)
    .listSectionSpacing(0)
    #endif
  }
}
