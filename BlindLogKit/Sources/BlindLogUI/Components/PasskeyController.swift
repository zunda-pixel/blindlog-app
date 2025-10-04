import AuthenticationServices

final class PasskeyController: NSObject, ASAuthorizationControllerPresentationContextProviding {
  var continuation: CheckedContinuation<ASAuthorization, any Error>?
  let anchor: ASPresentationAnchor
  
  init(anchor: ASPresentationAnchor) {
    self.anchor = anchor
  }
  
  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    self.anchor
  }
  
  func addPasskey(
    domain: String,
    userId: UUID,
    userName: String,
    challenge: Data,
    preferImmediatelyAvailableCredentials: Bool,
  ) async throws -> ASAuthorization {
    let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)
    // Fetch the challenge from the server. The challenge needs to be unique for each request.
    
    //    let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challenge)
    let assertionRequest = publicKeyCredentialProvider.createCredentialRegistrationRequest(
      challenge: challenge,
      name: userName,
      userID: Data(userId.uuidString.utf8)
    )
    
    // Also allow the user to use a saved password, if they have one.
    let passwordCredentialProvider = ASAuthorizationPasswordProvider()
    let passwordRequest = passwordCredentialProvider.createRequest()
    
    // Pass in any mix of supported sign-in request types.
    let authController = ASAuthorizationController(authorizationRequests: [ assertionRequest, passwordRequest ] )
    authController.delegate = self
    authController.presentationContextProvider = self
    
    if preferImmediatelyAvailableCredentials {
      // If credentials are available, presents a modal sign-in sheet.
      // If there are no locally saved credentials, no UI appears and
      // the system passes ASAuthorizationError.Code.canceled to call
      // `AccountManager.authorizationController(controller:didCompleteWithError:)`.
      authController.performRequests(options: .preferImmediatelyAvailableCredentials)
    } else {
      // If credentials are available, presents a modal sign-in sheet.
      // If there are no locally saved credentials, the system presents a QR code to allow signing in with a
      // passkey from a nearby device.
      authController.performRequests()
    }
    
    return try await withCheckedThrowingContinuation { continuation in
      self.continuation = continuation
    }
  }
  
  func signIn(
    domain: String,
    challenge: Data,
    preferImmediatelyAvailableCredentials: Bool,
  ) async throws -> ASAuthorization {
    let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)
    
    let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challenge)
    
    // Also allow the user to use a saved password, if they have one.
    let passwordCredentialProvider = ASAuthorizationPasswordProvider()
    let passwordRequest = passwordCredentialProvider.createRequest()
    
    // Pass in any mix of supported sign-in request types.
    let authController = ASAuthorizationController(authorizationRequests: [ assertionRequest, passwordRequest ] )
    authController.delegate = self
    authController.presentationContextProvider = self
    
    if preferImmediatelyAvailableCredentials {
      // If credentials are available, presents a modal sign-in sheet.
      // If there are no locally saved credentials, no UI appears and
      // the system passes ASAuthorizationError.Code.canceled to call
      // `AccountManager.authorizationController(controller:didCompleteWithError:)`.
      authController.performRequests(options: .preferImmediatelyAvailableCredentials)
    } else {
      // If credentials are available, presents a modal sign-in sheet.
      // If there are no locally saved credentials, the system presents a QR code to allow signing in with a
      // passkey from a nearby device.
      authController.performRequests()
    }
    
    return try await withCheckedThrowingContinuation { continuation in
      self.continuation = continuation
    }
  }
}

extension PasskeyController: ASAuthorizationControllerDelegate {
  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    continuation?.resume(returning: authorization)
  }
  
  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: any Error) {
    continuation?.resume(throwing: error)
  }
}
