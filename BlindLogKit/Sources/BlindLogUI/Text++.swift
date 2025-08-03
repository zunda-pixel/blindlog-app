import SwiftUI

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Text {
  init(
    _ key: LocalizedStringKey,
    tableName: String? = nil,
    comment: StaticString? = nil
  ) {
    self.init(
      key,
      tableName: tableName,
      bundle: .module,
      comment: comment
    )
  }
}
