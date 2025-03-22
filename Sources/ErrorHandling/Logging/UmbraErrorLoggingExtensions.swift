import ErrorHandlingInterfaces
import Foundation
import UmbraLogging

// MARK: - Logging Extensions

/// Adds logging capabilities to UmbraError
@MainActor
extension ErrorHandlingInterfaces.UmbraError {
  /// Logs this error at the error level
  /// - Parameters:
  ///   - additionalMessage: Optional additional context message
  ///   - file: Source file (autofilled by compiler)
  ///   - function: Function name (autofilled by compiler)
  ///   - line: Line number (autofilled by compiler)
  public func logAsError(
    additionalMessage _: String?=nil,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) async {
    // Create metadata
    var metadata=createBasicMetadata()

    // Add source information if available
    if let source {
      metadata["sourceFile"]=source.file
      metadata["sourceLine"]=String(source.line)
      metadata["sourceFunction"]=source.function
    }

    await ErrorLogger.shared.logError(
      self,
      file: file,
      function: function,
      line: line,
      additionalMetadata: metadata
    )
  }

  /// Logs this error at the warning level
  /// - Parameters:
  ///   - additionalMessage: Optional additional context message
  ///   - file: Source file (autofilled by compiler)
  ///   - function: Function name (autofilled by compiler)
  ///   - line: Line number (autofilled by compiler)
  public func logAsWarning(
    additionalMessage: String?=nil,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) async {
    // Create description for the error with additional context
    let warningMessage=formatErrorDescription(additionalMessage: additionalMessage)

    // Create metadata
    let metadata=createBasicMetadata()

    await ErrorLogger.shared.logWarning(
      warningMessage,
      file: file,
      function: function,
      line: line,
      metadata: metadata
    )
  }

  /// Logs this error at the info level
  /// - Parameters:
  ///   - additionalMessage: Optional additional context message
  ///   - file: Source file (autofilled by compiler)
  ///   - function: Function name (autofilled by compiler)
  ///   - line: Line number (autofilled by compiler)
  public func logAsInfo(
    additionalMessage: String?=nil,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) async {
    // Create description for the error with additional context
    let infoMessage=formatErrorDescription(additionalMessage: additionalMessage)

    // Create metadata
    let metadata=createBasicMetadata()

    await ErrorLogger.shared.logInfo(
      infoMessage,
      file: file,
      function: function,
      line: line,
      metadata: metadata
    )
  }

  /// Logs this error at the debug level
  /// - Parameters:
  ///   - additionalMessage: Optional additional context message
  ///   - file: Source file (autofilled by compiler)
  ///   - function: Function name (autofilled by compiler)
  ///   - line: Line number (autofilled by compiler)
  public func logAsDebug(
    additionalMessage: String?=nil,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) async {
    // Create description for the error with additional context
    let debugMessage=formatErrorDescription(additionalMessage: additionalMessage)

    // Create metadata
    let metadata=createBasicMetadata()

    await ErrorLogger.shared.logDebug(
      debugMessage,
      file: file,
      function: function,
      line: line,
      metadata: metadata
    )
  }

  // MARK: - Private Helpers

  /// Creates the basic metadata for this error
  /// - Returns: LogMetadata with error information
  private func createBasicMetadata() -> LogMetadata {
    var metadata=LogMetadata()
    metadata["domain"]=domain
    metadata["code"]=code
    return metadata
  }

  /// Creates a formatted description with optional additional message
  /// - Parameter additionalMessage: Optional additional context
  /// - Returns: Formatted string
  private func formatErrorDescription(additionalMessage: String?) -> String {
    if let additionalMessage {
      "[\(domain):\(code)] \(additionalMessage): \(errorDescription)"
    } else {
      "[\(domain):\(code)] \(errorDescription)"
    }
  }
}
