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

  /// General key management error
  case keyManagementError(details: String)

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
      case let .keyManagementError(details):
        "Key management error: \(details)"
    }
  }
}

// MARK: - LoggableErrorProtocol Conformance

extension KeyManagementError: LoggingTypes.LoggableErrorProtocol {
  /// Create a metadata collection for this error with appropriate privacy levels
  /// - Returns: A metadata collection with privacy classifications
  public func createMetadataCollection() -> LogMetadataDTOCollection {
    var metadata = LogMetadataDTOCollection()

    // Add standard error information with appropriate privacy level
    let classification = privacyClassification
    metadata = metadata.withPublic(key: "error_type", value: "key_management_error")
    metadata = metadata.withPublic(key: "error_code", value: errorCode)

    // Add specific details with privacy controls
    switch self {
      case let .keyNotFound(identifier):
        switch classification {
          case .public:
            metadata = metadata.withPublic(key: "identifier", value: identifier)
          case .private:
            metadata = metadata.withPrivate(key: "identifier", value: identifier)
          case .sensitive:
            metadata = metadata.withSensitive(key: "identifier", value: identifier)
          case .hash:
            metadata = metadata.withPublic(key: "identifier", value: "Identifier data hashed for privacy")
          case .auto:
            metadata = metadata.withPrivate(key: "identifier", value: identifier)
        }
        metadata = metadata.withPublic(key: "error_detail", value: "key_not_found")
        
      case let .keyCreationFailed(reason):
        switch classification {
          case .public:
            metadata = metadata.withPublic(key: "reason", value: reason)
          case .private:
            metadata = metadata.withPrivate(key: "reason", value: reason)
          case .sensitive:
            metadata = metadata.withSensitive(key: "reason", value: reason)
          case .hash:
            metadata = metadata.withPublic(key: "reason", value: "Reason data hashed for privacy")
          case .auto:
            metadata = metadata.withPrivate(key: "reason", value: reason)
        }
        metadata = metadata.withPublic(key: "error_detail", value: "creation_failed")
        
      case let .keyStorageFailed(reason):
        switch classification {
          case .public:
            metadata = metadata.withPublic(key: "reason", value: reason)
          case .private:
            metadata = metadata.withPrivate(key: "reason", value: reason)
          case .sensitive:
            metadata = metadata.withSensitive(key: "reason", value: reason)
          case .hash:
            metadata = metadata.withPublic(key: "reason", value: "Reason data hashed for privacy")
          case .auto:
            metadata = metadata.withPrivate(key: "reason", value: reason)
        }
        metadata = metadata.withPublic(key: "error_detail", value: "storage_failed")
        
      case let .invalidInput(details):
        switch classification {
          case .public:
            metadata = metadata.withPublic(key: "details", value: details)
          case .private:
            metadata = metadata.withPrivate(key: "details", value: details)
          case .sensitive:
            metadata = metadata.withSensitive(key: "details", value: details)
          case .hash:
            metadata = metadata.withPublic(key: "details", value: "Details data hashed for privacy")
          case .auto:
            metadata = metadata.withPrivate(key: "details", value: details)
        }
        metadata = metadata.withPublic(key: "error_detail", value: "invalid_input")
        
      case let .keyRotationFailed(reason):
        switch classification {
          case .public:
            metadata = metadata.withPublic(key: "reason", value: reason)
          case .private:
            metadata = metadata.withPrivate(key: "reason", value: reason)
          case .sensitive:
            metadata = metadata.withSensitive(key: "reason", value: reason)
          case .hash:
            metadata = metadata.withPublic(key: "reason", value: "Reason data hashed for privacy")
          case .auto:
            metadata = metadata.withPrivate(key: "reason", value: reason)
        }
        metadata = metadata.withPublic(key: "error_detail", value: "rotation_failed")
        
      case let .keyVerificationFailed(reason):
        switch classification {
          case .public:
            metadata = metadata.withPublic(key: "reason", value: reason)
          case .private:
            metadata = metadata.withPrivate(key: "reason", value: reason)
          case .sensitive:
            metadata = metadata.withSensitive(key: "reason", value: reason)
          case .hash:
            metadata = metadata.withPublic(key: "reason", value: "Reason data hashed for privacy")
          case .auto:
            metadata = metadata.withPrivate(key: "reason", value: reason)
        }
        metadata = metadata.withPublic(key: "error_detail", value: "verification_failed")
        
      case let .keyExportFailed(reason):
        switch classification {
          case .public:
            metadata = metadata.withPublic(key: "reason", value: reason)
          case .private:
            metadata = metadata.withPrivate(key: "reason", value: reason)
          case .sensitive:
            metadata = metadata.withSensitive(key: "reason", value: reason)
          case .hash:
            metadata = metadata.withPublic(key: "reason", value: "Reason data hashed for privacy")
          case .auto:
            metadata = metadata.withPrivate(key: "reason", value: reason)
        }
        metadata = metadata.withPublic(key: "error_detail", value: "export_failed")
        
      case let .keyImportFailed(reason):
        switch classification {
          case .public:
            metadata = metadata.withPublic(key: "reason", value: reason)
          case .private:
            metadata = metadata.withPrivate(key: "reason", value: reason)
          case .sensitive:
            metadata = metadata.withSensitive(key: "reason", value: reason)
          case .hash:
            metadata = metadata.withPublic(key: "reason", value: "Reason data hashed for privacy")
          case .auto:
            metadata = metadata.withPrivate(key: "reason", value: reason)
        }
        metadata = metadata.withPublic(key: "error_detail", value: "import_failed")
        
      case let .keyManagementError(details):
        switch classification {
          case .public:
            metadata = metadata.withPublic(key: "details", value: details)
          case .private:
            metadata = metadata.withPrivate(key: "details", value: details)
          case .sensitive:
            metadata = metadata.withSensitive(key: "details", value: details)
          case .hash:
            metadata = metadata.withPublic(key: "details", value: "Details data hashed for privacy")
          case .auto:
            metadata = metadata.withPrivate(key: "details", value: details)
        }
        metadata = metadata.withPublic(key: "error_detail", value: "key_management_error")
    }

    return metadata
  }

