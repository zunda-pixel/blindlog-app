import SwiftUI

struct MyPageView: View {
  var body: some View {
    NavigationStack {
      List {
        Label {
          Text("Profile")
        } icon: {
          Image(systemName: "person.crop.circle")
        }
      }
    }
  }
}
