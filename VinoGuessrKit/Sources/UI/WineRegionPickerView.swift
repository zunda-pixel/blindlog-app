import SwiftUI
import API

/// A hierarchical, single-selection picker for choosing a wine region.
///
/// Regions form a tree via `parentRegionID` (e.g. France › Bordeaux). Parent
/// regions are shown as `DisclosureGroup`s that can be expanded to reveal their
/// children; every region — parent or leaf — is itself selectable. A search
/// field flattens the tree to matching regions. A "None" option clears the
/// selection.
struct WineRegionPickerView: View {
  let regions: [WineRegion]
  @Binding var selection: UUID?

  @Environment(\.dismiss) private var dismiss
  @State private var query = ""
  @State private var expanded: Set<UUID> = []

  private var roots: [WineRegion] {
    children(of: nil)
  }

  private var trimmedQuery: String {
    query.trimmingCharacters(in: .whitespaces)
  }

  var body: some View {
    List {
      Button {
        selection = nil
        dismiss()
      } label: {
        selectableLabel(title: "None", isSelected: selection == nil)
      }

      if trimmedQuery.isEmpty {
        ForEach(roots) { region in
          node(region)
        }
      } else {
        ForEach(flatMatches) { region in
          regionButton(region)
        }
      }
    }
    .searchable(text: $query)
    .navigationTitle("Region")
  }

  // MARK: Hierarchy

  // Returns `AnyView` because the function is recursive: an opaque `some View`
  // cannot be defined in terms of itself.
  @ContentBuilder
  private func node(_ region: WineRegion) -> some View {
    let kids = children(of: region.id)
    if kids.isEmpty {
      return regionButton(region)
    } else {
      return DisclosureGroup(isExpanded: expansionBinding(region.id)) {
        ForEach(kids) { child in
          node(child)
        }
      } label: {
        regionButton(region)
      }
    }
  }

  private func regionButton(_ region: WineRegion) -> some View {
    Button {
      selection = region.id
      dismiss()
    } label: {
      selectableLabel(title: region.name, isSelected: selection == region.id)
    }
  }

  private func selectableLabel(title: String, isSelected: Bool) -> some View {
    HStack {
      Text(title)
      Spacer()
      if isSelected {
        Image(systemName: "checkmark")
          .foregroundStyle(.tint)
      }
    }
    .contentShape(.rect)
  }

  // MARK: Data

  private func children(of parentID: UUID?) -> [WineRegion] {
    regions
      .filter { $0.parentRegionID == parentID }
      .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
  }

  private var flatMatches: [WineRegion] {
    regions
      .filter { $0.name.localizedCaseInsensitiveContains(trimmedQuery) }
      .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
  }

  private func expansionBinding(_ id: UUID) -> Binding<Bool> {
    Binding(
      get: { expanded.contains(id) },
      set: { isExpanded in
        if isExpanded { expanded.insert(id) } else { expanded.remove(id) }
      }
    )
  }
}
