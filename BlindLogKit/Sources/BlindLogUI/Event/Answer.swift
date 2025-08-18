import Foundation

struct Answer: Identifiable, Hashable, Sendable, Codable {
  var id: UUID
  var vintage: Int
  var area: Area
  var grapes: [GrapePercentage]
  var alcoholPercentage: Double
}

struct GrapePercentage: Identifiable, Hashable, Sendable, Codable {
  var id: UUID
  var grape: Grape
  var percent: Double
}

