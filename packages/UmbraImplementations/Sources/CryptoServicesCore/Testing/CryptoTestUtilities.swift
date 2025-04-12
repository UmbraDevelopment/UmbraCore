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
     Creates a test EncryptionOptions object for the specified algorithm.
     
     - Parameters:
        - algorithm: The encryption algorithm to create options for
        - iv: An optional initialisation vector to use (generated if nil)
        - aad: Optional additional authenticated data
     - Returns: An EncryptionOptions object suitable for testing
     */
    public static func createEncryptionOptions(
        algorithm: String,
        iv: Data? = nil,
        aad: Data? = nil
    ) -> EncryptionOptions {
        let testIV = iv ?? createTestIV(for: algorithm)
        
        return EncryptionOptions(
            algorithm: algorithm,
            mode: getDefaultMode(for: algorithm),
            padding: getDefaultPadding(for: algorithm),
            iv: testIV,
            aad: aad
        )
    }
    
    /**
     Creates a test DecryptionOptions object for the specified algorithm.
     
     - Parameters:
        - algorithm: The decryption algorithm to create options for
        - iv: An optional initialisation vector to use (generated if nil)
        - aad: Optional additional authenticated data
     - Returns: A DecryptionOptions object suitable for testing
     */
    public static func createDecryptionOptions(
        algorithm: String,
        iv: Data? = nil,
        aad: Data? = nil
    ) -> DecryptionOptions {
        let testIV = iv ?? createTestIV(for: algorithm)
        
        return DecryptionOptions(
            algorithm: algorithm,
            mode: getDefaultMode(for: algorithm),
            padding: getDefaultPadding(for: algorithm),
            iv: testIV,
            aad: aad
        )
    }
    
    /**
     Creates a test HashingOptions object for the specified algorithm.
     
     - Parameter algorithm: The hashing algorithm to create options for
     - Returns: A HashingOptions object suitable for testing
     */
    public static func createHashingOptions(
        algorithm: String = "SHA-256"
    ) -> HashingOptions {
        return HashingOptions(
            algorithm: algorithm,
            metadata: nil
        )
    }
    
    /**
     Creates a test KeyGenerationOptions object for the specified algorithm.
     
     - Parameters:
        - algorithm: The encryption algorithm to create key options for
        - keyUsage: The intended usage of the key
        - metadata: Additional metadata for the key
     - Returns: A KeyGenerationOptions object suitable for testing
     */
    public static func createKeyGenerationOptions(
        algorithm: String,
        keyUsage: String = "encryption",
        metadata: [String: String]? = nil
    ) -> KeyGenerationOptions {
        return KeyGenerationOptions(
            algorithm: algorithm,
            keyUsage: keyUsage,
            metadata: metadata
        )
    }
    
    // MARK: - Helper Functions
    
    /**
     Gets the default mode for an encryption algorithm.
     
     - Parameter algorithm: The encryption algorithm
     - Returns: The default mode for the algorithm
     */
    private static func getDefaultMode(for algorithm: String) -> String {
        if algorithm.lowercased().contains("gcm") {
            return "GCM"
        } else if algorithm.lowercased().contains("cbc") {
            return "CBC"
        } else if algorithm.lowercased().contains("aes") {
            return "GCM" // Default to GCM for AES
        } else if algorithm.lowercased().contains("chacha20") {
            return "Poly1305" // For ChaCha20-Poly1305
        } else {
            return "GCM" // Default to GCM
        }
    }
    
    /**
     Gets the default padding for an encryption algorithm.
     
     - Parameter algorithm: The encryption algorithm
     - Returns: The default padding for the algorithm
     */
    private static func getDefaultPadding(for algorithm: String) -> String {
        if algorithm.lowercased().contains("gcm") || 
           algorithm.lowercased().contains("chacha20") {
            return "NoPadding"
        } else if algorithm.lowercased().contains("cbc") {
            return "PKCS7Padding"
        } else {
            return "NoPadding" // Default
        }
    }
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
public extension CryptoServiceProtocol {
    /// Convenience function to test if an implementation is a mock
    var isMock: Bool {
        return self is MockCryptoService
    }
}

/// Extension to allow direct construction of mock secure storage with common configurations
public extension MockSecureStorage {
    /// Creates a mockSecureStorage that always fails with a specific error
    static func alwaysFailing(
        error: SecurityStorageError = .storageError("Mock failure"),
        delay: TimeInterval? = nil
    ) -> MockSecureStorage {
        return MockSecureStorage(
            shouldSucceed: false, 
            mockResponseDelay: delay,
            mockError: error
        )
    }
    
    /// Creates a mockSecureStorage with simulated network delay
    static func withDelay(
        seconds: TimeInterval = 0.5
    ) -> MockSecureStorage {
        return MockSecureStorage(
            shouldSucceed: true,
            mockResponseDelay: seconds
        )
    }
}
