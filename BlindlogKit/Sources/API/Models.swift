import Foundation

// MARK: - Authentication

struct UserToken: Sendable, Codable, Hashable {
  var userID: UUID
  var token: String
  var tokenExpiredDate: Date
  var refreshToken: String
  var refreshTokenExpiredDate: Date
}

struct User: Sendable, Codable, Hashable, Identifiable {
  var id: UUID
  var email: String?
}

// MARK: - User Profile

struct UserProfile: Sendable, Codable, Hashable, Identifiable {
  var id: UUID
  var userID: UUID
  var name: String
  var imageURL: URL?
  var createdAt: Date
}

struct Me: Sendable, Codable, Hashable {
  var userID: UUID
  var userProfile: MeUserProfile?
  var emails: [Email]
}

struct MeUserProfile: Sendable, Codable, Hashable {
  var name: String
  var imageURL: URL?
  var createdAt: Date
}

struct Email: Sendable, Codable, Hashable {
  var email: String
  var createdAt: Date
}

// MARK: - Images

struct Image: Sendable, Codable, Hashable, Identifiable {
  var id: UUID
  var imageID: String
  var createdAt: Date
}

struct CreateImageUploadURLResponse: Sendable, Codable, Hashable {
  var imageID: String
  var uploadURL: String
}

// MARK: - Events

struct Event: Sendable, Codable, Hashable, Identifiable {
  var id: UUID
  var organizerUserID: UUID
  var title: String
  var body: String
  var imageID: UUID?
  var venueName: String
  var venueAddress: PostalAddress
  var venueCoordinate: GeoCoordinate?
  var registrationPeriod: DateTimePeriod?
  var eventPeriod: DateTimePeriod
  var answersPublishedAt: Date?
  var capacity: Int32?
  var entryFee: Money?
  var visibility: EventVisibility
  var publishedAt: Date?
  var canceledAt: Date?
  var regionScoreRules: [EventRegionScoreRule]
  var createdAt: Date
}

struct EventRegionScoreRule: Sendable, Codable, Hashable {
  var wineRegionTypeID: UUID
  var points: Int32
  var createdAt: Date
}

enum EventVisibility: String, Sendable, Codable, Hashable {
  case `public`
  case unlisted
  case `private`
}

struct EventParticipant: Sendable, Codable, Hashable, Identifiable {
  var id: UUID
  var eventID: UUID
  var userID: UUID
  var status: EventParticipantStatus
  var createdAt: Date
}

enum EventParticipantStatus: String, Sendable, Codable, Hashable {
  case registered
  case waitlisted
  case canceled
  case attended
}

struct EventQuestion: Sendable, Codable, Hashable, Identifiable {
  var id: UUID
  var eventID: UUID
  var questionNumber: Int32
  var imageID: UUID?
  var note: String?
  var createdAt: Date
}

struct EventQuestionCorrectAnswer: Sendable, Codable, Hashable, Identifiable {
  var id: UUID
  var eventQuestionID: UUID
  var wineRegionID: UUID?
  var vintage: Int32?
  var alcoholByVolume: Double?
  var wineVarietyIDs: [UUID]
  var createdAt: Date
}

struct EventQuestionResponse: Sendable, Codable, Hashable, Identifiable {
  var id: UUID
  var eventQuestionID: UUID
  var userID: UUID
  var wineRegionID: UUID?
  var vintage: Int32?
  var alcoholByVolume: Double?
  var note: String?
  var wineVarietyIDs: [UUID]
  var submittedAt: Date
}

// MARK: - Wine Master Data

struct WineStyle: Sendable, Codable, Hashable, Identifiable {
  var id: UUID
  var code: String
  var name: String
}

struct WineVariety: Sendable, Codable, Hashable, Identifiable {
  var id: UUID
  var name: String
  var wineStyleIDs: [UUID]
}

struct WineRegionType: Sendable, Codable, Hashable, Identifiable {
  var id: UUID
  var code: String
  var name: String
}

struct WineRegion: Sendable, Codable, Hashable, Identifiable {
  var id: UUID
  var parentRegionID: UUID?
  var wineRegionTypeID: UUID
  var name: String
}

