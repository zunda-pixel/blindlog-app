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
  public var uploadURL: URL
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

public enum EventVisibility: String, Sendable, Codable, Hashable, CaseIterable {
  case `public`
  case unlisted
  case `private`
}

public struct EventParticipant: Sendable, Codable, Hashable, Identifiable {
  public var id: UUID
  public var eventID: UUID
  public var userID: UUID
  public var status: EventParticipantStatus
  public var createdAt: Date
}

public enum EventParticipantStatus: String, Sendable, Codable, Hashable {
  case registered
  case waitlisted
  case canceled
  case attended
}

public struct EventQuestion: Sendable, Codable, Hashable, Identifiable {
  public var id: UUID
  public var eventID: UUID
  public var questionNumber: Int32
  public var imageID: UUID?
  public var note: String?
  public var createdAt: Date
}

public struct EventQuestionCorrectAnswer: Sendable, Codable, Hashable, Identifiable {
  public var id: UUID
  public var eventQuestionID: UUID
  public var wineRegionID: UUID?
  public var vintage: Int32?
  public var alcoholByVolume: Double?
  public var wineVarietyIDs: [UUID]
  public var createdAt: Date
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

public struct WineStyle: Sendable, Codable, Hashable, Identifiable {
  public var id: UUID
  public var code: String
  public var name: String
}

public struct WineVariety: Sendable, Codable, Hashable, Identifiable {
  public var id: UUID
  public var name: String
  public var wineStyleIDs: [UUID]
}

public struct WineRegionType: Sendable, Codable, Hashable, Identifiable {
  public var id: UUID
  public var code: String
  public var name: String
}

public struct WineRegion: Sendable, Codable, Hashable, Identifiable {
  public var id: UUID
  public var parentRegionID: UUID?
  public var wineRegionTypeID: UUID
  public var name: String
}

// MARK: - Shared Value Types

@MemberwiseInit(.public)
public struct DateTimePeriod: Sendable, Codable, Hashable {
  public var startsAt: Date
  public var endsAt: Date
}

@MemberwiseInit(.public)
public struct PostalAddress: Sendable, Codable, Hashable {
  public var addressLine1: String
  public var addressLine2: String? = nil
  public var locality: String? = nil
  public var administrativeArea: String? = nil
  public var postalCode: String? = nil
  public var countryCode: String
}

@MemberwiseInit(.public)
public struct GeoCoordinate: Sendable, Codable, Hashable {
  public var latitude: Double
  public var longitude: Double
}

@MemberwiseInit(.public)
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

@MemberwiseInit(.public)
public struct CreateEventRequest: Sendable, Codable, Hashable {
  public var title: String
  public var body: String
  public var imageID: UUID? = nil
  public var venueName: String
  public var venueAddress: PostalAddress
  public var venueCoordinate: GeoCoordinate? = nil
  public var registrationPeriod: DateTimePeriod? = nil
  public var eventPeriod: DateTimePeriod
  public var answersPublishedAt: Date? = nil
  public var capacity: Int32? = nil
  public var entryFee: Money? = nil
  public var visibility: EventVisibility
  public var publishedAt: Date? = nil
  public var canceledAt: Date? = nil
  public var regionScoreRules: [CreateEventRegionScoreRuleRequest]? = nil
}

@MemberwiseInit(.public)
public struct CreateEventRegionScoreRuleRequest: Sendable, Codable, Hashable {
  public var wineRegionTypeID: UUID
  public var points: Int32
}

@MemberwiseInit(.public)
public struct CreateEventQuestionRequest: Sendable, Codable, Hashable {
  public var questionNumber: Int32
  public var imageID: UUID? = nil
  public var note: String? = nil
}

@MemberwiseInit(.public)
public struct CreateEventQuestionCorrectAnswerRequest: Sendable, Codable, Hashable {
  public var wineRegionID: UUID? = nil
  public var vintage: Int32? = nil
  public var alcoholByVolume: Double? = nil
  public var wineVarietyIDs: [UUID] = []
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
