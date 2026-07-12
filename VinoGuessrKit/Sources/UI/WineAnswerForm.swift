import API
import Observation
import SwiftUI

/// The shared, observable state behind the wine-answer input rows: the loaded
/// catalog and the current selection (region, varieties, vintage, alcohol by
/// volume). Lifting this out of the parent view lets the region/variety pickers
/// be pushed with value-based routing and mutate the selection directly through
/// the environment, instead of threading `@Binding`s through `NavigationLink`.
@Observable
final class WineAnswerDraft {
  var catalog: WineCatalog
  var catalogState: WineAnswerForm.CatalogState
  var selectedRegionID: UUID?
  var selectedVarietyIDs: Set<UUID>
  var vintageText: String
  var abvText: String

  init(
    catalog: WineCatalog = WineCatalog(),
    catalogState: WineAnswerForm.CatalogState = .loading,
    selectedRegionID: UUID? = nil,
    selectedVarietyIDs: Set<UUID> = [],
    vintageText: String = "",
    abvText: String = ""
  ) {
    self.catalog = catalog
    self.catalogState = catalogState
    self.selectedRegionID = selectedRegionID
    self.selectedVarietyIDs = selectedVarietyIDs
    self.vintageText = vintageText
    self.abvText = abvText
  }
}

/// The shared wine-answer input rows — region, varieties, vintage, and alcohol
/// by volume — used both when an organizer sets a question's correct answer
/// (`CreateQuestionView`) and when a participant submits their guess
/// (`AnswerQuestionView`). The rows read and write the `WineAnswerDraft` from
/// the environment, and push the region/variety pickers through the `Router` so
/// no `NavigationLink` is needed. Meant to be placed inside a `Form` `Section`.
struct WineAnswerForm: View {
  enum CatalogState: Equatable { case loading, loaded, failed }

  @Environment(WineAnswerDraft.self) private var draft
  @Environment(Router.self) private var router

  var onRetry: () -> Void

  var body: some View {
    @Bindable var draft = draft
    Group {
      switch draft.catalogState {
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
        Button {
          router.items.append(.wineRegionPicker)
        } label: {
          LabeledContent("Region", value: draft.catalog.regionName(draft.selectedRegionID) ?? "None")
            .contentShape(.rect)
        }
        .buttonStyle(.plain)

        Button {
          router.items.append(.wineVarietyPicker)
        } label: {
          LabeledContent("Varieties", value: selectedVarietiesSummary)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
      }

      TextField("Vintage (year)", text: $draft.vintageText)
      TextField("Alcohol by volume (%)", text: $draft.abvText)
    }
  }

  private var selectedVarietiesSummary: String {
    let names = draft.catalog.varietyNames(draft.selectedVarietyIDs)
    return names.isEmpty ? "None" : names.joined(separator: ", ")
  }
}
#Preview {
  @Previewable @State var draft = PreviewSamples.draft
  @Previewable @State var router = Router()

  Form {
    Section("Correct Answer") {
      WineAnswerForm(onRetry: {})
    }
  }
  .environment(draft)
  .environment(router)
}

