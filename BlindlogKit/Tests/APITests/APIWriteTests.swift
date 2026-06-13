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
  func eventLifecycle() async throws {
    let (api, _) = try await authenticatedAPI()

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

    // Submit + update the authenticated user's response.
    let response = try await api.submitResponse(
      eventID: created.id,
      questionID: question.id,
      CreateEventQuestionResponseRequest(
        wineRegionID: nil,
        vintage: 2018,
        alcoholByVolume: 13.0,
        note: "Initial guess",
        wineVarietyIDs: []
      )
    )
    #expect(response.eventQuestionID == question.id)

    let updatedResponse = try await api.updateMyResponse(
      eventID: created.id,
      questionID: question.id,
      CreateEventQuestionResponseRequest(
        wineRegionID: nil,
        vintage: 2020,
        alcoholByVolume: 14.0,
        note: "Revised guess",
        wineVarietyIDs: []
      )
    )
    #expect(updatedResponse.eventQuestionID == question.id)
  }

  @Test
  func registerParticipant() async throws {
    let (api, token) = try await authenticatedAPI()
    let event = try await api.createEvent(sampleEventRequest())

    let participant = try await api.registerParticipant(eventID: event.id)
    #expect(participant.eventID == event.id)
    #expect(participant.userID == token.userID)
  }
}
