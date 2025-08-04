import Foundation

struct Event: Identifiable, Hashable, Sendable, Codable {
  var id: UUID
  var name: String
  var organizer: Organizer
  var startDate: Date
  var endDate: Date
  var answerAnnouncementDate: Date
  var tastingCount: Int
  var answers: [Answer] = []
}

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

struct Grape: Identifiable, Hashable, Sendable, Codable {
  var id: UUID
  var name: String
}

extension Event {
  static let laVineeEbisu001: Event = Event(
    id: UUID(),
    name: "No.1 Weekend Blind Tasting Wine in only France",
    organizer: .laVineeEbisu,
    startDate: .now.addingTimeInterval(60 * 60 * 24 * (7 * 4)),
    endDate: .now.addingTimeInterval(60 * 60 * 24 * (7 * 4 + 2)),
    answerAnnouncementDate: .now.addingTimeInterval(60 * 60 * 24 * (7 * 4 + 3)),
    tastingCount: 3
  )

  static let laVineeEbisu002: Event = Event(
    id: UUID(),
    name: "No.2 Weekend Blind Tasting Wine in only France",
    organizer: .laVineeEbisu,
    startDate: .now.addingTimeInterval(60 * 60 * 24 * (7 * 3)),
    endDate: .now.addingTimeInterval(60 * 60 * 24 * (7 * 3 + 2)),
    answerAnnouncementDate: .now.addingTimeInterval(60 * 60 * 24 * (7 * 3 + 3)),
    tastingCount: 3
  )

  static let laVineeEbisu003: Event = Event(
    id: UUID(),
    name: "No.3 Weekend Blind Tasting Wine in only France",
    organizer: .laVineeEbisu,
    startDate: .now.addingTimeInterval(60 * 60 * 24 * (7 * 2)),
    endDate: .now.addingTimeInterval(60 * 60 * 24 * (7 * 2 + 2)),
    answerAnnouncementDate: .now.addingTimeInterval(60 * 60 * 24 * (7 * 2 + 3)),
    tastingCount: 3
  )

  static let laVineeEbisu004: Event = Event(
    id: UUID(),
    name: "No.4 Weekend Blind Tasting Wine in only France",
    organizer: .laVineeEbisu,
    startDate: .now.addingTimeInterval(60 * 60 * 24 * (7 * 1)),
    endDate: .now.addingTimeInterval(60 * 60 * 24 * (7 * 1 + 2)),
    answerAnnouncementDate: .now.addingTimeInterval(60 * 60 * 24 * (7 * 1 + 3)),
    tastingCount: 3
  )

  static let winemarketpartyEbisu: Event = Event(
    id: UUID(),
    name: "Blind Tasting Wine",
    organizer: .winemarketpartyEbisu,
    startDate: .now.addingTimeInterval(60 * 60 * 24 * 1),
    endDate: .now.addingTimeInterval(60 * 60 * 24 * 3),
    answerAnnouncementDate: .now.addingTimeInterval(60 * 60 * 24 * 4),
    tastingCount: 3
  )
}

struct Organizer: Identifiable, Hashable, Sendable, Codable {
  var id: UUID
  var name: String
}

extension Organizer {
  static let laVineeEbisu: Organizer = Organizer(id: UUID(), name: "La Vinee Ebisu")
  static let winemarketpartyEbisu: Organizer = Organizer(
    id: UUID(), name: "WINE MARKET PARTY Ebisu")
}
