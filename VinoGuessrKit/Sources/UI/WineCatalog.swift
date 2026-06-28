import API
import Foundation

/// The wine master data (regions, varieties, styles) needed to render and
/// resolve answers. Loaded once and shared by the question-authoring form, the
/// participant answer form, and the result views so the three flows do not each
/// duplicate the catalog fetch and the id-to-name lookups.
struct WineCatalog: Sendable, Equatable {
  var regions: [WineRegion] = []
  var varieties: [WineVariety] = []
  var styles: [WineStyle] = []

  /// Fetches regions, varieties, and styles concurrently.
  static func load(using store: AccountStore) async throws -> WineCatalog {
    let api = try await store.authenticatedAPI()
    async let regions = api.wineRegions()
    async let varieties = api.wineVarieties()
    async let styles = api.wineStyles()
    return try await WineCatalog(regions: regions, varieties: varieties, styles: styles)
  }

  /// The display name for a region id, or `nil` when unset or unknown.
  func regionName(_ id: UUID?) -> String? {
    guard let id else { return nil }
    return regions.first { $0.id == id }?.name
  }

  /// The display names for a set of variety ids, sorted case-insensitively.
  func varietyNames(_ ids: some Sequence<UUID>) -> [String] {
    let ids = Set(ids)
    return varieties
      .filter { ids.contains($0.id) }
      .map(\.name)
      .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
  }
}
