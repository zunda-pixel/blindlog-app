public import Foundation
import HTTPClient
import URLSessionHTTPClient
import MemberwiseInit

/// Endpoints that require an authenticated user, identified by a bearer token.
@MemberwiseInit(.public)
public struct API: APIEndpoint, Sendable {
  public var baseURL: URL = URL(string: "https://api.blindlog.me")!
  public var httpClient: URLSession = .shared
  public var token: String

  // MARK: Current User

  public func me() async throws -> Me {
    try await send(.get, "me", token: token)
  }

  public func createProfile(_ request: CreateUserProfileRequest) async throws -> UserProfile {
    try await send(.post, "me", token: token, body: encode(request))
  }

  public func startEmailVerification(email: String) async throws {
    try await send(.post, "email/verify/start", query: [URLQueryItem(name: "email", value: email)], token: token)
  }

  public func confirmEmail(_ request: ConfirmEmailRequest) async throws {
    try await send(.post, "email/verify", token: token, body: encode(request))
  }

  // MARK: Passkey

  public func createRegistrationChallenge() async throws -> String {
    try await send(.post, "challenge/registration", token: token)
  }

  public func addPasskey(_ passkey: AddPasskey) async throws {
    try await send(.post, "passkey", token: token, body: encode(passkey))
  }

  // MARK: Users

  public func userProfile(userID: UUID) async throws -> UserProfile {
    try await send(.get, "user_profile/\(userID.uuidString)", token: token)
  }

  public func organizedEvents(userID: UUID) async throws -> [Event] {
    try await send(.get, "users/\(userID.uuidString)/organized_events", token: token)
  }

  public func participatingEvents(userID: UUID) async throws -> [Event] {
    try await send(.get, "users/\(userID.uuidString)/participating_events", token: token)
  }

  // MARK: Images

  public func createImageUploadURL() async throws -> CreateImageUploadURLResponse {
    try await send(.post, "images/upload_url", token: token)
  }

  public func createImage(_ request: CreateImageRequest) async throws -> Image {
    try await send(.post, "images", token: token, body: encode(request))
  }

  // MARK: Events

  public func events() async throws -> [Event] {
    try await send(.get, "events", token: token)
  }

  public func createEvent(_ request: CreateEventRequest) async throws -> Event {
    try await send(.post, "events", token: token, body: encode(request))
  }

  public func event(id: UUID) async throws -> Event {
    try await send(.get, "events/\(id.uuidString)", token: token)
  }

  public func updateEvent(id: UUID, _ request: CreateEventRequest) async throws -> Event {
    try await send(.put, "events/\(id.uuidString)", token: token, body: encode(request))
  }

  public func registerParticipant(eventID: UUID) async throws -> EventParticipant {
    try await send(.post, "events/\(eventID.uuidString)/participants", token: token)
  }

  public func participants(eventID: UUID) async throws -> [EventParticipant] {
    try await send(.get, "events/\(eventID.uuidString)/participants", token: token)
  }

  public func updateMyParticipation(
    eventID: UUID,
    _ request: UpdateEventParticipantRequest
  ) async throws -> EventParticipant {
    try await send(.put, "events/\(eventID.uuidString)/participants/me", token: token, body: encode(request))
  }

  // MARK: Event Questions

  public func questions(eventID: UUID) async throws -> [EventQuestion] {
    try await send(.get, "events/\(eventID.uuidString)/questions", token: token)
  }

  public func createQuestion(eventID: UUID, _ request: CreateEventQuestionRequest) async throws -> EventQuestion {
    try await send(.post, "events/\(eventID.uuidString)/questions", token: token, body: encode(request))
  }

  public func updateQuestion(
    eventID: UUID,
    questionID: UUID,
    _ request: CreateEventQuestionRequest
  ) async throws -> EventQuestion {
    try await send(
      .put,
      "events/\(eventID.uuidString)/questions/\(questionID.uuidString)",
      token: token,
      body: encode(request)
    )
  }

  // MARK: Correct Answers

