import SwiftUI
import API

/// A searchable, single-selection list for choosing a wine region (the
/// "place" of a wine). Includes a "None" option to clear the selection.
struct WineRegionPickerView: View {
  let regions: [WineRegion]
  @Binding var selection: UUID?

  @Environment(\.dismiss) private var dismiss
  @State private var query = ""

  private var filtered: [WineRegion] {
    let trimmed = query.trimmingCharacters(in: .whitespaces)
    let sorted = regions.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    guard !trimmed.isEmpty else { return sorted }
    return sorted.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
  }

  var body: some View {
    List {
      Button {
        selection = nil
        dismiss()
      } label: {
        HStack {
          Text("None")
          Spacer()
          if selection == nil {
            Image(systemName: "checkmark")
          }
        }
      }

      ForEach(filtered) { region in
        Button {
          selection = region.id
          dismiss()
        } label: {
          HStack {
            Text(region.name)
            Spacer()
            if selection == region.id {
              Image(systemName: "checkmark")
            }
          }
        }
      }
    }
    .searchable(text: $query)
    .navigationTitle("Region")
  }
}
