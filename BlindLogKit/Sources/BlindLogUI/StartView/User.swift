import Foundation

struct User: Codable, Hashable, Identifiable {
  var id: UUID
  var email: String?
}
