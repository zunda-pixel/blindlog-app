import Foundation

struct UserToken: Codable, Hashable {
  var id: UUID
  var token: String
  var refreshToken: String
}
