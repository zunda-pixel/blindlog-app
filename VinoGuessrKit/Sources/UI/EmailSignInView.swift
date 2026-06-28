import API
import OSLog
import SwiftUI

private let logger = Logger(subsystem: "com.vinoguessr.app", category: "EmailSignInView")

/// A two-step email one-time-password sign-in: enter an email to receive a
/// code, then enter the code to obtain tokens and add the account.
struct EmailSignInView: View {
  @Environment(AccountStore.self) private var store
  @Environment(\.dismiss) private var dismiss

  @State private var email = ""
  @State private var otp = ""
  /// The challenge returned by `startEmailLogin`; non-nil once a code was sent.
  @State private var challenge: String?
  @State private var isBusy = false
  @State private var errorMessage: String?

  private var codeSent: Bool { challenge != nil }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField("Email", text: $email)
            .textContentType(.emailAddress)
            #if os(iOS)
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
            #endif
            .disableAutocorrection(true)
            .disabled(codeSent)
        }

        if codeSent {
          Section("Verification Code") {
            TextField("One-time code", text: $otp)
              .textContentType(.oneTimeCode)
              #if os(iOS)
              .keyboardType(.numberPad)
              #endif
          }
        }

        if let errorMessage {
          Section {
            Text(errorMessage)
              .foregroundStyle(.red)
              .font(.callout)
          }
        }
      }
      .formStyle(.grouped)
      .disabled(isBusy)
      .navigationTitle("Sign in with Email")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(role: .cancel) { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(codeSent ? "Sign In" : "Send Code") {
            Task {
              if codeSent { await verify() } else { await sendCode() }
            }
          }
          .disabled(isBusy || (codeSent ? otp.isEmpty : email.isEmpty))
        }
      }
    }
  }

  private func sendCode() async {
    errorMessage = nil
    isBusy = true
    defer { isBusy = false }
    do {
      challenge = try await AuthAPI().startEmailLogin(email: email.trimmingCharacters(in: .whitespaces))
    } catch {
      errorMessage = String(describing: error)
      logger.error("Failed to start email login: \(String(describing: error))")
    }
  }

  private func verify() async {
    guard let challenge else { return }
    errorMessage = nil
    isBusy = true
    defer { isBusy = false }
    do {
      let auth = AuthAPI()
      let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
      let request = CreateEmailTokenRequest(
        challenge: challenge,
        email: trimmedEmail,
        otp: otp.trimmingCharacters(in: .whitespaces)
      )
      let token = try await auth.token(email: request)
      let me = try? await API(token: token.token).me()
      try store.addAccount(token: token, displayName: me?.userProfile?.name ?? trimmedEmail)
      dismiss()
    } catch {
      errorMessage = String(describing: error)
      logger.error("Failed to verify email OTP: \(String(describing: error))")
    }
  }
}
