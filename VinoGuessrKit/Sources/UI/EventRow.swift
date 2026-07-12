import SwiftUI
import API

/// A compact summary row for an event, used in the event list and My Page.
struct EventRow: View {
  let event: Event

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(event.title)
        .font(.headline)
      Text(event.venueName)
        .font(.subheadline)
        .foregroundStyle(.secondary)
      Text(event.eventPeriod.startsAt, style: .date)
        .font(.caption)
        .foregroundStyle(.tertiary)
    }
  }
}

#Preview {
  List {
    EventRow(event: PreviewSamples.event)
  }
}
