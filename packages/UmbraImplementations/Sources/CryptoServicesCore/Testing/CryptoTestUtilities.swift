import CoreSecurityTypes
import CryptoInterfaces
import Foundation
import SecurityCoreInterfaces

/**
 # CryptoTestUtilities
 
 A collection of utility functions and extensions useful for testing
 cryptographic services and components.
 
 These utilities make it easier to create test data, mock configurations,
 and verify cryptographic operations in unit tests and integration tests.
 */
public enum CryptoTestUtilities {
    // MARK: - Test Data Generation
    
    /**
     Creates a deterministic test data buffer of the specified size.
     
     - Parameter size: The size of the data buffer in bytes
     - Returns: A Data object containing deterministic test data
     */
    public static func createTestData(size: Int) -> Data {
        var data = Data(capacity: size)
        for i in 0..<size {
            data.append(UInt8(i % 256))
        }
        return data
    }
    
    /**
     Creates a deterministic test key for the specified algorithm.
     
     - Parameter algorithm: The encryption algorithm to create a key for
     - Returns: A Data object containing a suitable test key
     */
    public static func createTestKey(for algorithm: String) -> Data {
        switch algorithm.lowercased() {
        case "aes-256", "aes-256-gcm", "aes256gcm", "aes256-gcm", "aes256", "aes-256-cbc", "aes256cbc":
            return createTestData(size: 32) // 256 bits = 32 bytes
        case "aes-128", "aes-128-gcm", "aes128gcm", "aes128", "aes-128-cbc", "aes128cbc":
            return createTestData(size: 16) // 128 bits = 16 bytes
        case "chacha20poly1305", "chacha20-poly1305":
            return createTestData(size: 32) // 256 bits = 32 bytes
        default:
            // Default to AES-256 key size
            return createTestData(size: 32)
        }
    }
    
    /**
     Creates a deterministic test IV (Initialisation Vector) for the specified algorithm.
     
     - Parameter algorithm: The encryption algorithm to create an IV for
     - Returns: A Data object containing a suitable test IV
     */
    public static func createTestIV(for algorithm: String) -> Data {
        switch algorithm.lowercased() {
        case "aes-256-gcm", "aes256gcm", "aes-128-gcm", "aes128gcm":
            return createTestData(size: 12) // 96 bits = 12 bytes for GCM
        case "aes-256-cbc", "aes256cbc", "aes-128-cbc", "aes128cbc":
            return createTestData(size: 16) // 128 bits = 16 bytes for CBC
        case "chacha20poly1305", "chacha20-poly1305":
            return createTestData(size: 12) // 96 bits = 12 bytes
        default:
            // Default to GCM IV size
            return createTestData(size: 12)
        }
    }
    
    // MARK: - Configuration Creation
    
    /**
     Creates encryption options for testing.
     
     - Parameters:
        - algorithm: The encryption algorithm
        - testIV: The initialisation vector to use
        - aad: Additional authenticated data (for AEAD modes)
     - Returns: Configured encryption options
     */
    public static func createEncryptionOptions(
        algorithm: EncryptionAlgorithm,
        testIV: [UInt8],
        aad: [UInt8]? = nil
    ) -> EncryptionOptions {
        // Create appropriate EncryptionMode based on algorithm
        let mode: EncryptionMode
        switch algorithm {
        case .aes256CBC:
            mode = .cbc
        case .aes256GCM:
            mode = .gcm
        case .chacha20Poly1305:
            mode = .gcm // ChaCha20 doesn't have a direct mode in EncryptionMode
        }
        
        // Create appropriate EncryptionPadding based on algorithm
        let padding: EncryptionPadding
        switch algorithm {
        case .aes256CBC:
            padding = .pkcs7
        case .aes256GCM, .chacha20Poly1305:
            padding = .none
        }
        
        return EncryptionOptions(
            algorithm: algorithm,
            mode: mode,
            padding: padding,
            iv: testIV,
            additionalAuthenticatedData: aad
        )
    }
    
    /**
     Creates decryption options for testing.
     
     - Parameters:
        - algorithm: The decryption algorithm
        - testIV: The initialisation vector to use
        - aad: Additional authenticated data (for AEAD modes)
     - Returns: Configured decryption options
     */
    public static func createDecryptionOptions(
        algorithm: EncryptionAlgorithm,
        testIV: [UInt8],
        aad: [UInt8]? = nil
    ) -> DecryptionOptions {
        // Decryption options mirror encryption options
        return createEncryptionOptions(
            algorithm: algorithm,
            testIV: testIV,
            aad: aad
        )
    }
    
    /**
     Creates hashing options for testing.
     
     - Parameter algorithm: The hash algorithm to use
     - Returns: Configured hashing options
     */
    public static func createHashingOptions(
        algorithm: HashAlgorithm = .sha256
    ) -> CoreSecurityTypes.HashingOptions {
        return CoreSecurityTypes.HashingOptions(
            algorithm: algorithm
        )
    }
    
    /**
     Creates key generation options for testing.
     
     - Parameters:
        - keyType: The type of key to generate
        - keySizeInBits: The key size in bits
        - isExtractable: Whether the key can be exported
        - useSecureEnclave: Whether to use secure hardware if available
     - Returns: Configured key generation options
     */
    public static func createKeyGenerationOptions(
        keyType: KeyType = .aes,
        keySizeInBits: Int = 256,
        isExtractable: Bool = true,
        useSecureEnclave: Bool = false
    ) -> CoreSecurityTypes.KeyGenerationOptions {
        return CoreSecurityTypes.KeyGenerationOptions(
            keyType: keyType,
            keySizeInBits: keySizeInBits,
            isExtractable: isExtractable,
            useSecureEnclave: useSecureEnclave
        )
    }
    
    // MARK: - Helper Functions
    
    // MARK: - Extensions
}

// MARK: - Extensions

/// Extension on Data for easy conversion to/from strings for testing
public extension Data {
    /// Creates a hexadecimal string representation of the data
    var hexString: String {
        return self.map { String(format: "%02x", $0) }.joined()
    }
    
    /// Creates data from a hexadecimal string
    static func fromHexString(_ string: String) -> Data? {
        let len = string.count / 2
        var data = Data(capacity: len)
        for i in 0..<len {
            let j = string.index(string.startIndex, offsetBy: i * 2)
            let k = string.index(j, offsetBy: 2)
            let bytes = string[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        return data
    }
}

/// Extension to simplify mocking for test verification
@available(*, deprecated, message: "Use only for testing")
public extension CryptoServiceProtocol {
    /// Convenience function to test if an implementation is a mock
    @available(*, deprecated, message: "Use only for testing")
    var isMock: Bool {
        return self is MockCryptoService
    }
}

/// Extension to allow direct construction of mock secure storage with common configurations
@available(*, deprecated, message: "Use only for testing")
public extension MockSecureStorage {
    /// Creates a mockSecureStorage that always fails with a specific error
    static func alwaysFailing(
        error: SecurityStorageError = .operationFailed("Mock failure"),
        delay: TimeInterval? = nil
    ) -> MockSecureStorage {
        let behaviour = MockBehaviour(
            shouldSucceed: false,
            failureError: error
        )
        return MockSecureStorage(behaviour: behaviour)
    }
    
    /// Creates a mockSecureStorage with a specified delay
    static func withDelay(
        seconds: TimeInterval = 0.5
    ) -> MockSecureStorage {
        let behaviour = MockBehaviour(
            shouldSucceed: true,
            delay: seconds
        )
        return MockSecureStorage(behaviour: behaviour)
    }
}
