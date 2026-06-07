import SwiftUI
import Valet
import Defaults
import AuthenticationServices

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Valet {
  static var shared: Valet {
    Valet.valet(
     with: .init(nonEmpty: "com.blindlog.Blindlog")!,
     accessibility: .afterFirstUnlock
   )
  }
}

extension Defaults.Keys {
  static let userID = Key<UUID?>("currentUserID")
}

struct StartView: View {
  @Environment(ViewModel.self) var viewModel
  
  @Observable
  final class ViewModel {
    var isCompleted: Bool
    
    init() {
      guard let userID = Defaults[.userID] else {
        isCompleted = false
        return
      }

      do {
        guard try Valet.shared.containsObject(forKey: "userToken:\(userID.uuidString)") else {
          isCompleted = false
          return
        }
        let data = try Valet.shared.object(forKey: "userToken:\(userID.uuidString)")
        _ = try JSONDecoder().decode(UserToken.self, from: data)
        isCompleted = true
      } catch {
        isCompleted = false
      }
    }
  }

  @State var router = NavigationRouter()
  let api = API()

  func store(userToken: UserToken) throws {
    let data = try JSONEncoder().encode(userToken)
    try Valet.shared.setObject(data, forKey: "userToken:\(userToken.userID.uuidString)")
    Defaults[.userID] = userToken.userID
  }

  func createUser() async {
    do {
      let userToken = try await api.getNewUser()
      let user = try await api.getMe(token: userToken)
      try store(userToken: userToken)
      await MainActor.run {
        router.items.append(.addSignInOption(user, userToken))
      }
    } catch {
      print(error)
    }
  }

  func signInWithPasskey() async {
    do {
      let challenge = try await api.getChallenge()
      let controller = try PasskeyController(anchor: currentPresentationAnchor())
      let authorization = try await controller.signIn(
        domain: api.baseURL.host()!,
        challenge: challenge,
        preferImmediatelyAvailableCredentials: false
      )

      guard
        let credential = authorization.credential
          as? ASAuthorizationPlatformPublicKeyCredentialAssertion
      else {
        throw PasskeySignInError.unexpectedCredential
      }

      let userToken = try await api.getToken(challenge: challenge, credential: credential)
      try store(userToken: userToken)
      await MainActor.run {
        viewModel.isCompleted = true
      }
    } catch {
      print(error)
    }
  }

  func currentPresentationAnchor() throws -> ASPresentationAnchor {
#if canImport(UIKit)
    let windowScene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first
    let window = windowScene?.windows.first(where: \.isKeyWindow) ?? windowScene?.windows.first

    guard let window else {
      throw PasskeySignInError.missingPresentationAnchor
    }

    return window
#elseif canImport(AppKit)
    guard let window = NSApp.keyWindow ?? NSApp.windows.first else {
      throw PasskeySignInError.missingPresentationAnchor
    }

    return window
#else
    throw PasskeySignInError.missingPresentationAnchor
#endif
  }
  
  var body: some View {
    NavigationStack(path: $router.items) {
      List {
        Section {
          Text("Welcome to the app!")
        }
        
        Section {
          Button {
            Task {
              await createUser()
            }
          } label: {
            Text("continue as a guest")
          }
        }
        
        Section {
          Button {
            Task {
              await signInWithPasskey()
            }
          } label: {
            Text("Sign in with Passkey")
          }
        }
      }
      .navigationDestination(for: NavigationRouter.Item.self) { item in
        switch item {
        case .addSignInOption(let user, let userToken):
          AddSignInOptionView()
            .navigationTitle(Text("Sign in Options"))
            .environment(AuthStore(user: user, userToken: userToken))
        case .sendVerifyEmailView:
          SendVerifyEmailView()
        case .emailVerifyOneTimeCode(let email):
          EmailVerifyOneTimeCodeView(email: email)
        }
      }
    }
    .environment(router)
  }
}

@Observable
final class NavigationRouter {
  var items: [Item] = []
  
  enum Item: Hashable {
    case addSignInOption(User, UserToken)
    case sendVerifyEmailView
    case emailVerifyOneTimeCode(String)
  }
}

@Observable
final class AuthStore {
  var user: User
  var userToken: UserToken
  
  init(
    user: User,
    userToken: UserToken
  ) {
    self.user = user
    self.userToken = userToken
  }
}

#Preview {
  StartView()
}

private enum PasskeySignInError: LocalizedError {
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
