import Foundation
import UmbraErrorsCore

// MARK: - UmbraErrorsCore Integration

// This file previously contained a typealias to UmbraErrorsCore.ErrorContext.
// Instead of using a typealias, code should directly import UmbraErrorsCore
// and use UmbraErrorsCore.ErrorContext.

// The documentation and implementation have been moved to UmbraErrorsCore
// Original documentation preserved here for reference:
//
// /// A structure that provides detailed context about an error's occurrence.
// ///
// /// `ErrorContext` enriches errors with information about where and how they
// /// occurred, making debugging and error reporting more effective. It captures
// /// both programmatic details (file, line, function) and semantic information
// /// (source, operation, details).
// ///
// /// Example:
// /// ```swift
// /// do {
// ///     try processPayment(amount: 100)
// /// } catch let error {
// ///     throw ErrorContext(
// ///         source: "PaymentProcessor",
// ///         operation: "processPayment",
// ///         details: "Invalid card number",
// ///         underlyingError: error
// ///     )
// /// }
// /// ```
