import Foundation
import Testing
@testable import API

/// Live integration tests that mutate server state (create profile, image
/// upload URL, and the full event → question → answer → response lifecycle).
/// These create real records via the production API.
@Suite(.serialized)
struct APIWriteTests {
  var authAPI = AuthAPI()

  private func authenticatedAPI() async throws -> (api: API, token: UserToken) {
    let token = try await authAPI.guestAccount()
    return (API(token: token.token), token)
  }

  /// Returns an authenticated client whose user already has a profile.
  /// Organizing an event requires a profile, so event-related flows start here.
  private func organizerAPI() async throws -> (api: API, token: UserToken) {
    let (api, token) = try await authenticatedAPI()
    _ = try await api.createProfile(CreateUserProfileRequest(name: "Test Organizer", imageID: nil))
    return (api, token)
  }

  private func sampleEventRequest() -> CreateEventRequest {
    let now = Date()
    return CreateEventRequest(
      title: "Integration Test Tasting",
      body: "Created by automated tests.",
      imageID: nil,
      venueName: "Test Cellar",
      venueAddress: PostalAddress(addressLine1: "1 Test St", countryCode: "JP"),
      venueCoordinate: GeoCoordinate(latitude: 35.681, longitude: 139.767),
      registrationPeriod: DateTimePeriod(startsAt: now, endsAt: now.addingTimeInterval(3600)),
      eventPeriod: DateTimePeriod(startsAt: now.addingTimeInterval(7200), endsAt: now.addingTimeInterval(10800)),
      answersPublishedAt: nil,
      capacity: 10,
      entryFee: Money(minorAmount: 0, currencyCode: "JPY"),
      visibility: .private,
      publishedAt: nil,
      canceledAt: nil,
      regionScoreRules: nil
    )
  }

  /// A public, published event whose registration and event periods span now,
  /// so that participants can register and submit responses.
  private func liveEventRequest() -> CreateEventRequest {
    let now = Date()
    return CreateEventRequest(
      title: "Live Tasting",
      body: "Created by automated tests.",
      imageID: nil,
      venueName: "Test Cellar",
      venueAddress: PostalAddress(addressLine1: "1 Test St", countryCode: "JP"),
      venueCoordinate: nil,
      registrationPeriod: DateTimePeriod(startsAt: now.addingTimeInterval(-7200), endsAt: now.addingTimeInterval(7200)),
      eventPeriod: DateTimePeriod(startsAt: now.addingTimeInterval(-3600), endsAt: now.addingTimeInterval(3600)),
      answersPublishedAt: nil,
      capacity: 10,
      entryFee: Money(minorAmount: 0, currencyCode: "JPY"),
      visibility: .public,
      publishedAt: now.addingTimeInterval(-60),
      canceledAt: nil,
      regionScoreRules: nil
    )
  }

  @Test
  func createProfileAndFetchMe() async throws {
    let (api, token) = try await authenticatedAPI()
    let profile = try await api.createProfile(CreateUserProfileRequest(name: "Test User", imageID: nil))
    #expect(profile.userID == token.userID)
    #expect(profile.name == "Test User")

    let me = try await api.me()
    #expect(me.userProfile?.name == "Test User")
  }

  @Test
  func createImageUploadURL() async throws {
    let (api, _) = try await authenticatedAPI()
    let response = try await api.createImageUploadURL()
    #expect(!response.imageID.isEmpty)
    #expect(!response.uploadURL.isEmpty)
  }

  @Test
  func createEvent() async throws {
    let (api, _) = try await organizerAPI()
    let created = try await api.createEvent(sampleEventRequest())
    #expect(created.title == "Integration Test Tasting")
    #expect(created.visibility == .private)
    #expect(created.capacity == 10)
  }

  @Test
  func eventLifecycle() async throws {
    let (api, _) = try await organizerAPI()

    // Create + read.
    let created = try await api.createEvent(sampleEventRequest())
    #expect(created.title == "Integration Test Tasting")

    let fetched = try await api.event(id: created.id)
    #expect(fetched.id == created.id)

    // Update.
    var updateRequest = sampleEventRequest()
    updateRequest.title = "Updated Title"
    let updated = try await api.updateEvent(id: created.id, updateRequest)
    #expect(updated.title == "Updated Title")

    // Question create + update.
    let question = try await api.createQuestion(
      eventID: created.id,
      CreateEventQuestionRequest(questionNumber: 1, imageID: nil, note: "First flight")
    )
    #expect(question.questionNumber == 1)

    let updatedQuestion = try await api.updateQuestion(
      eventID: created.id,
      questionID: question.id,
      CreateEventQuestionRequest(questionNumber: 1, imageID: nil, note: "Updated note")
    )
    #expect(updatedQuestion.id == question.id)

    // Correct answer create + update.
    let answer = try await api.createCorrectAnswer(
      eventID: created.id,
      questionID: question.id,
      CreateEventQuestionCorrectAnswerRequest(
        wineRegionID: nil,
        vintage: 2018,
        alcoholByVolume: 13.0,
        wineVarietyIDs: []
      )
    )
    #expect(answer.eventQuestionID == question.id)

    // Updating the correct answer keeps the same stable id.
    let updatedAnswer = try await api.updateCorrectAnswer(
      eventID: created.id,
      questionID: question.id,
      CreateEventQuestionCorrectAnswerRequest(
        wineRegionID: nil,
        vintage: 2019,
        alcoholByVolume: 12.5,
        wineVarietyIDs: []
      )
    )
    #expect(updatedAnswer.id == answer.id)
    #expect(updatedAnswer.eventQuestionID == question.id)
    #expect(updatedAnswer.vintage == 2019)
  }

  // Responses must be submitted by a registered participant who is NOT the
  // organizer, against a published, currently-active event. So the organizer
  // sets up the event/question and a separate participant responds.
  @Test
  func questionResponses() async throws {
    let (organizer, _) = try await organizerAPI()
    let event = try await organizer.createEvent(liveEventRequest())
    let question = try await organizer.createQuestion(
      eventID: event.id,
      CreateEventQuestionRequest(questionNumber: 1, imageID: nil, note: nil)
    )

    let (participant, participantToken) = try await organizerAPI()
    let registration = try await participant.registerParticipant(eventID: event.id)
    #expect(registration.userID == participantToken.userID)

    let response = try await participant.submitResponse(
      eventID: event.id,
      questionID: question.id,
      CreateEventQuestionResponseRequest(wineRegionID: nil, vintage: 2018, alcoholByVolume: 13.0, note: "Initial guess", wineVarietyIDs: [])
    )
    #expect(response.eventQuestionID == question.id)
    #expect(response.userID == participantToken.userID)

    let updatedResponse = try await participant.updateMyResponse(
      eventID: event.id,
      questionID: question.id,
      CreateEventQuestionResponseRequest(wineRegionID: nil, vintage: 2020, alcoholByVolume: 14.0, note: "Revised guess", wineVarietyIDs: [])
    )
    #expect(updatedResponse.eventQuestionID == question.id)
    #expect(updatedResponse.vintage == 2020)
  }

  @Test
  func registerParticipant() async throws {
    let (api, token) = try await organizerAPI()
    let event = try await api.createEvent(sampleEventRequest())

    let participant = try await api.registerParticipant(eventID: event.id)
    #expect(participant.eventID == event.id)
    #expect(participant.userID == token.userID)
  }
}
