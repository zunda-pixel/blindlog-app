import SwiftUI

struct SendVerifyEmailView: View {
  @State var email = ""
  @Environment(NavigationRouter.self) var router
  
  var body: some View {
    List {
      TextField(text: $email) {
        Text("Email")
      }
        .textContentType(.emailAddress)
      
      Button {
        router.items.append(.emailVerifyOneTimeCode(email))
      } label: {
        Text("Send Email")
      }
    }
  }
}

#Preview {
  @Previewable @State var router = NavigationRouter()
  
  NavigationStack(path: $router.items) {
    SendVerifyEmailView()
  }
    .environment(router)
}
