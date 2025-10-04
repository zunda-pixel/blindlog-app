import SwiftUI

struct EmailVerifyOneTimeCodeView: View {
  var email: String
  @State var oneTimeCode: String = ""
  
  var body: some View {
    List {
      Text(email)

      VerificationField(type: .six, style: .roundedBorder, value: $oneTimeCode) { result in
        if result.count < 6 {
          return .typing
        } else {
          return .invalid
        }
      }
    }
  }
}

#Preview {
  EmailVerifyOneTimeCodeView(email: "test@example.com")
}
