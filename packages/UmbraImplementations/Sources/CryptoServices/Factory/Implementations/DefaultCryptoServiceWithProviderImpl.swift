// MARK: - Error Handling

func mapErrorToSecurityStorageError(_ error: Error, operation: String? = nil, metadata: [String: String]? = nil) -> SecurityStorageError {
    let errorMetadata = metadata ?? [:]
    // Log the mapping attempt
    logger.debug("Mapping provider error to SecurityStorageError", metadata: errorMetadata)

    // Check for specific SecurityProviderError types first
    if let providerError = error as? SecurityProviderError {
        logger.warning("Handling specific SecurityProviderError: \(providerError.localizedDescription)", metadata: errorMetadata)
        switch providerError {
            case .notInitialized:
                return .providerUnavailable(details: "Provider not initialized")
            case let .initializationFailed(reason):
                return .providerUnavailable(details: "Initialization failed: \(reason)")
            case .operationNotSupported:
                return .operationNotSupported(details: "Provider does not support operation: \(operation ?? "unknown")")
            case let .invalidInput(reason):
                return .invalidInput(details: "Invalid input for \(operation ?? "unknown"): \(reason)")
            case let .invalidParameters(reason):
                return .invalidParameters(details: "Invalid parameters for \(operation ?? "unknown"): \(reason)")
            case let .operationFailed(_, reason):
                // More specific mapping might be needed based on operation
                return mapOperationFailureToStorageError(operation: operation ?? "unknown", reason: reason)
            case let .storageError(reason):
                return .storageError(details: "Provider storage error: \(reason)")
            case let .configurationError(reason):
                return .configurationError(details: "Provider configuration error: \(reason)")
            case let .invalidKeyFormat(reason):
                return .keyHandlingError(details: "Invalid key format for \(operation ?? "unknown"): \(reason)")
            case let .keyNotFound(identifier, reason):
                return .keyNotFound(identifier: identifier, details: reason)
            case let .keyGenerationFailed(reason):
                return .keyGenerationFailed(details: reason)
            case let .accessDenied(reason):
                return .accessDenied(details: "Provider access denied: \(reason)")
            case let .internalError(reason):
                return .underlyingError(error: error, details: "Provider internal error: \(reason)")
        }
    }

    // Handle generic Error or other specific types if necessary
    // (Example: Handling potential URLError, etc., though less likely here)
    // ...

    // Fallback for unknown or unhandled errors
    logger.error("Unhandled error type encountered during \(operation ?? "unknown"): \(error.localizedDescription)", metadata: errorMetadata)
    return .underlyingError(error: error, details: "Unhandled error during \(operation ?? "unknown"): \(error.localizedDescription)")
}

/// Helper to map generic operation failures based on the operation type.
private func mapOperationFailureToStorageError(operation: String, reason: String) -> SecurityStorageError {
    switch operation {
        case "encrypt":
            return .encryptionFailed(details: reason)
        case "decrypt":
            return .decryptionFailed(details: reason)
        case "generateKey":
            return .keyGenerationFailed(details: reason)
        case "importKey":
            return .keyImportFailed(details: reason)
        case "exportKey":
            return .keyExportFailed(details: reason)
        case "deleteKey":
            return .keyDeletionFailed(details: reason)
        case "signData":
            return .signingFailed(details: reason)
        case "verifySignature":
            return .verificationFailed(details: reason)
        default:
            logger.warning("Mapping generic operation failure for unknown operation '\(operation)'")
            return .operationFailed(details: "Operation '\(operation)' failed: \(reason)")
    }
}
