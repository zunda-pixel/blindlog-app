import AuthenticationServices
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct AddSignInOptionView: View {
  @Environment(NavigationRouter.self) var router
  @Environment(AuthStore.self) var authStore
  @Environment(StartView.ViewModel.self) var startViewModel
  
  @State var isPresentedPasskeyAddAlert = false
  @State var passkeyName = ""
  @State var isPresentedPasskeyNameIsEmpty = false
  
  func addPasskey() async throws {
    let api = API()
    let challenge = try await api.getChallenge(token: authStore.userToken.token)
    let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
    let controller = PasskeyController(anchor: .init(windowScene: windowScene!))
    let authorization = try await controller.addPasskey(
      domain: api.baseURL.host()!,
      userId: authStore.user.id,
      userName: passkeyName,
      challenge: challenge,
      preferImmediatelyAvailableCredentials: false
    )

    guard
      let credential = authorization.credential
        as? ASAuthorizationPlatformPublicKeyCredentialRegistration
    else {
      throw PasskeyAddError.unexpectedCredential
    }

    try await api.addPasskey(
      token: authStore.userToken.token,
      challenge: challenge,
      credentail: credential
    )
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
        ForEach(authStore.user.emails, id: \.email) { email in
          Label(email.email, systemImage: "envelope")
        }
        if authStore.user.emails.isEmpty {
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
          startViewModel.isCompleted = true
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
    user: User.init(userID: .init(), emails: []),
    userToken: UserToken(
      userID: .init(),
      token: "token",
      tokenExpiredDate: .now,
      refreshToken: "refreshToken",
      refreshTokenExpiredDate: .now
    )
  )))
}

private enum PasskeyAddError: LocalizedError {
  case missingPresentationAnchor
  case unexpectedCredential

  var errorDescription: String? {
    switch self {
    case .missingPresentationAnchor:
      return "Could not find a window to present the passkey sheet."
    case .unexpectedCredential:
      return "The passkey flow returned an unexpected credential."
    }
  }
}
