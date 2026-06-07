import Foundation
import HTTPTypes
import HTTPTypesFoundation
import AuthenticationServices

struct API {
  var baseURL: URL = URL(string: "https://api.blindlog.me")!
  
  func getMe(token: UserToken) async throws -> User {
    let endpoint = baseURL.appending(path: "me")
    let request = HTTPRequest(
      method: .get,
      url: endpoint,
      headerFields:  [
        .authorization: "Bearer \(token.token)",
        .contentType: "application/json"
      ]
    )
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode(User.self, from: data)
  }
  
  func getNewUser() async throws -> UserToken {
    let endpoint = baseURL.appending(path: "user")
    let request = HTTPRequest(method: .post, url: endpoint)
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode(UserToken.self, from: data)
  }
  
  func getChallenge(token: String? = nil) async throws -> Data {
    let endpoint = baseURL.appending(path: "challenge")
    var request = HTTPRequest(
      method: .post,
      url: endpoint
    )
    
    if let token {
      request.headerFields = [.authorization: "Bearer \(token)"]
    }

    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode(Data.self, from: data)
  }
  
  func addPasskey(
    token: String,
    challenge: Data,
    credentail: ASAuthorizationPlatformPublicKeyCredentialRegistration
  ) async throws {
    let payload = AddPasskeyPayload(credentialRegistration: credentail)
    let body = try JSONEncoder().encode(payload)
    let endpoint = baseURL
      .appending(path: "passkey")
      .appending(queryItems: [
        URLQueryItem(name: "challenge", value: challenge.base64EncodedString())
      ])
    let request = HTTPRequest(
      method: .post,
      url: endpoint,
      headerFields: [
        .authorization: "Bearer \(token)",
        .contentType: "application/json"
      ]
    )
    let (_, response) = try await URLSession.shared.upload(for: request, from: body)
    
    assert(response.status == .ok)
  }
  
  func getToken(
    challenge: Data,
    credential: ASAuthorizationPlatformPublicKeyCredentialAssertion
  ) async throws -> UserToken {
    let payload = PasskeyTokenPayload(challenge: challenge, credential: credential)
    let body = try JSONEncoder().encode(payload)
    let endpoint = baseURL.appending(path: "token/passkey")
    let request = HTTPRequest(
      method: .post,
      url: endpoint,
      headerFields: [.contentType: "application/json"]
    )
    let (data, _) = try await URLSession.shared.upload(for: request, from: body)
    return try JSONDecoder().decode(UserToken.self, from: data)
  }
}

struct AddPasskeyPayload: Encodable {
  var id: Data
  var rawId: Data
  var type: String
  var response: AttestationResponse
  var authenticatorAttachment: String?
  var challenge: Data?
  
  init(credentialRegistration: ASAuthorizationPlatformPublicKeyCredentialRegistration) {
    self.id = credentialRegistration.credentialID
    self.rawId = credentialRegistration.credentialID
    self.type = "public-key"
    self.response = .init(
      clientDataJSON: credentialRegistration.rawClientDataJSON,
      attestationObject: credentialRegistration.rawAttestationObject!
    )
  }
  
  init(challenge: Data, credential: ASAuthorizationPlatformPublicKeyCredentialAssertion) {
    self.id = credential.credentialID
    self.rawId = credential.credentialID
    self.type = "public-key"
    self.response = .init(
      clientDataJSON: credential.rawClientDataJSON,
      authenticatorData: credential.rawAuthenticatorData,
      signature: credential.signature
    )
    self.authenticatorAttachment = credential.attachment.label
    self.challenge = challenge
  }
  
  struct AttestationResponse: Codable {
    var clientDataJSON: Data
    var attestationObject: Data?
    var authenticatorData: Data?
    var signature: Data?
  }
}

struct PasskeyTokenPayload: Encodable {
  var challenge: String
  var id: String
  var rawId: String
  var type: String
  var response: AssertionResponse
  var authenticatorAttachment: String?

  init(challenge: Data, credential: ASAuthorizationPlatformPublicKeyCredentialAssertion) {
    let credentialID = credential.credentialID.base64URLEncodedString
    self.challenge = challenge.base64URLEncodedString
    self.id = credentialID
    self.rawId = credentialID
    self.type = "public-key"
    self.response = .init(
      clientDataJSON: credential.rawClientDataJSON.base64URLEncodedString,
      authenticatorData: credential.rawAuthenticatorData.base64URLEncodedString,
      signature: credential.signature.base64URLEncodedString
    )
    self.authenticatorAttachment = credential.attachment.label
  }

  struct AssertionResponse: Encodable {
    var clientDataJSON: String
    var authenticatorData: String
    var signature: String
  }
}

extension ASAuthorizationPublicKeyCredentialAttachment {
  var label: String {
    switch self {
    case .crossPlatform: "cross-platform"
    case .platform: "platform"
    default : "unknown"
    }
  }
}

private extension Data {
  var base64URLEncodedString: String {
    base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }
}
