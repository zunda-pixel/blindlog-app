import Foundation

struct User: Hashable {
  var userID: UUID
  var emails: [Email]
}

extension User: Codable {
}

extension User: Identifiable {
  var id: UUID { userID }
}

struct Email: Codable, Hashable {
  var email: String
  var createdAt: Date
}
