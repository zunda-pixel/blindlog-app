import Foundation
import Observation

@Observable
final class Router {
  var items: [Item] = []

  enum Item: Hashable {
     case createAccount
  }
}