  /// Throws `AuthAPIError.unexpectedStatus(.notFound, ...)` when no answer exists
  /// or answers are not yet published to the participant.
  public func correctAnswer(eventID: UUID, questionID: UUID) async throws -> EventQuestionCorrectAnswer {
    try await send(
      .get,
      "events/\(eventID.uuidString)/questions/\(questionID.uuidString)/correct_answer",
      token: token
    )
  }

  public func createCorrectAnswer(
    eventID: UUID,
    questionID: UUID,
    _ request: CreateEventQuestionCorrectAnswerRequest
  ) async throws -> EventQuestionCorrectAnswer {
    try await send(
      .post,
      "events/\(eventID.uuidString)/questions/\(questionID.uuidString)/correct_answer",
      token: token,
      body: encode(request)
    )
  }

  public func updateCorrectAnswer(
    eventID: UUID,
    questionID: UUID,
    _ request: CreateEventQuestionCorrectAnswerRequest
  ) async throws -> EventQuestionCorrectAnswer {
    try await send(
      .put,
      "events/\(eventID.uuidString)/questions/\(questionID.uuidString)/correct_answer",
      token: token,
      body: encode(request)
    )
  }

  // MARK: Responses

  /// All submitted responses for a question. Organizer only.
  public func responses(eventID: UUID, questionID: UUID) async throws -> [EventQuestionResponse] {
    try await send(
      .get,
      "events/\(eventID.uuidString)/questions/\(questionID.uuidString)/responses",
      token: token
    )
  }

  /// The authenticated user's own response. Throws `AuthAPIError.unexpectedStatus(.notFound, ...)`
  /// when the user has not submitted a response yet.
  public func myResponse(eventID: UUID, questionID: UUID) async throws -> EventQuestionResponse {
    try await send(
      .get,
      "events/\(eventID.uuidString)/questions/\(questionID.uuidString)/responses/me",
      token: token
    )
  }

  /// The authenticated user's own response, or `nil` when none has been submitted.
  public func myResponseIfExists(eventID: UUID, questionID: UUID) async throws -> EventQuestionResponse? {
    try await optionalIfNotFound { try await myResponse(eventID: eventID, questionID: questionID) }
  }

  /// The correct answer when available to the caller, or `nil` when it is not
  /// set or has not been published to the participant yet.
  public func correctAnswerIfAvailable(eventID: UUID, questionID: UUID) async throws -> EventQuestionCorrectAnswer? {
    try await optionalIfNotFound { try await correctAnswer(eventID: eventID, questionID: questionID) }
  }

  public func submitResponse(
    eventID: UUID,
    questionID: UUID,
    _ request: CreateEventQuestionResponseRequest
  ) async throws -> EventQuestionResponse {
    try await send(
      .post,
      "events/\(eventID.uuidString)/questions/\(questionID.uuidString)/responses",
      token: token,
      body: encode(request)
    )
  }

  public func updateMyResponse(
    eventID: UUID,
    questionID: UUID,
    _ request: CreateEventQuestionResponseRequest
  ) async throws -> EventQuestionResponse {
    try await send(
      .put,
      "events/\(eventID.uuidString)/questions/\(questionID.uuidString)/responses/me",
      token: token,
      body: encode(request)
    )
  }

  // MARK: Wine Master Data

  public func wineStyles() async throws -> [WineStyle] {
    try await send(.get, "wine/styles", token: token)
  }

  public func wineVarieties() async throws -> [WineVariety] {
    try await send(.get, "wine/varieties", token: token)
  }

  public func wineRegionTypes() async throws -> [WineRegionType] {
    try await send(.get, "wine/region_types", token: token)
  }

  public func wineRegions() async throws -> [WineRegion] {
    try await send(.get, "wine/regions", token: token)
  }

  // MARK: Helpers

  /// Runs `operation`, mapping a `404 Not Found` response to `nil`. Used for
  /// endpoints where absence is an expected, non-error outcome (an unsubmitted
  /// response, or a correct answer not yet published).
  private func optionalIfNotFound<T>(
    _ operation: () async throws -> T
  ) async throws -> T? {
    do {
      return try await operation()
    } catch let AuthAPIError.unexpectedStatus(status, _) where status == .notFound {
      return nil
    }
  }
}
