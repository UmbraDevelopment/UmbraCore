import BackupInterfaces
import Foundation
import LoggingTypes

/**
 * Maps errors to log contexts with appropriate privacy classifications.
 *
 * This class follows the Alpha Dot Five architecture principles for privacy-aware
 * logging, ensuring sensitive error details are properly classified.
 */
public struct ErrorLogContextMapper {
  /// Creates a new error log context mapper
  public init() {}

  /**
   * Creates a log context from an error with appropriate privacy classifications.
   *
   * - Parameters:
   *   - error: The error to map
   *   - baseContext: Optional base context to enhance
   * - Returns: A log context with error details
   */
  public func createContext(
    from error: Error,
    baseContext: BackupLogContext?=nil
  ) -> BackupLogContext {
    // Start with the base context or create a new one
    let context=baseContext ?? BackupLogContext(
      source: "BackupServices.ErrorMapper"
    )

    // Add error type with public classification
    let errorContext=context.withPublic(
      key: "errorType",
      value: String(describing: type(of: error))
    )

    // Add error code if available
    if let nsError=error as? NSError {
      return errorContext
        .withPublic(key: "errorCode", value: String(nsError.code))
        .withPublic(key: "errorDomain", value: nsError.domain)
        .withPrivate(key: "errorDescription", value: nsError.localizedDescription)
    }

    // For other errors, just add the description as private
    return errorContext.withPrivate(
      key: "errorDescription",
      value: error.localizedDescription
    )
  }
}
