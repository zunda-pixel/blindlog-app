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

  public func addPasskey(_ passkey: AddPasskey, challenge: String) async throws {
    try await send(
      .post,
      "passkey",
      query: [URLQueryItem(name: "challenge", value: challenge)],
      token: token,
      body: encode(passkey)
    )
  }

  // MARK: Users

  func userProfile(userID: UUID) async throws -> UserProfile {
    try await send(.get, "user_profile/\(userID.uuidString)", token: token)
  }

  func organizedEvents(userID: UUID) async throws -> [Event] {
    try await send(.get, "users/\(userID.uuidString)/organized_events", token: token)
  }

  func participatingEvents(userID: UUID) async throws -> [Event] {
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

  func updateEvent(id: UUID, _ request: CreateEventRequest) async throws -> Event {
    try await send(.put, "events/\(id.uuidString)", token: token, body: encode(request))
  }

  func registerParticipant(eventID: UUID) async throws -> EventParticipant {
    try await send(.post, "events/\(eventID.uuidString)/participants", token: token)
  }

  // MARK: Event Questions

  public func createQuestion(eventID: UUID, _ request: CreateEventQuestionRequest) async throws -> EventQuestion {
    try await send(.post, "events/\(eventID.uuidString)/questions", token: token, body: encode(request))
  }

  func updateQuestion(
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

  func updateCorrectAnswer(
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

  func submitResponse(
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

  func updateMyResponse(
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

  func wineStyles() async throws -> [WineStyle] {
    try await send(.get, "wine/styles", token: token)
  }

  public func wineVarieties() async throws -> [WineVariety] {
    try await send(.get, "wine/varieties", token: token)
  }

  func wineRegionTypes() async throws -> [WineRegionType] {
    try await send(.get, "wine/region_types", token: token)
  }

  public func wineRegions() async throws -> [WineRegion] {
    try await send(.get, "wine/regions", token: token)
  }
}
