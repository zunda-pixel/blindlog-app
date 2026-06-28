import API
import SwiftUI

/// The shared wine-answer input rows — region, varieties, vintage, and alcohol
/// by volume — used both when an organizer sets a question's correct answer
/// (`CreateQuestionView`) and when a participant submits their guess
/// (`AnswerQuestionView`). The rows are meant to be placed inside a `Form`
/// `Section`; the parent owns the catalog and its load state so the same data
/// can also drive a result view.
struct WineAnswerForm: View {
  enum CatalogState: Equatable { case loading, loaded, failed }

  let catalog: WineCatalog
  let catalogState: CatalogState
  var onRetry: () -> Void

  @Binding var selectedRegionID: UUID?
  @Binding var selectedVarietyIDs: Set<UUID>
  @Binding var vintageText: String
  @Binding var abvText: String

  var body: some View {
    Group {
      switch catalogState {
      case .loading:
        HStack {
          Text("Region")
          Spacer()
          ProgressView()
        }
      case .failed:
        HStack {
          Text("Couldn’t load wine data")
            .foregroundStyle(.secondary)
          Spacer()
          Button("Retry", action: onRetry)
        }
      case .loaded:
        NavigationLink {
          WineRegionPickerView(regions: catalog.regions, selection: $selectedRegionID)
        } label: {
          LabeledContent("Region", value: catalog.regionName(selectedRegionID) ?? "None")
        }

        NavigationLink {
          WineVarietyPickerView(
            varieties: catalog.varieties,
            styles: catalog.styles,
            selection: $selectedVarietyIDs
          )
        } label: {
          LabeledContent("Varieties", value: selectedVarietiesSummary)
        }
      }

      TextField("Vintage (year)", text: $vintageText)
      TextField("Alcohol by volume (%)", text: $abvText)
    }
  }

  private var selectedVarietiesSummary: String {
    let names = catalog.varietyNames(selectedVarietyIDs)
    return names.isEmpty ? "None" : names.joined(separator: ", ")
  }
}
