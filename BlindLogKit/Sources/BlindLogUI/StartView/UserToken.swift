import Foundation

struct UserToken: Codable, Hashable {
  var userID: UUID
  var token: String
  var tokenExpiredDate: Date
  var refreshToken: String
  var refreshTokenExpiredDate: Date
}
