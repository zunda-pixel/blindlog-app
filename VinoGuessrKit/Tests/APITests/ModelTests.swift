import Foundation
import Testing
import Currency
@testable import API

/// Offline tests that verify the model `Codable` mappings against the JSON
/// shapes described by the OpenAPI specification. These do not touch the
/// network, so they are deterministic and safe to run anywhere.
@Suite
struct ModelDecodingTests {

  private func decode<T: Decodable>(_ type: T.Type, from json: String) throws -> T {
    try JSONDecoder().decode(T.self, from: Data(json.utf8))
  }

  @Test
  func decodesUserToken() throws {
    let json = """
    {
      "userID": "1B2C3D4E-5F60-4A1B-8C2D-3E4F5A6B7C8D",
      "token": "access-token",
      "tokenExpiredDate": 100,
      "refreshToken": "refresh-token",
      "refreshTokenExpiredDate": 200
    }
    """
    let token = try decode(UserToken.self, from: json)
    #expect(token.token == "access-token")
    #expect(token.refreshToken == "refresh-token")
  }

  @Test
  func decodesFullEvent() throws {
    let json = """
    {
      "id": "1B2C3D4E-5F60-4A1B-8C2D-3E4F5A6B7C8D",
      "organizerUserID": "2B2C3D4E-5F60-4A1B-8C2D-3E4F5A6B7C8D",
      "title": "Blind Tasting",
      "body": "Bring your palate.",
      "imageID": "3B2C3D4E-5F60-4A1B-8C2D-3E4F5A6B7C8D",
      "venueName": "Cellar",
      "venueAddress": { "addressLine1": "1 Main St", "countryCode": "JP" },
      "venueCoordinate": { "latitude": 35.0, "longitude": 139.0 },
      "registrationPeriod": { "startsAt": 1, "endsAt": 2 },
      "eventPeriod": { "startsAt": 3, "endsAt": 4 },
      "answersPublishedAt": 5,
      "capacity": 20,
      "entryFee": { "minorAmount": 1000, "currencyCode": "JPY" },
      "visibility": "public",
      "publishedAt": 6,
      "canceledAt": null,
      "regionScoreRules": [
        { "wineRegionTypeID": "4B2C3D4E-5F60-4A1B-8C2D-3E4F5A6B7C8D", "points": 3, "createdAt": 7 }
      ],
      "createdAt": 8
    }
    """
    let event = try decode(Event.self, from: json)
    #expect(event.title == "Blind Tasting")
    #expect(event.visibility == .public)
    #expect(event.capacity == 20)
    #expect(event.entryFee?.minorAmount == 1000)
    #expect(event.canceledAt == nil)
    #expect(event.regionScoreRules.count == 1)
    #expect(event.regionScoreRules.first?.points == 3)
  }

  @Test
  func decodesEventWithOnlyRequiredFields() throws {
    let json = """
    {
      "id": "1B2C3D4E-5F60-4A1B-8C2D-3E4F5A6B7C8D",
      "organizerUserID": "2B2C3D4E-5F60-4A1B-8C2D-3E4F5A6B7C8D",
      "title": "Minimal",
      "body": "",
      "venueName": "Somewhere",
      "venueAddress": { "addressLine1": "1 Main St", "countryCode": "JP" },
      "eventPeriod": { "startsAt": 3, "endsAt": 4 },
      "visibility": "private",
      "regionScoreRules": [],
      "createdAt": 8
    }
    """
    let event = try decode(Event.self, from: json)
    #expect(event.visibility == .private)
    #expect(event.imageID == nil)
    #expect(event.venueCoordinate == nil)
    #expect(event.capacity == nil)
    #expect(event.regionScoreRules.isEmpty)
  }

  @Test
  func decodesMeWithNullProfile() throws {
    let json = """
    {
      "userID": "1B2C3D4E-5F60-4A1B-8C2D-3E4F5A6B7C8D",
      "userProfile": null,
      "emails": [ { "email": "a@example.com", "createdAt": 1 } ]
    }
    """
    let me = try decode(Me.self, from: json)
    #expect(me.userProfile == nil)
    #expect(me.emails.count == 1)
    #expect(me.emails.first?.email == "a@example.com")
  }

