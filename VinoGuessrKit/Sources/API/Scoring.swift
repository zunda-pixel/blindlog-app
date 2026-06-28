import Foundation

/// Pure scoring for a participant's response against a question's correct
/// answer. Lives in the API layer (free of SwiftUI) so it can be unit-tested
/// directly. The backend exposes no results endpoint, so per-question scoring
/// is computed on the client from the event's `regionScoreRules`.
public enum Scoring {
  /// The outcome of comparing one response to the correct answer.
  ///
  /// Match flags are `nil` when the correct answer left that field unset (so the
  /// UI can omit it rather than show a misleading "wrong").
  public struct QuestionResult: Equatable, Sendable {
    public var pointsEarned: Int32
    public var regionMatch: Bool
    public var vintageMatch: Bool?
    public var abvMatch: Bool?
    public var varietyMatch: Bool?

    public init(
      pointsEarned: Int32,
      regionMatch: Bool,
      vintageMatch: Bool? = nil,
      abvMatch: Bool? = nil,
      varietyMatch: Bool? = nil
    ) {
      self.pointsEarned = pointsEarned
      self.regionMatch = regionMatch
      self.vintageMatch = vintageMatch
      self.abvMatch = abvMatch
      self.varietyMatch = varietyMatch
    }
  }

  /// Scores `response` against `correct`. Region points are awarded only when
  /// the response's region exactly matches the correct region; the points come
  /// from the `rules` entry for that region's type.
  public static func score(
    response: EventQuestionResponse,
    correct: EventQuestionCorrectAnswer,
    regions: [WineRegion],
    rules: [EventRegionScoreRule]
  ) -> QuestionResult {
    let regionMatch = correct.wineRegionID != nil && response.wineRegionID == correct.wineRegionID

    var points: Int32 = 0
    if regionMatch,
       let regionID = correct.wineRegionID,
       let typeID = regions.first(where: { $0.id == regionID })?.wineRegionTypeID,
       let rule = rules.first(where: { $0.wineRegionTypeID == typeID }) {
      points = rule.points
    }

    let vintageMatch = correct.vintage.map { $0 == response.vintage }
    let abvMatch = correct.alcoholByVolume.map { $0 == response.alcoholByVolume }
    let varietyMatch = correct.wineVarietyIDs.isEmpty
      ? nil
      : Set(correct.wineVarietyIDs) == Set(response.wineVarietyIDs)

    return QuestionResult(
      pointsEarned: points,
      regionMatch: regionMatch,
      vintageMatch: vintageMatch,
      abvMatch: abvMatch,
      varietyMatch: varietyMatch
    )
  }
}
