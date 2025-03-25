import Foundation
import UmbraErrorsCore

/// This file previously contained the ErrorSeverity enum definition.
/// The implementation has been moved to UmbraErrorsCore.
///
/// Instead of using a typealias, code should directly import UmbraErrorsCore
/// and use UmbraErrorsCore.ErrorSeverity.
///
/// Example usage:
/// ```swift
/// import UmbraErrorsCore
///
/// func processError(_ error: Error, severity: UmbraErrorsCore.ErrorSeverity) {
///     // Handle error based on severity
/// }
/// ```
