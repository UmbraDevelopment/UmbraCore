import Foundation
import LoggingTypes
import LoggingInterfaces

/// Represents the status of a keychain operation for UI binding
public enum KeychainOperationStatus: Equatable {
    /// No operation in progress
    case idle
    
    /// Operation is currently processing
    case processing
    
    /// Operation completed successfully
    case completed
    
    /// Operation failed with an error
    case failed(Error)
    
    public static func == (lhs: KeychainOperationStatus, rhs: KeychainOperationStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.processing, .processing):
            return true
        case (.completed, .completed):
            return true
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

/// Protocol for keychain security operations
public protocol KeychainSecurityProtocol {
    /// Store a secret in the keychain
    /// - Parameters:
    ///   - secret: The secret to store
    ///   - account: The account identifier
    func storeSecret(_ secret: String, forAccount account: String) async throws
    
    /// Retrieve a secret from the keychain
    /// - Parameter account: The account identifier
    /// - Returns: The secret if found
    func retrieveSecret(forAccount account: String) async throws -> String
    
    /// Delete a secret from the keychain
    /// - Parameter account: The account identifier
    func deleteSecret(forAccount account: String) async throws
}

/// Example errors that can occur during keychain operations
public enum KeychainError: Error, LocalizedError {
    case accessDenied
    case itemNotFound
    case duplicateItem
    case unexpectedStatus(OSStatus)
    
    public var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Access to the keychain was denied"
        case .itemNotFound:
            return "The requested item was not found in the keychain"
        case .duplicateItem:
            return "An item with this identifier already exists in the keychain"
        case .unexpectedStatus(let status):
            return "Unexpected keychain error with status: \(status)"
        }
    }
}

/// ViewModel for keychain security operations that demonstrates integration
/// with the privacy-enhanced logging system.
public class KeychainSecurityViewModel {
    /// The logger for recording operations with privacy controls
    private let logger: any PrivacyAwareLoggingProtocol
    
    /// The service for keychain operations
    private let keychainService: KeychainSecurityProtocol
    
    /// Current operation status for UI binding
    @Published public private(set) var status: KeychainOperationStatus = .idle
    
    /// Creates a new KeychainSecurityViewModel
    /// - Parameters:
    ///   - logger: The logger for recording operations
    ///   - keychainService: The service for keychain operations
    public init(logger: any PrivacyAwareLoggingProtocol, keychainService: KeychainSecurityProtocol) {
        self.logger = logger
        self.keychainService = keychainService
    }
    
    /// Store a secret in the keychain
    /// - Parameters:
    ///   - secret: The secret to store
    ///   - account: The account identifier
    public func storeSecret(_ secret: String, forAccount account: String) async {
        // Update status for UI binding
        status = .processing
        
        await logger.log(
            .info,
            "Processing secret storage for \(private: account)",
            metadata: [
                "secretLength": (value: secret.count, privacy: .public),
                "hasSpecialCharacters": (value: containsSpecialCharacters(secret), privacy: .public)
            ],
            source: "KeychainSecurityViewModel"
        )
        
        do {
            try await keychainService.storeSecret(secret, forAccount: account)
            
            // Update status for UI binding
            status = .completed
            
            await logger.info(
                "Secret stored successfully",
                metadata: [
                    "accountIdentifier": (value: account, privacy: .private)
                ],
                source: "KeychainSecurityViewModel"
            )
        } catch {
            // Update status for UI binding
            status = .failed(error)
            
            await logger.logError(
                error,
                privacyLevel: .private,
                metadata: [
                    "operation": (value: "storeSecret", privacy: .public),
                    "accountIdentifier": (value: account, privacy: .private)
                ],
                source: "KeychainSecurityViewModel"
            )
        }
    }
    
    /// Retrieve a secret from the keychain
    /// - Parameter account: The account identifier
    /// - Returns: The secret if found
    public func retrieveSecret(forAccount account: String) async -> String? {
        // Update status for UI binding
        status = .processing
        
        await logger.log(
            .info,
            "Retrieving secret for \(private: account)",
            metadata: nil,
            source: "KeychainSecurityViewModel"
        )
        
        do {
            let secret = try await keychainService.retrieveSecret(forAccount: account)
            
            // Update status for UI binding
            status = .completed
            
            await logger.log(
                .info,
                "Secret retrieved successfully for \(private: account)",
                metadata: [
                    "secretLength": (value: secret.count, privacy: .public),
                    "hasSpecialCharacters": (value: containsSpecialCharacters(secret), privacy: .public)
                ],
                source: "KeychainSecurityViewModel"
            )
            
            return secret
        } catch {
            // Update status for UI binding
            status = .failed(error)
            
            await logger.logError(
                error,
                privacyLevel: .private,
                metadata: [
                    "operation": (value: "retrieveSecret", privacy: .public),
                    "accountIdentifier": (value: account, privacy: .private)
                ],
                source: "KeychainSecurityViewModel"
            )
            
            return nil
        }
    }
    
    /// Delete a secret from the keychain
    /// - Parameter account: The account identifier
    public func deleteSecret(forAccount account: String) async {
        // Update status for UI binding
        status = .processing
        
        await logger.log(
            .info,
            "Deleting secret for \(private: account)",
            metadata: nil,
            source: "KeychainSecurityViewModel"
        )
        
        do {
            try await keychainService.deleteSecret(forAccount: account)
            
            // Update status for UI binding
            status = .completed
            
            await logger.info(
                "Secret deleted successfully",
                metadata: [
                    "accountIdentifier": (value: account, privacy: .private)
                ],
                source: "KeychainSecurityViewModel"
            )
        } catch {
            // Update status for UI binding
            status = .failed(error)
            
            await logger.logError(
                error,
                privacyLevel: .private,
                metadata: [
                    "operation": (value: "deleteSecret", privacy: .public),
                    "accountIdentifier": (value: account, privacy: .private)
                ],
                source: "KeychainSecurityViewModel"
            )
        }
    }
    
    /// Check if a string contains special characters
    /// - Parameter string: The string to check
    /// - Returns: True if the string contains special characters
    private func containsSpecialCharacters(_ string: String) -> Bool {
        let specialCharacterSet = CharacterSet(charactersIn: "!@#$%^&*()_-+=[]{}|\\;:'\",.<>/?")
        return string.rangeOfCharacter(from: specialCharacterSet) != nil
    }
}
