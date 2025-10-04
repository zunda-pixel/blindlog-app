import SwiftUI

struct AddSignInOptionView: View {
  @Environment(NavigationRouter.self) var router
  @Environment(AuthStore.self) var authStore
  @State var isPresentedPasskeyAddAlert = false
  @State var passkeyName = ""
  @State var isPresentedPasskeyNameIsEmpty = false
  
  func addPasskey() async throws {
    
  }
  
  var body: some View {
    List {
      Section {
        Button  {
          isPresentedPasskeyAddAlert.toggle()
        } label: {
          Label {
            Text("Add Passkey")
          } icon: {
            Image(systemName: "person.badge.key")
          }
        }
        .alert(Text("Add Passkey"), isPresented: $isPresentedPasskeyAddAlert) {
          TextField(text: $passkeyName) {
            Text("Name")
          }
          Button(role: .confirm) {
            Task {
              do {
                guard !passkeyName.isEmpty else {
                  isPresentedPasskeyNameIsEmpty = true
                  return
                }
                try await addPasskey()
              } catch {
                print(error)
              }
            }
          }
          Button(role: .cancel) {
            isPresentedPasskeyAddAlert = false
          }
        } message: {
          Text("Please enter a name that will be displayed in the password management app.")
        }
        .alert(Text("Passkey name is empty"), isPresented: $isPresentedPasskeyNameIsEmpty) {
          Button(role: .close) {
            isPresentedPasskeyAddAlert = true
          }
        }
      }
      
      Section {
        if let email = authStore.user.email {
          Label(email, systemImage: "envelope")
        } else {
          Button {
            router.items.append(.sendVerifyEmailView)
          } label: {
            Label {
              Text("Add Email")
            } icon: {
              Image(systemName: "envelope")
            }
          }
        }
      }
      
      Section {
        Button {
          
        } label: {
          Text("Add sign option later")
        }
      }
    }
  }
}

#Preview {
  @Previewable @State var router = NavigationRouter()
  
  NavigationStack(path: $router.items) {
    AddSignInOptionView()
  }
  .environment(router)
  .environment((AuthStore(
    user: .init(id: .init()),
    userToken: .init(id: .init(), token: "token", refreshToken: "refreshToken")
  )))
}
