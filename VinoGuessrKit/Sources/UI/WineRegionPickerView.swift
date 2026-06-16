import SwiftUI
import API

/// One node of the region tree, built from the flat `WineRegion` list so it can
/// drive `OutlineGroup`. `children` is `nil` for leaves so no disclosure
/// triangle is shown.
private struct RegionNode: Identifiable {
  let region: WineRegion
  var children: [RegionNode]?

  var id: UUID { region.id }
}

/// A hierarchical, single-selection picker for choosing a wine region.
///
/// Regions form a tree via `parentRegionID` (e.g. France › Bordeaux). The tree
/// is rendered with `OutlineGroup`, which manages expansion itself; every
/// region — parent or leaf — is selectable. A search field flattens the tree to
/// matching regions, and a "None" option clears the selection.
struct WineRegionPickerView: View {
  let regions: [WineRegion]
  @Binding var selection: UUID?

  @Environment(\.dismiss) private var dismiss
  @State private var query = ""

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
        OutlineGroup(rootNodes, children: \.children) { node in
          regionButton(node.region)
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

  /// Builds the region tree rooted at the top-level (parentless) regions.
  private var rootNodes: [RegionNode] {
    nodes(parentID: nil)
  }

  private func nodes(parentID: UUID?) -> [RegionNode] {
    regions
      .filter { $0.parentRegionID == parentID }
      .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
      .map { region in
        let children = nodes(parentID: region.id)
        return RegionNode(region: region, children: children.isEmpty ? nil : children)
      }
  }

  private var flatMatches: [WineRegion] {
    regions
      .filter { $0.name.localizedCaseInsensitiveContains(trimmedQuery) }
      .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
  }
}
