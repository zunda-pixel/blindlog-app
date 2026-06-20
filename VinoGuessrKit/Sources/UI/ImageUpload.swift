import Foundation
import MultipartKit
import HTTPTypes
import API

enum ImageUploadError: Error {
  case badURL
  case uploadFailed
}

extension API {
  /// Uploads image bytes and returns the registered image's identifier, for use
  /// as an event's or profile's `imageID`.
  ///
  /// The upload URL returned by `createImageUploadURL()` is a Cloudflare Images
  /// direct-upload endpoint, which expects a `multipart/form-data` POST with a
  /// `file` field. The body is serialized with MultipartKit. After the bytes are
  /// uploaded, the image is registered via `createImage(_:)`.
  func uploadImage(_ data: Data) async throws -> UUID {
    let upload = try await createImageUploadURL()
    guard let url = URL(string: upload.uploadURL) else { throw ImageUploadError.badURL }

    let boundary = "Boundary-\(UUID().uuidString)"
    let body = Self.multipartBody(for: data, boundary: boundary)

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    let (_, response) = try await URLSession.shared.upload(for: request, from: body)
    guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
      throw ImageUploadError.uploadFailed
    }

    let image = try await createImage(CreateImageRequest(imageID: upload.imageID))
    return image.id
  }

  /// Serializes a single `file` form-data part containing the raw image bytes.
  private static func multipartBody(for data: Data, boundary: String) -> Data {
    let headerFields: HTTPFields = [
      HTTPField.Name("Content-Disposition")!: "form-data; name=\"file\"; filename=\"image\"",
      HTTPField.Name("Content-Type")!: "application/octet-stream",
    ]
    let part = MultipartPart<[UInt8]>(headerFields: headerFields, body: [UInt8](data))
    let bytes = MultipartSerializer(boundary: boundary).serialize(parts: [part], into: [UInt8].self)
    return Data(bytes)
  }
}
