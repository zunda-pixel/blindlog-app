import SwiftUI
import Defaults

struct MyPageView: View {
  var body: some View {
    NavigationStack {
      List {
        Label {
          Text("Profile")
        } icon: {
          Image(systemName: "person.crop.circle")
        }
        
        Button {
          Defaults[.userID] = nil
        } label: {
          Text("Logout")
        }
        .buttonStyle(.borderedProminent)
      }
    }
  }
}
