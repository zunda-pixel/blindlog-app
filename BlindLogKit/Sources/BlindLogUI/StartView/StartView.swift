import SwiftUI
import Valet
import Defaults

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
  
  var body: some View {
    NavigationStack(path: $router.items) {
      List {
        Section {
          Text("Welcome to the app!")
        }
        
        Section {
          Button {
            Task {
              do {
                let userToken = try await api.getNewUser()
                let user = try await api.getMe(token: userToken)
                router.items.append(.addSignInOption(user, userToken))
              } catch {
                print(error)
              }
            }
          } label: {
            Text("continue as a guest")
          }
        }
        
        Section {
          Button {
            
          } label: {
            Text("Sign up")
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
  
  init(user: User, userToken: UserToken) {
    self.user = user
    self.userToken = userToken
  }
}

#Preview {
  StartView()
}