// MARK: - Shared Value Types

struct DateTimePeriod: Sendable, Codable, Hashable {
  var startsAt: Date
  var endsAt: Date
}

struct PostalAddress: Sendable, Codable, Hashable {
  var addressLine1: String
  var addressLine2: String?
  var locality: String?
  var administrativeArea: String?
  var postalCode: String?
  var countryCode: String
}

struct GeoCoordinate: Sendable, Codable, Hashable {
  var latitude: Double
  var longitude: Double
}

struct Money: Sendable, Codable, Hashable {
  var minorAmount: Int64
  var currencyCode: String
}

// MARK: - Apple App Site Association

struct AppleAppSiteAssociation: Sendable, Codable, Hashable {
  var webcredentials: WebCredentials?
  var appclips: AppClips?
  var applinks: AppLinks?
}

struct WebCredentials: Sendable, Codable, Hashable {
  var apps: [String]?
}

struct AppClips: Sendable, Codable, Hashable {
  var apps: [String]?
}

struct AppLinks: Sendable, Codable, Hashable {
  var details: [AppLinkDetail]?
}

struct AppLinkDetail: Sendable, Codable, Hashable {
  var appIDs: [String]?
  var components: [String]?
}

// MARK: - Request Payloads

struct RefreshTokenRequest: Sendable, Codable, Hashable {
  var refreshToken: String
}

struct CreateUserProfileRequest: Sendable, Codable, Hashable {
  var name: String
  var imageID: UUID?
}

struct CreateImageRequest: Sendable, Codable, Hashable {
  var imageID: String
}

struct CreateEventRequest: Sendable, Codable, Hashable {
  var title: String
  var body: String
  var imageID: UUID?
  var venueName: String
  var venueAddress: PostalAddress
  var venueCoordinate: GeoCoordinate?
  var registrationPeriod: DateTimePeriod?
  var eventPeriod: DateTimePeriod
  var answersPublishedAt: Date?
  var capacity: Int32?
  var entryFee: Money?
  var visibility: EventVisibility
  var publishedAt: Date?
  var canceledAt: Date?
  var regionScoreRules: [CreateEventRegionScoreRuleRequest]?
}

struct CreateEventRegionScoreRuleRequest: Sendable, Codable, Hashable {
  var wineRegionTypeID: UUID
  var points: Int32
}

struct CreateEventQuestionRequest: Sendable, Codable, Hashable {
  var questionNumber: Int32
  var imageID: UUID?
  var note: String?
}

struct CreateEventQuestionCorrectAnswerRequest: Sendable, Codable, Hashable {
  var wineRegionID: UUID?
  var vintage: Int32?
  var alcoholByVolume: Double?
  var wineVarietyIDs: [UUID]
}

struct CreateEventQuestionResponseRequest: Sendable, Codable, Hashable {
  var wineRegionID: UUID?
  var vintage: Int32?
  var alcoholByVolume: Double?
  var note: String?
  var wineVarietyIDs: [UUID]
}

// MARK: - Passkey / Email Authentication Payloads

struct AddPasskey: Sendable, Codable, Hashable {
  var id: String
  var rawId: String
  var type: String
  var response: AuthenticatorAttestation
}

struct AuthenticatorAttestation: Sendable, Codable, Hashable {
  var clientDataJSON: String
  var attestationObject: String
}

struct AuthenticatorAssertion: Sendable, Codable, Hashable {
  var clientDataJSON: String
  var authenticatorData: String
  var signature: String
  var userHandle: String?
  var attestationObject: String?
}

struct CreatePasskeyTokenRequest: Sendable, Codable, Hashable {
  var challenge: String
  var id: String
  var rawId: String
  var type: String
  var authenticatorAttachment: String?
  var response: AuthenticatorAssertion
}

struct CreateEmailTokenRequest: Sendable, Codable, Hashable {
  var challenge: String
  var email: String
  var otp: String
}

struct ConfirmEmailRequest: Sendable, Codable, Hashable {
  var email: String
  var otp: String
}
