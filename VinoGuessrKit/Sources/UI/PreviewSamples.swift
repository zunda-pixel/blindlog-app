import API
import Foundation

@MainActor
enum PreviewSamples {
  static let organizerID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
  static let participantID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
  static let eventID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
  static let questionID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
  static let burgundyID = UUID(uuidString: "77777777-7777-7777-7777-777777777777")!
  static let pinotNoirID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!

  static let now = Date(timeIntervalSinceReferenceDate: 800_000_000)

  static var event: Event {
    decode(
      """
      {
        "id": "33333333-3333-3333-3333-333333333333",
        "organizerUserID": "11111111-1111-1111-1111-111111111111",
        "title": "Burgundy Blind Tasting",
        "body": "Compare classic villages and identify region, variety, vintage, and ABV.",
        "imageID": null,
        "imageURL": null,
        "venueName": "Tokyo Wine Studio",
        "venueAddress": {
          "addressLine1": "1-2-3 Ginza",
          "addressLine2": null,
          "locality": "Chuo",
          "administrativeArea": "Tokyo",
          "postalCode": "104-0061",
          "countryCode": "JP"
        },
        "venueCoordinate": { "latitude": 35.6721, "longitude": 139.7648 },
        "registrationPeriod": { "startsAt": 800000000, "endsAt": 800604800 },
        "eventPeriod": { "startsAt": 801209600, "endsAt": 801216800 },
        "answersPublishedAt": null,
        "capacity": 24,
        "entryFee": null,
        "visibility": "public",
        "publishedAt": 800000000,
        "canceledAt": null,
        "regionScoreRules": [
          {
            "wineRegionTypeID": "55555555-5555-5555-5555-555555555555",
            "points": 5,
            "createdAt": 800000000
          }
        ],
        "createdAt": 800000000
      }
      """
    )
  }

  static var revealedEvent: Event {
    var event = event
    event.answersPublishedAt = now
    return event
  }

  static var question: EventQuestion {
    decode(
      """
      {
        "id": "44444444-4444-4444-4444-444444444444",
        "eventID": "33333333-3333-3333-3333-333333333333",
        "questionNumber": 1,
        "imageID": null,
        "imageURL": null,
        "note": "Ruby color, red cherry, earth, and bright acidity.",
        "createdAt": 800000000
      }
      """
    )
  }

  static var participant: EventParticipant {
    decode(
      """
      {
        "id": "cccccccc-cccc-cccc-cccc-cccccccccccc",
        "eventID": "33333333-3333-3333-3333-333333333333",
        "userID": "22222222-2222-2222-2222-222222222222",
        "status": "registered",
        "createdAt": 800000000
      }
      """
    )
  }

  static var catalog: WineCatalog {
    WineCatalog(regions: regions, varieties: varieties, styles: styles)
  }

  static var draft: WineAnswerDraft {
    WineAnswerDraft(
      catalog: catalog,
      catalogState: .loaded,
      selectedRegionID: burgundyID,
      selectedVarietyIDs: [pinotNoirID],
      vintageText: "2020",
      abvText: "13.5"
    )
  }

  private static var regions: [WineRegion] {
    decode(
      """
      [
        {
          "id": "66666666-6666-6666-6666-666666666666",
          "parentRegionID": null,
          "wineRegionTypeID": "55555555-5555-5555-5555-555555555555",
          "name": "France"
        },
        {
          "id": "77777777-7777-7777-7777-777777777777",
          "parentRegionID": "66666666-6666-6666-6666-666666666666",
          "wineRegionTypeID": "55555555-5555-5555-5555-555555555555",
          "name": "Burgundy"
        }
      ]
      """
    )
  }

  private static var varieties: [WineVariety] {
    decode(
      """
      [
        {
          "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
          "name": "Pinot Noir",
          "wineStyleIDs": ["88888888-8888-8888-8888-888888888888"]
        },
        {
          "id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
          "name": "Chardonnay",
          "wineStyleIDs": ["99999999-9999-9999-9999-999999999999"]
        }
      ]
      """
    )
  }

  private static var styles: [WineStyle] {
    decode(
      """
      [
        {
          "id": "88888888-8888-8888-8888-888888888888",
          "code": "red",
          "name": "Red"
        },
        {
          "id": "99999999-9999-9999-9999-999999999999",
          "code": "white",
          "name": "White"
        }
      ]
      """
    )
  }

  private static func decode<T: Decodable>(_ json: String) -> T {
    let data = Data(json.utf8)
    return try! JSONDecoder().decode(T.self, from: data)
  }
}
