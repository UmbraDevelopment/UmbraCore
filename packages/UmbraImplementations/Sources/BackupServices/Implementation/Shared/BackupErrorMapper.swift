import BackupInterfaces
import Foundation
import LoggingTypes
import ResticInterfaces
import UmbraErrors

/**
 * Provides error mapping functionality for backup operations
 *
 * This utility converts low-level errors into domain-specific
 * BackupError types that are more meaningful to clients of the backup services,
 * while ensuring privacy-sensitive information is properly handled.
 */
public struct BackupErrorMapper {
    
    public init() {}

    /**
     * Maps any error to an appropriate BackupError
     * - Parameters:
     *   - error: The original error
     *   - context: Log context for the operation
     * - Returns: An appropriate BackupError
     */
    public func mapError(_ error: Error, context: LogContextDTO? = nil) -> BackupError {
        // If it's already a BackupError, just return it
        if let backupError = error as? BackupError {
            return backupError
        }
        
        // Handle ResticError types
        if let resticError = error as? ResticError {
            return convertResticError(resticError)
        }
        
        // Handle URLError types
        if let urlError = error as? URLError {
            return BackupError.networkConnectionFailure(
                code: urlError.code.rawValue,
                reason: urlError.localizedDescription
            )
        }
        
        // Handle NSError types
        if let nsError = error as? NSError {
            switch nsError.domain {
                case NSURLErrorDomain:
                    return BackupError.networkConnectionFailure(
                        code: nsError.code,
                        reason: nsError.localizedDescription
                    )
                    
                case NSPOSIXErrorDomain:
                    return BackupError.invalidConfiguration(
                        details: "File system error: \(nsError.localizedDescription)"
                    )
                    
                case NSCocoaErrorDomain:
                    if nsError.code == NSFileNoSuchFileError {
                        if let url = nsError.userInfo[NSURLErrorKey] as? URL {
                            return BackupError.invalidConfiguration(
                                details: "File not found: \(url.path)"
                            )
                        } else {
                            return BackupError.invalidConfiguration(
                                details: "File not found: unknown path"
                            )
                        }
                    } else {
                        return BackupError.invalidConfiguration(
                            details: "File system error: \(nsError.localizedDescription)"
                        )
                    }
                    
                default:
                    break
            }
        }
        
        // For other errors, create a general error
        return BackupError.unexpectedError(
            error.localizedDescription
        )
    }

    /// Converts a ResticError to a BackupError
    /// - Parameter error: The original Restic error
    /// - Returns: An appropriate BackupError
    func convertResticError(_ error: ResticError) -> BackupError {
        switch error {
            case let .repositoryNotFound(path):
                return BackupError.repositoryAccessFailure(
                    path: path,
                    reason: "Repository not found"
                )

            case let .permissionDenied(path):
                return BackupError.repositoryAccessFailure(
                    path: path,
                    reason: "Access denied"
                )

            case .invalidPassword:
                return BackupError.authenticationFailure(
                    reason: "Invalid repository password"
                )

            case let .missingParameter(param):
                return BackupError.invalidConfiguration(
                    details: "Missing parameter: \(param)"
                )

            case let .invalidParameter(param):
                return BackupError.invalidConfiguration(
                    details: "Invalid parameter: \(param)"
                )

            case let .executionFailure(exitCode, message):
                return BackupError.commandExecutionFailure(
                    command: "restic",
                    exitCode: exitCode,
                    errorOutput: message
                )

            case let .executionFailed(message):
                return BackupError.commandExecutionFailure(
                    command: "restic",
                    exitCode: -1,
                    errorOutput: message
                )

            default:
                return BackupError.unexpectedError(
                    "Unexpected Restic error: \(error.localizedDescription)"
                )
        }
    }
}
