import Foundation
import UmbraErrorsCore

// MARK: - Legacy Support

/**
 * This file previously contained local declarations of error types that have been
 * moved to UmbraErrorsCore. The code below provides compatibility extensions and
 * mappings to UmbraErrorsCore types to support existing client code.
 *
 * New code should:
 * 1. Import UmbraErrorsCore directly
 * 2. Use UmbraErrorsCore types like ErrorContext directly
 * 3. Avoid using the compatibility layer in this file
 */

// MARK: - Domain Constants

// Legacy domain constants for backward compatibility
extension UmbraErrorsCore.ErrorDomain {
  /// Security domain
  public static let security="Security"
  /// Crypto domain
  public static let crypto="Crypto"
  /// Application domain
  public static let application="Application"
}

// MARK: - Compatibility Mappings

/// For backward compatibility - use UmbraErrorsCore.ErrorContext in new code
public typealias ErrorContext=UmbraErrorsCore.ErrorContext

/**
 * For backward compatibility - use UmbraErrorsCore.ErrorContext in new code
 *
 * This struct provides a simple mapping to UmbraErrorsCore.ErrorContext.
 * It is only maintained for legacy code support and should not be used in new code.
 */
public struct BaseErrorContext: Equatable, Codable, Hashable, Sendable {
  /// Domain of the error
  public let domain: String
  /// Code of the error
  public let code: Int
  /// Description of the error
  public let description: String

  /// Initialise with domain, code and description
  public init(domain: String, code: Int, description: String) {
    self.domain=domain
    self.code=code
    self.description=description
  }

  /// Map to UmbraErrorsCore.ErrorContext
  public var asUmbraErrorContext: UmbraErrorsCore.ErrorContext {
    UmbraErrorsCore.ErrorContext(
      ["domain": domain, "code": code, "description": description],
      source: domain,
      operation: "unknown",
      details: description
    )
  }

  /// Create from UmbraErrorsCore.ErrorContext
  public static func from(_ context: UmbraErrorsCore.ErrorContext) -> BaseErrorContext {
    let domainValue=context.typedValue(for: "domain", as: String.self) ?? context
      .source ?? "Unknown"
    let codeValue=context.typedValue(for: "code", as: Int.self) ?? 0
    let descriptionValue=context.details ?? "Unknown error"

    return BaseErrorContext(
      domain: domainValue,
      code: codeValue,
      description: descriptionValue
    )
  }
}

// MARK: - Conversion Extensions

/// Extension to enable conversion from UmbraErrorsCore.ErrorContext to BaseErrorContext
extension UmbraErrorsCore.ErrorContext {
  /// Convert to legacy BaseErrorContext
  public var asBaseErrorContext: BaseErrorContext {
    BaseErrorContext.from(self)
  }
}
