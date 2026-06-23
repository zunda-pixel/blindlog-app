import SwiftUI
import API

/// A multi-selection picker for wine varieties, grouped into a section per wine
/// style (Red, White). A variety belongs to a section when its `wineStyleIDs`
/// contains that style. A search field filters within the sections. Tapping a
/// row toggles its membership.
struct WineVarietyPickerView: View {
  let varieties: [WineVariety]
  let styles: [WineStyle]
  @Binding var selection: Set<UUID>

  @State private var query = ""

  private var trimmedQuery: String {
    query.trimmingCharacters(in: .whitespaces)
  }

  /// Styles ordered red first, then white, then any others by name.
  private var orderedStyles: [WineStyle] {
    styles.sorted { lhs, rhs in
      func rank(_ code: String) -> Int {
        switch code.lowercased() {
        case "red": 0
        case "white": 1
        default: 2
        }
      }
      let l = rank(lhs.code), r = rank(rhs.code)
      return l == r ? lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending : l < r
    }
  }

  var body: some View {
    List {
      ForEach(orderedStyles) { style in
        let items = varieties(for: style.id)
        if !items.isEmpty {
          Section(style.name) {
            ForEach(items) { variety in
              row(variety)
            }
          }
        }
      }
    }
    .searchable(text: $query)
    .navigationTitle("Varieties")
  }

  private func row(_ variety: WineVariety) -> some View {
    Button {
      toggle(variety.id)
    } label: {
      HStack {
        Text(variety.name)
        Spacer()
        if selection.contains(variety.id) {
          Image(systemName: "checkmark")
            .foregroundStyle(.tint)
        }
      }
      .contentShape(.rect)
    }
  }

  private func varieties(for styleID: UUID) -> [WineVariety] {
    varieties
      .filter { $0.wineStyleIDs.contains(styleID) }
      .filter { trimmedQuery.isEmpty || $0.name.localizedCaseInsensitiveContains(trimmedQuery) }
      .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
  }

  private func toggle(_ id: UUID) {
    if selection.contains(id) {
      selection.remove(id)
    } else {
      selection.insert(id)
    }
  }
}
