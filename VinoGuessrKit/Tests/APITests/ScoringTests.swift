import Foundation
import Testing
@testable import API

/// Offline tests for the pure client-side scoring logic. No network access.
@Suite
struct ScoringTests {
  // Shared fixtures.
  private let regionTypeID = UUID()
  private let regionID = UUID()
  private let otherRegionID = UUID()
  private let varietyA = UUID()
  private let varietyB = UUID()

  private var regions: [WineRegion] {
    [
      WineRegion(id: regionID, parentRegionID: nil, wineRegionTypeID: regionTypeID, name: "Bordeaux"),
      WineRegion(id: otherRegionID, parentRegionID: nil, wineRegionTypeID: regionTypeID, name: "Burgundy"),
    ]
  }

  private var rules: [EventRegionScoreRule] {
    [EventRegionScoreRule(wineRegionTypeID: regionTypeID, points: 5, createdAt: Date())]
  }

  private func correct(
    region: UUID?,
    vintage: Int32? = nil,
    abv: Double? = nil,
    varieties: [UUID] = []
  ) -> EventQuestionCorrectAnswer {
    EventQuestionCorrectAnswer(
      id: UUID(),
      eventQuestionID: UUID(),
      wineRegionID: region,
      vintage: vintage,
      alcoholByVolume: abv,
      wineVarietyIDs: varieties,
      createdAt: Date()
    )
  }

  private func response(
    region: UUID?,
    vintage: Int32? = nil,
    abv: Double? = nil,
    varieties: [UUID] = []
  ) -> EventQuestionResponse {
    EventQuestionResponse(
      id: UUID(),
      eventQuestionID: UUID(),
      userID: UUID(),
      wineRegionID: region,
      vintage: vintage,
      alcoholByVolume: abv,
      note: nil,
      wineVarietyIDs: varieties,
      submittedAt: Date()
    )
  }

  @Test
  func exactRegionMatchAwardsRulePoints() {
    let result = Scoring.score(
      response: response(region: regionID),
      correct: correct(region: regionID),
      regions: regions,
      rules: rules
    )
    #expect(result.regionMatch)
    #expect(result.pointsEarned == 5)
  }

  @Test
  func regionMismatchAwardsNoPoints() {
    let result = Scoring.score(
      response: response(region: otherRegionID),
      correct: correct(region: regionID),
      regions: regions,
      rules: rules
    )
    #expect(!result.regionMatch)
    #expect(result.pointsEarned == 0)
  }

  @Test
  func noMatchingRuleAwardsNoPointsEvenWhenRegionMatches() {
    let result = Scoring.score(
      response: response(region: regionID),
      correct: correct(region: regionID),
      regions: regions,
      rules: []
    )
    #expect(result.regionMatch)
    #expect(result.pointsEarned == 0)
  }

  @Test
  func unsetCorrectFieldsProduceNilMatchFlags() {
    let result = Scoring.score(
      response: response(region: regionID, vintage: 2018, abv: 13.5, varieties: [varietyA]),
      correct: correct(region: regionID),
      regions: regions,
      rules: rules
    )
    #expect(result.vintageMatch == nil)
    #expect(result.abvMatch == nil)
    #expect(result.varietyMatch == nil)
  }

  @Test
  func vintageAbvAndVarietyMatchesAreReported() {
    let result = Scoring.score(
      response: response(region: regionID, vintage: 2018, abv: 13.5, varieties: [varietyA, varietyB]),
      correct: correct(region: regionID, vintage: 2018, abv: 13.5, varieties: [varietyB, varietyA]),
      regions: regions,
      rules: rules
    )
    #expect(result.vintageMatch == true)
    #expect(result.abvMatch == true)
    #expect(result.varietyMatch == true)  // order-independent
  }

  @Test
  func mismatchedDetailsAreReportedFalse() {
    let result = Scoring.score(
      response: response(region: regionID, vintage: 2019, abv: 12.0, varieties: [varietyA]),
      correct: correct(region: regionID, vintage: 2018, abv: 13.5, varieties: [varietyA, varietyB]),
      regions: regions,
      rules: rules
    )
    #expect(result.vintageMatch == false)
    #expect(result.abvMatch == false)
    #expect(result.varietyMatch == false)
  }
}
