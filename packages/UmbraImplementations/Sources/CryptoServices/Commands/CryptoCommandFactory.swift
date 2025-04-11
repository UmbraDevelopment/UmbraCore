import CoreSecurityTypes
import CryptoInterfaces
import DomainSecurityTypes
import Foundation
import LoggingInterfaces

/**
 Factory for creating cryptographic operation command objects.
 
 This factory creates appropriate command objects for different cryptographic
 operations, enabling a more modular and testable architecture while
 maintaining the same functionality.
 */
public struct CryptoCommandFactory {
    /// The secure storage for cryptographic materials
    private let secureStorage: SecureStorageProtocol
    
    /// Logger for operation auditing and tracking
    private let logger: LoggingProtocol?
    
    /**
     Initialises a new crypto command factory.
     
     - Parameters:
        - secureStorage: Secure storage for cryptographic materials
        - logger: Optional logger for operation tracking and auditing
     */
    public init(secureStorage: SecureStorageProtocol, logger: LoggingProtocol? = nil) {
        self.secureStorage = secureStorage
        self.logger = logger
    }
    
    /**
     Creates a command for encrypting data.
     
     - Parameters:
        - data: The data to encrypt
        - keyIdentifier: The identifier of the encryption key
        - algorithm: The encryption algorithm to use
        - iv: Optional initialization vector
     - Returns: A configured encrypt command
     */
    public func createEncryptCommand(
        data: [UInt8],
        keyIdentifier: String,
        algorithm: EncryptionAlgorithm = .aes256GCM,
        iv: [UInt8]? = nil
    ) -> EncryptDataCommand {
        return EncryptDataCommand(
            data: data,
            keyIdentifier: keyIdentifier,
            algorithm: algorithm,
            iv: iv,
            secureStorage: secureStorage,
            logger: logger
        )
    }
    
    /**
     Creates a command for decrypting data.
     
     - Parameters:
        - encryptedDataIdentifier: The identifier of the encrypted data
        - algorithm: The encryption algorithm used
     - Returns: A configured decrypt command
     */
    public func createDecryptCommand(
        encryptedDataIdentifier: String,
        algorithm: EncryptionAlgorithm = .aes256GCM
    ) -> DecryptDataCommand {
        return DecryptDataCommand(
            encryptedDataIdentifier: encryptedDataIdentifier,
            algorithm: algorithm,
            secureStorage: secureStorage,
            logger: logger
        )
    }
    
    /**
     Creates a command for hashing data.
     
     - Parameters:
        - data: The data to hash
        - algorithm: The hash algorithm to use
        - salt: Optional salt for the hash
     - Returns: A configured hash command
     */
    public func createHashCommand(
        data: [UInt8],
        algorithm: HashAlgorithm = .sha256,
        salt: [UInt8]? = nil
    ) -> HashDataCommand {
        return HashDataCommand(
            data: data,
            algorithm: algorithm,
            salt: salt,
            secureStorage: secureStorage,
            logger: logger
        )
    }
    
    /**
     Creates a command for verifying a hash.
     
     - Parameters:
        - data: The data to verify
        - expectedHash: The expected hash value
        - algorithm: The hash algorithm to use
        - salt: Optional salt for the hash
     - Returns: A configured hash verification command
     */
    public func createVerifyHashCommand(
        data: [UInt8],
        expectedHash: [UInt8],
        algorithm: HashAlgorithm = .sha256,
        salt: [UInt8]? = nil
    ) -> VerifyHashCommand {
        return VerifyHashCommand(
            data: data,
            expectedHash: expectedHash,
            algorithm: algorithm,
            salt: salt,
            secureStorage: secureStorage,
            logger: logger
        )
    }
    
    /**
     Creates a command for generating a cryptographic key.
     
     - Parameters:
        - keyType: The type of key to generate
        - size: Optional key size in bits
        - identifier: Optional predefined identifier for the key
     - Returns: A configured key generation command
     */
    public func createGenerateKeyCommand(
        keyType: KeyType,
        size: Int? = nil,
        identifier: String? = nil
    ) -> GenerateKeyCommand {
        return GenerateKeyCommand(
            keyType: keyType,
            size: size,
            identifier: identifier,
            secureStorage: secureStorage,
            logger: logger
        )
    }
    
    /**
     Creates a command for importing external data.
     
     - Parameters:
        - data: The data to import
        - identifier: Optional predefined identifier for the imported data
     - Returns: A configured import data command
     */
    public func createImportDataCommand(
        data: [UInt8],
        identifier: String? = nil
    ) -> ImportDataCommand {
        return ImportDataCommand(
            data: data,
            identifier: identifier,
            secureStorage: secureStorage,
            logger: logger
        )
    }
    
    /**
     Creates a command for exporting data.
     
     - Parameter identifier: The identifier of the data to export
     - Returns: A configured export data command
     */
    public func createExportDataCommand(
        identifier: String
    ) -> ExportDataCommand {
        return ExportDataCommand(
            identifier: identifier,
            secureStorage: secureStorage,
            logger: logger
        )
    }
}
