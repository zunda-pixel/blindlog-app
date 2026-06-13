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

@Suite
struct APITests {
  var authAPI = AuthAPI()
  
  @Test
  func events() async throws {
    let user = try await authAPI.guestAccount()
    let api = API(token: user.token)
    let events = try await api.events()
    print(events)
  }
}
