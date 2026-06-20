import SwiftUI
import MapKit
import API

/// The address/coordinate chosen from a search result.
struct VenueSelection: Sendable {
  var coordinate: GeoCoordinate
  var name: String?
  var addressLine1: String?
  var countryCode: String?
  var locality: String?
}

private struct VenueSearchResult: Identifiable, Sendable {
  let id = UUID()
  let title: String
  let subtitle: String
  let selection: VenueSelection
}

/// A text-search picker for the venue location, similar to the Calendar app:
/// the user types a place or address and picks from live search results. The
/// chosen result's coordinate and address are returned to the caller.
struct VenueLocationPickerView: View {
  @Binding var coordinate: GeoCoordinate?
  /// Called with the selected place's details.
  var onSelect: (VenueSelection) -> Void

  @Environment(\.dismiss) private var dismiss
  @State private var query = ""
  @State private var results: [VenueSearchResult] = []
  @State private var isSearching = false

  private var trimmedQuery: String {
    query.trimmingCharacters(in: .whitespaces)
  }

  var body: some View {
    List {
      ForEach(results) { result in
        Button {
          coordinate = result.selection.coordinate
          onSelect(result.selection)
          dismiss()
        } label: {
          VStack(alignment: .leading, spacing: 2) {
            Text(result.title)
              .font(.headline)
            if !result.subtitle.isEmpty {
              Text(result.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
          .contentShape(.rect)
        }
      }

      if results.isEmpty, !trimmedQuery.isEmpty, !isSearching {
        ContentUnavailableView.search(text: trimmedQuery)
      }
    }
    .overlay {
      if isSearching { ProgressView() }
    }
    .searchable(text: $query, prompt: "Search for a place or address")
    .navigationTitle("Venue Location")
    .task(id: query) { await runSearch() }
  }

  private func runSearch() async {
    guard !trimmedQuery.isEmpty else {
      results = []
      return
    }
    // Debounce: `.task(id:)` cancels this when the query changes again.
    try? await Task.sleep(for: .milliseconds(300))
    if Task.isCancelled { return }

    isSearching = true
    defer { isSearching = false }
    results = await Self.search(trimmedQuery)
  }

  private static func search(_ query: String) async -> [VenueSearchResult] {
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = query
    let search = MKLocalSearch(request: request)
    return await withCheckedContinuation { continuation in
      search.start { response, _ in
        let results = (response?.mapItems ?? []).map(makeResult)
        continuation.resume(returning: results)
      }
    }
  }

  private static func makeResult(_ item: MKMapItem) -> VenueSearchResult {
    let placemark = item.placemark
    let streetLine = [placemark.subThoroughfare, placemark.thoroughfare]
      .compactMap { $0 }
      .joined(separator: " ")
    let selection = VenueSelection(
      coordinate: GeoCoordinate(
        latitude: placemark.coordinate.latitude,
        longitude: placemark.coordinate.longitude
      ),
      name: item.name,
      addressLine1: streetLine.isEmpty ? item.name : streetLine,
      countryCode: placemark.isoCountryCode,
      locality: placemark.locality
    )
    let subtitle = [placemark.locality, placemark.administrativeArea, placemark.country]
      .compactMap { $0 }
      .joined(separator: ", ")
    return VenueSearchResult(
      title: item.name ?? streetLine,
      subtitle: subtitle,
      selection: selection
    )
  }
}
