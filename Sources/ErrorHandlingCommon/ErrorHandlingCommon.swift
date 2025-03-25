import Foundation
import UmbraErrorsCore

// MARK: - UmbraErrorsCore Integration

// This file previously contained a typealias to UmbraErrorsCore.ErrorContext.
// Instead of using a typealias, code should directly import UmbraErrorsCore
// and use UmbraErrorsCore.ErrorContext.

// Extension to bridge between the old and new ErrorContext formats if needed
extension UmbraErrorsCore.ErrorContext {
  /// Initialise with legacy parameters for backward compatibility
  public init(domain: String, code: Int, description: String) {
    self.init(
      ["domain": domain, "code": code],
      source: domain,
      details: description
    )
  }
}
