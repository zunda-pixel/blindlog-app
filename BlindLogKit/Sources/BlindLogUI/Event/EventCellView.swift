import SwiftUI

extension EventListView {
  struct CellView: View {
    var event: Event

    var body: some View {
      VStack(alignment: .leading, spacing: 5) {
        Text(event.name)
          .font(.title3.bold())

        HStack {
          Label {
            Text(
              "\(event.startDate, style: .date) ~ \(event.endDate, format: .dateTime.month().day())"
            )
          } icon: {
            Image(systemName: "calendar")
          }
          .labelIconToTitleSpacing(1)

          Label {
            Text(event.answerAnnouncementDate, style: .date)
          } icon: {
            Image(systemName: "checkmark")
          }
          .labelIconToTitleSpacing(1)
        }
        .font(.caption)

        Label {
          Text(event.organizer.name)
        } icon: {
          Image(systemName: "storefront")
        }
        .labelIconToTitleSpacing(1)
        .font(.caption)
      }
    }
  }
}

#Preview {
  List {
    EventListView.CellView(event: .laVineeEbisu001)
    EventListView.CellView(event: .laVineeEbisu002)
  }
}
