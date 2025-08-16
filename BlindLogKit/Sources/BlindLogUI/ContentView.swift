import SwiftUI

public struct ContentView: View {
  public init() {}
  @State var selectedTab: TabItem = .records

  @ViewBuilder
  func tabViewContent(_ tab: TabItem) -> some View {
    switch tab {
    case .records: RecordListView()
    case .events: EventListView()
    case .mypage: MyPageView()
    }
  }

  public var body: some View {
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
    #endif
  }
}

#Preview {
  ContentView()
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
