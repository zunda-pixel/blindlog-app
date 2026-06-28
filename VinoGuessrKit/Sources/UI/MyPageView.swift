import SwiftUI
import API

/// The current user's page: a list of the events they organized and the events
/// they're participating in, each navigating to the event detail. Also hosts
/// the account switcher and profile editing.
struct MyPageView: View {
  @Environment(AccountStore.self) private var store
  @Environment(ErrorState.self) private var errorState
  @Environment(Router.self) private var router

  @State private var organized: [Event] = []
  @State private var participating: [Event] = []
  @State private var isLoading = false
  @State private var isEditingProfile = false
  @State private var isPresentingEmailSignIn = false

  var body: some View {
    List {
      Section("Organized") {
        if organized.isEmpty {
          Text("No organized events.")
            .foregroundStyle(.secondary)
        } else {
          ForEach(organized) { event in
            Button {
              router.items.append(.event(event))
            } label: {
              EventRow(event: event)
            }
            .buttonStyle(.plain)
          }
        }
      }

      Section("Participating") {
        if participating.isEmpty {
          Text("No events joined.")
            .foregroundStyle(.secondary)
        } else {
          ForEach(participating) { event in
            Button {
              router.items.append(.event(event))
            } label: {
              EventRow(event: event)
            }
            .buttonStyle(.plain)
          }
        }
      }
    }
    .overlay {
      if isLoading && organized.isEmpty && participating.isEmpty {
        ProgressView()
      }
    }
    .navigationTitle("My Page")
    .toolbar {
      AccountSwitcherToolbar(isPresentingEmailSignIn: $isPresentingEmailSignIn)
      ToolbarItem(placement: .primaryAction) {
        Button("Edit Profile", systemImage: "person.text.rectangle") {
          isEditingProfile = true
        }
      }
    }
    .sheet(isPresented: $isEditingProfile) {
      EditProfileView()
        .environment(store)
        .environment(errorState)
    }
    .sheet(isPresented: $isPresentingEmailSignIn) {
      EmailSignInView()
        .environment(store)
        .environment(errorState)
    }
    .task(id: store.currentAccountID) { await load() }
  }

  private func load() async {
    guard let userID = store.currentAccountID else { return }
    if organized.isEmpty && participating.isEmpty {
      isLoading = true
    }
    defer { isLoading = false }
    do {
      let api = try await store.authenticatedAPI()
      async let organizedResult = api.organizedEvents(userID: userID)
      async let participatingResult = api.participatingEvents(userID: userID)
      organized = try await organizedResult
      participating = try await participatingResult
    } catch {
      errorState.report(error)
    }
  }
}
