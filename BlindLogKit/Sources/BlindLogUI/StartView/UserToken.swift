import Foundation

struct UserToken: Codable, Hashable {
  var userID: UUID
  var token: String
  var refreshToken: String
}
