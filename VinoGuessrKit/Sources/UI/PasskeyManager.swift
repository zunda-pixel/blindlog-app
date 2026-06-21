import AuthenticationServices
import API
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Bridges AuthenticationServices passkey (WebAuthn) flows to async/await and
/// the Blindlog API request models.
///
/// Requires the app to be associated with the relying-party domain via the
/// `webcredentials:` Associated Domains entitlement, and that the server's
/// apple-app-site-association lists this app. Otherwise the system rejects the
/// request at runtime.
@MainActor
final class PasskeyManager: NSObject {
  enum PasskeyError: Error { case invalidChallenge, unexpectedCredential }

  private let relyingPartyID = "api.blindlog.me"
  private var continuation: CheckedContinuation<ASAuthorization, any Error>?

  /// Registers a new passkey for the given user, returning the payload to send
  /// to `addPasskey`.
  func register(challenge: String, name: String, userID: UUID) async throws -> AddPasskey {
    let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: relyingPartyID)
    let request = provider.createCredentialRegistrationRequest(
      challenge: try Self.decodeBase64URL(challenge),
      name: name,
      userID: withUnsafeBytes(of: userID.uuid) { Data($0) }
    )
    let authorization = try await perform(request)
    guard let registration = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration else {
      throw PasskeyError.unexpectedCredential
    }
    return AddPasskey(
      id: Self.encodeBase64URL(registration.credentialID),
      rawId: Self.encodeBase64URL(registration.credentialID),
      type: "public-key",
      response: AuthenticatorAttestation(
        clientDataJSON: Self.encodeBase64URL(registration.rawClientDataJSON),
        attestationObject: Self.encodeBase64URL(registration.rawAttestationObject ?? Data())
      )
    )
  }

  /// Performs a passkey assertion, returning the payload to exchange for tokens.
  func assert(challenge: String) async throws -> CreatePasskeyTokenRequest {
    let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: relyingPartyID)
    let request = provider.createCredentialAssertionRequest(challenge: try Self.decodeBase64URL(challenge))
    let authorization = try await perform(request)
    guard let assertion = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion else {
      throw PasskeyError.unexpectedCredential
    }
    return CreatePasskeyTokenRequest(
      challenge: challenge,
      id: Self.encodeBase64URL(assertion.credentialID),
      rawId: Self.encodeBase64URL(assertion.credentialID),
      type: "public-key",
      authenticatorAttachment: "platform",
      response: AuthenticatorAssertion(
        clientDataJSON: Self.encodeBase64URL(assertion.rawClientDataJSON),
        authenticatorData: Self.encodeBase64URL(assertion.rawAuthenticatorData),
        signature: Self.encodeBase64URL(assertion.signature),
        userHandle: Self.encodeBase64URL(assertion.userID)
      )
    )
  }

  private func perform(_ request: ASAuthorizationRequest) async throws -> ASAuthorization {
    try await withCheckedThrowingContinuation { continuation in
      self.continuation = continuation
      let controller = ASAuthorizationController(authorizationRequests: [request])
      controller.delegate = self
      controller.presentationContextProvider = self
      controller.performRequests()
    }
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

extension PasskeyManager: ASAuthorizationControllerDelegate {
  nonisolated func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithAuthorization authorization: ASAuthorization
  ) {
    Task { @MainActor in
      continuation?.resume(returning: authorization)
      continuation = nil
    }
  }

  nonisolated func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithError error: any Error
  ) {
    Task { @MainActor in
      continuation?.resume(throwing: error)
      continuation = nil
    }
  }
}

extension PasskeyManager: ASAuthorizationControllerPresentationContextProviding {
  nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    MainActor.assumeIsolated {
      #if canImport(UIKit)
      let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
      return scenes.flatMap(\.windows).first { $0.isKeyWindow } ?? ASPresentationAnchor()
      #elseif canImport(AppKit)
      return NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first ?? ASPresentationAnchor()
      #else
      return ASPresentationAnchor()
      #endif
    }
  }
}