  /// Get the source information for this error
  /// - Returns: Source information
  public func getSource() -> String {
    return "KeyManagementService"
  }

  /// Get the log message for this error
  /// - Returns: A descriptive message appropriate for logging
  public func getLogMessage() -> String {
    switch self {
      case .keyNotFound(let identifier):
        return "Key not found: \(identifier)"
      case .keyCreationFailed(let reason):
        return "Key creation failed: \(reason)"
      case .keyStorageFailed(let reason):
        return "Key storage failed: \(reason)"
      case .invalidInput(let details):
        return "Invalid input: \(details)"
      case .keyRotationFailed(let reason):
        return "Key rotation failed: \(reason)"
      case .keyVerificationFailed(let reason):
        return "Key verification failed: \(reason)"
      case .keyExportFailed(let reason):
        return "Key export failed: \(reason)"
      case .keyImportFailed(let reason):
        return "Key import failed: \(reason)"
      case .keyManagementError(let details):
        return "Key management error: \(details)"
    }
  }
  
  /// Returns a privacy classification for the error
  private var privacyClassification: LoggingTypes.PrivacyClassification {
    switch self {
      case let .keyNotFound(identifier) where identifier.contains("master"):
        // Master keys are particularly sensitive
        return .sensitive
      case .keyNotFound:
        // Regular key identifiers are private
        return .private
      case .keyCreationFailed, .keyStorageFailed, .keyRotationFailed,
           .keyVerificationFailed, .keyExportFailed, .keyImportFailed:
        // Details about key operations should be private
        return .private
      case .invalidInput:
        // Input details might contain sensitive information
        return .private
      case .keyManagementError:
        // General key management errors are private
        return .private
    }
  }

  /// Unique error code for the error
  private var errorCode: String {
    switch self {
      case .keyNotFound: return "KM001"
      case .keyCreationFailed: return "KM002"
      case .keyStorageFailed: return "KM003"
      case .invalidInput: return "KM004"
      case .keyRotationFailed: return "KM005"
      case .keyVerificationFailed: return "KM006"
      case .keyExportFailed: return "KM007"
      case .keyImportFailed: return "KM008"
      case .keyManagementError: return "KM009"
    }
  }

  /// Categorises the reason string without revealing sensitive content
  private func categorizeReason(_ reason: String) -> String {
    if reason.contains("permission") || reason.contains("access") {
      return "permission_related"
    } else if reason.contains("format") || reason.contains("corrupt") {
      return "data_integrity"
    } else if reason.contains("timeout") || reason.contains("unavailable") {
      return "availability"
    } else {
      return "general"
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
      case .hash: .hash
      case .auto: .auto
    }
  }
}