  @Test
  func decodesMeWithProfile() throws {
    let json = """
    {
      "userID": "1B2C3D4E-5F60-4A1B-8C2D-3E4F5A6B7C8D",
      "userProfile": { "name": "Hiroki", "imageURL": "https://example.com/a.png", "createdAt": 1 },
      "emails": []
    }
    """
    let me = try decode(Me.self, from: json)
    #expect(me.userProfile?.name == "Hiroki")
    #expect(me.userProfile?.imageURL == URL(string: "https://example.com/a.png"))
  }

  @Test
  func decodesEventQuestionResponse() throws {
    let json = """
    {
      "id": "1B2C3D4E-5F60-4A1B-8C2D-3E4F5A6B7C8D",
      "eventQuestionID": "2B2C3D4E-5F60-4A1B-8C2D-3E4F5A6B7C8D",
      "userID": "3B2C3D4E-5F60-4A1B-8C2D-3E4F5A6B7C8D",
      "vintage": 2018,
      "alcoholByVolume": 13.5,
      "wineVarietyIDs": ["4B2C3D4E-5F60-4A1B-8C2D-3E4F5A6B7C8D"],
      "submittedAt": 99
    }
    """
    let response = try decode(EventQuestionResponse.self, from: json)
    #expect(response.vintage == 2018)
    #expect(response.alcoholByVolume == 13.5)
    #expect(response.wineRegionID == nil)
    #expect(response.note == nil)
    #expect(response.wineVarietyIDs.count == 1)
  }

  @Test
  func decodesWineRegionWithoutParent() throws {
    let json = """
    {
      "id": "1B2C3D4E-5F60-4A1B-8C2D-3E4F5A6B7C8D",
      "wineRegionTypeID": "2B2C3D4E-5F60-4A1B-8C2D-3E4F5A6B7C8D",
      "name": "Bordeaux"
    }
    """
    let region = try decode(WineRegion.self, from: json)
    #expect(region.parentRegionID == nil)
    #expect(region.name == "Bordeaux")
  }

  @Test
  func decodesParticipantStatus() throws {
    let json = """
    {
      "id": "1B2C3D4E-5F60-4A1B-8C2D-3E4F5A6B7C8D",
      "eventID": "2B2C3D4E-5F60-4A1B-8C2D-3E4F5A6B7C8D",
      "userID": "3B2C3D4E-5F60-4A1B-8C2D-3E4F5A6B7C8D",
      "status": "waitlisted",
      "createdAt": 1
    }
    """
    let participant = try decode(EventParticipant.self, from: json)
    #expect(participant.status == .waitlisted)
  }
}

/// Verifies request payloads encode with the property names the API expects
/// and survive an encode/decode round-trip unchanged.
@Suite
struct RequestEncodingTests {

  @Test
  func encodesVisibilityRawValues() {
    #expect(EventVisibility.public.rawValue == "public")
    #expect(EventVisibility.unlisted.rawValue == "unlisted")
    #expect(EventVisibility.private.rawValue == "private")
  }

  @Test
  func roundTripsCreateEventRequest() throws {
    let request = CreateEventRequest(
      title: "Tasting",
      body: "Notes",
      imageID: nil,
      venueName: "Cellar",
      venueAddress: PostalAddress(addressLine1: "1 Main St", countryCode: "JP"),
      venueCoordinate: GeoCoordinate(latitude: 35, longitude: 139),
      registrationPeriod: nil,
      eventPeriod: DateTimePeriod(startsAt: Date(timeIntervalSince1970: 1), endsAt: Date(timeIntervalSince1970: 2)),
      answersPublishedAt: nil,
      capacity: 10,
      entryFee: Money(minorAmount: 500, currencyCode: .jpy),
      visibility: .unlisted,
      publishedAt: nil,
      canceledAt: nil,
      regionScoreRules: [CreateEventRegionScoreRuleRequest(wineRegionTypeID: UUID(), points: 2)]
    )
    let data = try JSONEncoder().encode(request)
    let decoded = try JSONDecoder().decode(CreateEventRequest.self, from: data)
    #expect(decoded == request)
  }

  @Test
  func encodesCreateEventQuestionResponseRequestKeys() throws {
    let request = CreateEventQuestionResponseRequest(
      wineRegionID: nil,
      vintage: 2020,
      alcoholByVolume: 12.0,
      note: "Crisp",
      wineVarietyIDs: [UUID()]
    )
    let data = try JSONEncoder().encode(request)
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    #expect(object?["vintage"] as? Int == 2020)
    #expect(object?["note"] as? String == "Crisp")
    #expect((object?["wineVarietyIDs"] as? [Any])?.count == 1)
  }
}
