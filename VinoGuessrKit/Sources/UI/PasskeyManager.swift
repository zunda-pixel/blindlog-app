import SwiftUI
import AuthenticationServices
import API

/// Builds passkey (WebAuthn) requests and converts AuthenticationServices
/// results into the Blindlog API request models.
///
/// The request is performed by SwiftUI's `@Environment(\.authorizationController)`
/// (`AuthorizationController`), which presents the system UI itself — no
/// delegate, presentation anchor, or `NSObject` bridging required.
///
/// Requires the app to be associated with the relying-party domain via the
/// `webcredentials:` Associated Domains entitlement, and the server's
/// apple-app-site-association must list this app, or the system rejects the
/// request at runtime.
enum Passkey {
  static let relyingPartyID = "api.blindlog.me"

  enum PasskeyError: Error { case invalidChallenge, unexpectedResult }

  static func registrationRequest(challenge: String, name: String, userID: UUID) throws -> ASAuthorizationRequest {
    let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: relyingPartyID)
    return provider.createCredentialRegistrationRequest(
      challenge: try decodeBase64URL(challenge),
      name: name,
      userID: withUnsafeBytes(of: userID.uuid) { Data($0) }
    )
  }

  static func assertionRequest(challenge: String) throws -> ASAuthorizationRequest {
    let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: relyingPartyID)
    return provider.createCredentialAssertionRequest(challenge: try decodeBase64URL(challenge))
  }

  static func addPasskey(from result: ASAuthorizationResult, challenge: String) throws -> AddPasskey {
    guard case let .passkeyRegistration(registration) = result else {
      throw PasskeyError.unexpectedResult
    }
    return AddPasskey(
      challenge: challenge,
      id: encodeBase64URL(registration.credentialID),
      rawId: encodeBase64URL(registration.credentialID),
      type: "public-key",
      response: AuthenticatorAttestation(
        clientDataJSON: encodeBase64URL(registration.rawClientDataJSON),
        attestationObject: encodeBase64URL(registration.rawAttestationObject ?? Data())
      )
    )
  }

  static func tokenRequest(from result: ASAuthorizationResult, challenge: String) throws -> CreatePasskeyTokenRequest {
    guard case let .passkeyAssertion(assertion) = result else {
      throw PasskeyError.unexpectedResult
    }
    return CreatePasskeyTokenRequest(
      challenge: challenge,
      id: encodeBase64URL(assertion.credentialID),
      rawId: encodeBase64URL(assertion.credentialID),
      type: "public-key",
      authenticatorAttachment: "platform",
      response: AuthenticatorAssertion(
        clientDataJSON: encodeBase64URL(assertion.rawClientDataJSON),
        authenticatorData: encodeBase64URL(assertion.rawAuthenticatorData),
        signature: encodeBase64URL(assertion.signature),
        userHandle: encodeBase64URL(assertion.userID)
      )
    )
  }

  // MARK: Base64URL

  static func decodeBase64URL(_ string: String) throws -> Data {
    var s = string.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
    while s.count % 4 != 0 { s += "=" }
    guard let data = Data(base64Encoded: s) else { throw PasskeyError.invalidChallenge }
    return data
  }

  static func encodeBase64URL(_ data: Data) -> String {
    data.base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }
}
