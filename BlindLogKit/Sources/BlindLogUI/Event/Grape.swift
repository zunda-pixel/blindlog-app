import Foundation

struct Grape: Identifiable, Hashable, Sendable, Codable {
  var id: UUID
  var name: String
  var localizedNames: [String: String]
}
