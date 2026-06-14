public import Foundation
import MemberwiseInit

// MARK: - Authentication

@MemberwiseInit(.public)
public struct UserToken: Sendable, Codable, Hashable {
  public var userID: UUID
  public var token: String
  public var tokenExpiredDate: Date
  public var refreshToken: String
  public var refreshTokenExpiredDate: Date
}

@MemberwiseInit(.public)
public struct User: Sendable, Codable, Hashable, Identifiable {
  public var id: UUID
  public var email: String? = nil
}

// MARK: - User Profile

@MemberwiseInit(.public)
public struct UserProfile: Sendable, Codable, Hashable, Identifiable {
  public var userID: UUID
  public var name: String
  public var imageURL: URL? = nil
  public var createdAt: Date

  public var id: UUID { userID }
}

@MemberwiseInit(.public)
public struct Me: Sendable, Codable, Hashable {
  public var userID: UUID
  public var userProfile: MeUserProfile? = nil
  public var emails: [Email]
}

@MemberwiseInit(.public)
public struct MeUserProfile: Sendable, Codable, Hashable {
  public var name: String
  public var imageURL: URL? = nil
  public var createdAt: Date
}

@MemberwiseInit(.public)
public struct Email: Sendable, Codable, Hashable {
  public var email: String
  public var createdAt: Date
}

// MARK: - Images

@MemberwiseInit(.public)
public struct Image: Sendable, Codable, Hashable, Identifiable {
  public var id: UUID
  public var imageID: String
  public var createdAt: Date
}

@MemberwiseInit(.public)
public struct CreateImageUploadURLResponse: Sendable, Codable, Hashable {
  public var imageID: String
  public var uploadURL: String
}

// MARK: - Events

public struct Event: Sendable, Codable, Hashable, Identifiable {
  public var id: UUID
  public var organizerUserID: UUID
  public var title: String
  public var body: String
  public var imageID: UUID?
  public var venueName: String
  public var venueAddress: PostalAddress
  public var venueCoordinate: GeoCoordinate?
  public var registrationPeriod: DateTimePeriod?
  public var eventPeriod: DateTimePeriod
  public var answersPublishedAt: Date?
  public var capacity: Int32?
  public var entryFee: Money?
  public var visibility: EventVisibility
  public var publishedAt: Date?
  public var canceledAt: Date?
  public var regionScoreRules: [EventRegionScoreRule]
  public var createdAt: Date
}

public struct EventRegionScoreRule: Sendable, Codable, Hashable {
  public var wineRegionTypeID: UUID
  public var points: Int32
  public var createdAt: Date
}

public enum EventVisibility: String, Sendable, Codable, Hashable {
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

public struct DateTimePeriod: Sendable, Codable, Hashable {
  public var startsAt: Date
  public var endsAt: Date
}

public struct PostalAddress: Sendable, Codable, Hashable {
  public var addressLine1: String
  public var addressLine2: String?
  public var locality: String?
  public var administrativeArea: String?
  public var postalCode: String?
  public var countryCode: String
}

public struct GeoCoordinate: Sendable, Codable, Hashable {
  public var latitude: Double
  public var longitude: Double
}

public struct Money: Sendable, Codable, Hashable {
  public var minorAmount: Int64
  public var currencyCode: String
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

@MemberwiseInit(.public)
public struct CreateUserProfileRequest: Sendable, Codable, Hashable {
  public var name: String
  public var imageID: UUID? = nil
}

@MemberwiseInit(.public)
public struct CreateImageRequest: Sendable, Codable, Hashable {
  public var imageID: String
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

@MemberwiseInit(.public)
public struct AddPasskey: Sendable, Codable, Hashable {
  public var id: String
  public var rawId: String
  public var type: String
  public var response: AuthenticatorAttestation
}

@MemberwiseInit(.public)
public struct AuthenticatorAttestation: Sendable, Codable, Hashable {
  public var clientDataJSON: String
  public var attestationObject: String
}

@MemberwiseInit(.public)
public struct AuthenticatorAssertion: Sendable, Codable, Hashable {
  public var clientDataJSON: String
  public var authenticatorData: String
  public var signature: String
  public var userHandle: String? = nil
  public var attestationObject: String? = nil
}

@MemberwiseInit(.public)
public struct CreatePasskeyTokenRequest: Sendable, Codable, Hashable {
  public var challenge: String
  public var id: String
  public var rawId: String
  public var type: String
  public var authenticatorAttachment: String? = nil
  public var response: AuthenticatorAssertion
}

@MemberwiseInit(.public)
public struct CreateEmailTokenRequest: Sendable, Codable, Hashable {
  public var challenge: String
  public var email: String
  public var otp: String
}

@MemberwiseInit(.public)
public struct ConfirmEmailRequest: Sendable, Codable, Hashable {
  public var email: String
  public var otp: String
}
