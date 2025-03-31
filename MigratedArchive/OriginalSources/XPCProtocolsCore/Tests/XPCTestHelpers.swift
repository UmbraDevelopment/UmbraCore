import Foundation

/// Common test helper extensions
extension Result {
  /// Returns true if the result is a success case
  var isSuccess: Bool {
    switch self {
      case .success: true
      case .failure: false
    }
  }
}
