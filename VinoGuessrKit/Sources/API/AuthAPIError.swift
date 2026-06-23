import Foundation
import HTTPTypes

enum AuthAPIError: Error, CustomStringConvertible, LocalizedError {
  case unexpectedStatus(HTTPResponse.Status, body: String)

  var description: String {
    switch self {
    case let .unexpectedStatus(status, body):
      let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmed.isEmpty
        ? "HTTP \(status.code) \(status.reasonPhrase)"
        : "HTTP \(status.code) \(status.reasonPhrase): \(trimmed)"
    }
  }

  var errorDescription: String? { description }
}
