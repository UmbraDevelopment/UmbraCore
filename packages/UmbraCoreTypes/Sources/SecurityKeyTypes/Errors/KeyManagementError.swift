import Foundation
import LoggingTypes

/**
 Error type for key management operations.

 This error type follows the Alpha Dot Five architecture pattern for domain-specific errors
 with detailed information and proper Sendable conformance for actor isolation.
 */
public enum KeyManagementError: Error, Equatable, Sendable {
  /// Key not found with the specified identifier
  case keyNotFound(identifier: String)

  /// Key creation failed
  case keyCreationFailed(reason: String)

  /// Key storage failed
  case keyStorageFailed(reason: String)

  /// Invalid input provided to operation
  case invalidInput(details: String)

  /// Key rotation failed
  case keyRotationFailed(reason: String)

  /// Key verification failed
  case keyVerificationFailed(reason: String)

  /// Key export failed
  case keyExportFailed(reason: String)

  /// Key import failed
  case keyImportFailed(reason: String)

  /// Creates a human-readable description of the error
  public var localizedDescription: String {
    switch self {
      case let .keyNotFound(identifier):
        "Key not found with identifier: \(identifier)"
      case let .keyCreationFailed(reason):
        "Failed to create key: \(reason)"
      case let .keyStorageFailed(reason):
        "Failed to store key: \(reason)"
      case let .invalidInput(details):
        "Invalid input: \(details)"
      case let .keyRotationFailed(reason):
        "Failed to rotate key: \(reason)"
      case let .keyVerificationFailed(reason):
        "Failed to verify key: \(reason)"
      case let .keyExportFailed(reason):
        "Failed to export key: \(reason)"
      case let .keyImportFailed(reason):
        "Failed to import key: \(reason)"
    }
  }
}

// MARK: - LoggableErrorProtocol Conformance

extension KeyManagementError: LoggingTypes.LoggableErrorProtocol {
  /// Get the privacy metadata for this error
  /// - Returns: Privacy metadata for logging this error
  public func getPrivacyMetadata() -> PrivacyMetadata {
    var metadata=PrivacyMetadata()

    // Add standard error information with appropriate privacy level
    let classification=privacyClassification
    metadata["error_type"]=PrivacyMetadataValue(value: "key_management_error", privacy: .public)
    metadata["error_code"]=PrivacyMetadataValue(value: errorCode, privacy: .public)

    // Add specific details with privacy controls
    switch self {
      case let .keyNotFound(identifier):
        metadata["identifier"]=PrivacyMetadataValue(value: identifier,
                                                    privacy: classification.toLogPrivacyLevel())
        metadata["error_detail"]=PrivacyMetadataValue(value: "key_not_found", privacy: .public)
      case let .keyCreationFailed(reason):
        metadata["reason"]=PrivacyMetadataValue(value: reason,
                                                privacy: classification.toLogPrivacyLevel())
        metadata["error_detail"]=PrivacyMetadataValue(value: "creation_failed", privacy: .public)
      case let .keyStorageFailed(reason):
        metadata["reason"]=PrivacyMetadataValue(value: reason,
                                                privacy: classification.toLogPrivacyLevel())
        metadata["error_detail"]=PrivacyMetadataValue(value: "storage_failed", privacy: .public)
      case let .invalidInput(details):
        metadata["details"]=PrivacyMetadataValue(value: details,
                                                 privacy: classification.toLogPrivacyLevel())
        metadata["error_detail"]=PrivacyMetadataValue(value: "invalid_input", privacy: .public)
      case let .keyRotationFailed(reason):
        metadata["reason"]=PrivacyMetadataValue(value: reason,
                                                privacy: classification.toLogPrivacyLevel())
        metadata["error_detail"]=PrivacyMetadataValue(value: "rotation_failed", privacy: .public)
      case let .keyVerificationFailed(reason):
        metadata["reason"]=PrivacyMetadataValue(value: reason,
                                                privacy: classification.toLogPrivacyLevel())
        metadata["error_detail"]=PrivacyMetadataValue(value: "verification_failed",
                                                      privacy: .public)
      case let .keyExportFailed(reason):
        metadata["reason"]=PrivacyMetadataValue(value: reason,
                                                privacy: classification.toLogPrivacyLevel())
        metadata["error_detail"]=PrivacyMetadataValue(value: "export_failed", privacy: .public)
      case let .keyImportFailed(reason):
        metadata["reason"]=PrivacyMetadataValue(value: reason,
                                                privacy: classification.toLogPrivacyLevel())
        metadata["error_detail"]=PrivacyMetadataValue(value: "import_failed", privacy: .public)
    }

    return metadata
  }

  /// Get the source information for this error
  /// - Returns: Source information (e.g., file, function, line)
  public func getSource() -> String {
    "KeyManagementError"
  }

  /// Get the log message for this error
  /// - Returns: A descriptive message appropriate for logging
  public func getLogMessage() -> String {
    "[\(errorCode)] \(localizedDescription)"
  }

  /// Returns a privacy classification for the error
  public var privacyClassification: LoggingTypes.PrivacyClassification {
    switch self {
      case let .keyNotFound(identifier) where identifier.contains("master"):
        // Master keys are particularly sensitive
        .sensitive
      case .keyNotFound:
        // Regular key identifiers are private
        .private
      case .keyCreationFailed, .keyStorageFailed, .keyRotationFailed,
           .keyVerificationFailed, .keyExportFailed, .keyImportFailed:
        // Details about key operations should be private
        .private
      case .invalidInput:
        // Input details might contain sensitive information
        .private
    }
  }

  /// Unique error code for the error
  private var errorCode: String {
    switch self {
      case .keyNotFound: "KM001"
      case .keyCreationFailed: "KM002"
      case .keyStorageFailed: "KM003"
      case .invalidInput: "KM004"
      case .keyRotationFailed: "KM005"
      case .keyVerificationFailed: "KM006"
      case .keyExportFailed: "KM007"
      case .keyImportFailed: "KM008"
    }
  }

  /// Categorises the reason string without revealing sensitive content
  private func categorizeReason(_ reason: String) -> String {
    if reason.contains("permission") || reason.contains("access") {
      "permission_related"
    } else if reason.contains("format") || reason.contains("corrupt") {
      "data_integrity"
    } else if reason.contains("timeout") || reason.contains("unavailable") {
      "availability"
    } else {
      "general"
    }
  }
}

/// Extension to convert PrivacyClassification to LogPrivacyLevel
extension LoggingTypes.PrivacyClassification {
  /// Convert to LogPrivacyLevel
  func toLogPrivacyLevel() -> LoggingTypes.LogPrivacyLevel {
    switch self {
      case .public: .public
      case .private: .private
      case .sensitive: .sensitive
      default: .auto
    }
  }
}
