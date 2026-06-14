import SwiftUI
import API

/// A searchable, multi-selection list for choosing wine varieties. Tapping a
/// row toggles its membership; selected rows show a checkmark.
struct WineVarietyPickerView: View {
  let varieties: [WineVariety]
  @Binding var selection: Set<UUID>

  @State private var query = ""

  private var filtered: [WineVariety] {
    let trimmed = query.trimmingCharacters(in: .whitespaces)
    let sorted = varieties.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    guard !trimmed.isEmpty else { return sorted }
    return sorted.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
  }

  var body: some View {
    List {
      ForEach(filtered) { variety in
        Button {
          toggle(variety.id)
        } label: {
          HStack {
            Text(variety.name)
            Spacer()
            if selection.contains(variety.id) {
              Image(systemName: "checkmark")
            }
          }
        }
      }
    }
    .searchable(text: $query)
    .navigationTitle("Varieties")
  }

  private func toggle(_ id: UUID) {
    if selection.contains(id) {
      selection.remove(id)
    } else {
      selection.insert(id)
    }
  }
}
