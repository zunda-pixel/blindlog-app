import SwiftUI
import Defaults

public struct ContentView: View {
  public init() {}
  @State var selectedTab: TabItem = .records
  var startViewModel = StartView.ViewModel()
  @Default(.userID) var userID

  @ViewBuilder
  func tabViewContent(_ tab: TabItem) -> some View {
    switch tab {
    case .records: RecordListView()
    case .events: EventListView()
    case .mypage: MyPageView()
    }
  }

  public var body: some View {
    if let userID, startViewModel.isCompleted {
      TabView(selection: $selectedTab) {
        ForEach(TabItem.allCases, id: \.self) { tab in
          Tab(value: tab) {
            tabViewContent(tab)
          } label: {
            Label {
              Text(tab.label)
            } icon: {
              Image(systemName: tab.iconName)
            }
          }
        }
      }
      #if !os(macOS)
      .tabBarMinimizeBehavior(.onScrollDown)
      .environment(\.userID, userID)
      #endif
    } else {
      StartView()
        .environment(startViewModel)
    }
  }
}

#Preview {
  ContentView()
    .environment(\.locale, .init(identifier: "ja"))
}

extension EnvironmentValues {
  @Entry var userID: UUID = .init()
}


enum TabItem: CaseIterable {
  case records
  case events
  case mypage
}

extension TabItem {
  var label: LocalizedStringKey {
    switch self {
    case .records: "BlindLog"
    case .events: "Events"
    case .mypage: "Mypage"
    }
  }

  var iconName: String {
    switch self {
    case .records: "calendar"
    case .events: "calendar"
    case .mypage: "person.crop.circle"
    }
  }
}
