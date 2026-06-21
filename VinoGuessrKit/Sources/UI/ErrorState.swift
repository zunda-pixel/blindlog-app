import Observation

/// App-wide error presenter. Inject it into the environment at the top level
/// (`RootView`), display a single alert there, and have any child report errors
/// to it (directly via `report`, or by binding with `@Bindable`).
@MainActor
@Observable
final class ErrorState {
  /// The message currently being presented, if any.
  var message: String?

  /// Drives a top-level `.alert(isPresented:)`. Setting it to `false` clears the
  /// message; this lets a child write `$errorState.isPresenting` via `@Bindable`.
  var isPresenting: Bool {
    get { message != nil }
    set { if !newValue { message = nil } }
  }

  func report(_ message: String) {
    self.message = message
  }

  func report(_ error: any Error) {
    self.message = error.localizedDescription
  }
}
