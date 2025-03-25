import Foundation
import UmbraErrorsCore

// Use the canonical ErrorContext from UmbraErrorsCore instead of defining our own
typealias ErrorContext = UmbraErrorsCore.ErrorContext

// Extension to bridge between the old and new ErrorContext formats if needed
extension UmbraErrorsCore.ErrorContext {
    /// Initialize with legacy parameters for backward compatibility
    public init(domain: String, code: Int, description: String) {
        self.init(
            ["domain": domain, "code": code],
            source: domain,
            details: description
        )
    }
}
