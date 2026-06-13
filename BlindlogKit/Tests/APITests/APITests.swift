import Testing
@testable import API

@Suite
struct AuthAPITests {
  var api = AuthAPI()
  
  @Test
  func guestAccount() async throws {
    let user = try await api.guestAccount()
    print(user)
  }
}
