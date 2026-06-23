import Testing
@testable import API

/// Live, read-only integration tests against the Blindlog API: create a guest
/// account, then exercise authenticated GET endpoints that do not mutate
/// server state.
@Suite(.serialized)
struct APIReadTests {
  var authAPI = AuthAPI()

  private func authenticatedAPI() async throws -> (api: API, token: UserToken) {
    let token = try await authAPI.guestAccount()
    return (API(token: token.token), token)
  }

  @Test
  func guestAccount() async throws {
    let user = try await authAPI.guestAccount()
    #expect(!user.token.isEmpty)
  }

  @Test
  func createAuthenticationChallenge() async throws {
    let challenge = try await authAPI.createAuthenticationChallenge()
    #expect(!challenge.isEmpty)
  }

  @Test
  func me() async throws {
    let (api, token) = try await authenticatedAPI()
    let me = try await api.me()
    #expect(me.userID == token.userID)
  }

  @Test
  func usersByID() async throws {
    let (_, token) = try await authenticatedAPI()
    let users = try await authAPI.users(ids: [token.userID])
    #expect(users.contains { $0.id == token.userID })
  }

  @Test
  func events() async throws {
    let (api, _) = try await authenticatedAPI()
    let events = try await api.events()
    print("events: \(events.count)")
  }

  @Test
  func wineStyles() async throws {
    let (api, _) = try await authenticatedAPI()
    let styles = try await api.wineStyles()
    print("wine styles: \(styles.count)")
  }

  @Test
  func wineVarieties() async throws {
    let (api, _) = try await authenticatedAPI()
    let varieties = try await api.wineVarieties()
    print("wine varieties: \(varieties.count)")
  }

  @Test
  func wineRegionTypes() async throws {
    let (api, _) = try await authenticatedAPI()
    let regionTypes = try await api.wineRegionTypes()
    print("wine region types: \(regionTypes.count)")
  }

  @Test
  func wineRegions() async throws {
    let (api, _) = try await authenticatedAPI()
    let regions = try await api.wineRegions()
    print("wine regions: \(regions.count)")
  }
}
