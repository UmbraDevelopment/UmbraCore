import Foundation
import CoreSecurityTypes
import SecurityCoreInterfaces

/// Provides standardised conversion utilities between different formats and types
/// for cryptographic operations in the UmbraCore system.
///
/// This helps maintain a clear boundary between different modules and their type systems,
/// ensuring type safety and making conversion points explicit and testable.
public enum CryptoConversionDTO: Sendable {
    
    // MARK: - SecurityResultDTO Conversions
    
    /// Create a standard SecurityResultDTO with data payload
    ///
    /// - Parameters:
    ///   - data: The data to include in the result
    ///   - metadata: Additional metadata to include
    /// - Returns: A properly formatted SecurityResultDTO
    public static func createSuccessResult(
        data: Data,
        metadata: [String: String] = [:]
    ) -> SecurityResultDTO {
        return SecurityResultDTO.success(
            resultData: data,
            executionTimeMs: 0,
            metadata: metadata
        )
    }
    
    /// Create a SecurityResultDTO from byte array data
    ///
    /// - Parameters:
    ///   - bytes: The byte array to include in the result
    ///   - metadata: Additional metadata to include
    /// - Returns: A properly formatted SecurityResultDTO
    public static func createSuccessResult(
        bytes: [UInt8],
        metadata: [String: String] = [:]
    ) -> SecurityResultDTO {
        return SecurityResultDTO.success(
            resultData: Data(bytes),
            executionTimeMs: 0,
            metadata: metadata
        )
    }
    
    // MARK: - Error Conversions
    
    /// Convert from one error type to SecurityStorageError
    ///
    /// - Parameters:
    ///   - error: The source error
    ///   - defaultMessage: Default message if the error can't be specifically mapped
    /// - Returns: A properly converted SecurityStorageError
    public static func toSecurityStorageError(
        from error: Error,
        defaultMessage: String = "Operation failed"
    ) -> SecurityStorageError {
        if let storageError = error as? SecurityStorageError {
            return storageError
        }
        
        let nsError = error as NSError
        
        // Map specific error domains
        if nsError.domain == NSOSStatusErrorDomain {
            return .generalError(reason: "Security framework error: \(nsError.code)")
        } else if nsError.domain == NSPOSIXErrorDomain {
            return .generalError(reason: "System error: \(nsError.code)")
        }
        
        return .operationFailed(error.localizedDescription)
    }
    
    /// Convert from CommonCrypto status code to SecurityStorageError
    ///
    /// - Parameters:
    ///   - status: The CommonCrypto status code
    ///   - operation: Description of the operation that failed
    /// - Returns: A properly converted SecurityStorageError
    public static func toSecurityStorageError(
        fromStatus status: Int32,
        operation: String
    ) -> SecurityStorageError {
        return .generalError(reason: "\(operation) failed with status: \(status)")
    }
    
    // MARK: - Algorithm Conversions
    
    /// Convert from EncryptionAlgorithm to string representation
    ///
    /// - Parameter algorithm: The encryption algorithm
    /// - Returns: String representation of the algorithm
    public static func toString(algorithm: EncryptionAlgorithm) -> String {
        switch algorithm {
        case .aes256CBC:
            return "AES-256-CBC"
        case .aes256GCM:
            return "AES-256-GCM"
        case .chacha20Poly1305:
            return "CHACHA20-POLY1305"
        }
    }
    
    /// Convert from string to EncryptionAlgorithm
    ///
    /// - Parameter string: String representation of the algorithm
    /// - Returns: EncryptionAlgorithm or nil if conversion fails
    public static func toAlgorithm(from string: String) -> EncryptionAlgorithm? {
        switch string.uppercased() {
        case "AES-256-CBC", "AES256CBC": 
            return .aes256CBC
        case "AES-256-GCM", "AES256GCM":
            return .aes256GCM
        case "CHACHA20-POLY1305", "CHACHA20POLY1305":
            return .chacha20Poly1305
        default:
            return nil
        }
    }
    
    // MARK: - Data Conversions
    
    /// Convert from Data to [UInt8]
    ///
    /// - Parameter data: The Data to convert
    /// - Returns: Byte array representation
    public static func toByteArray(from data: Data) -> [UInt8] {
        return [UInt8](data)
    }
    
    /// Convert from [UInt8] to Data
    ///
    /// - Parameter bytes: The byte array to convert
    /// - Returns: Data representation
    public static func toData(from bytes: [UInt8]) -> Data {
        return Data(bytes)
    }
    
    /// Extract a slice from a byte array
    ///
    /// - Parameters:
    ///   - array: The source array
    ///   - range: The range to extract
    /// - Returns: A new byte array containing the extracted elements
    public static func extractSlice(from array: [UInt8], range: Range<Int>) -> [UInt8] {
        return Array(array[range])
    }
    
    /// Extract a slice from a byte array to the end
    ///
    /// - Parameters:
    ///   - array: The source array
    ///   - startIndex: The starting index for extraction
    /// - Returns: A new byte array containing the extracted elements
    public static func extractSliceToEnd(from array: [UInt8], startIndex: Int) -> [UInt8] {
        guard startIndex < array.count else { return [] }
        return Array(array[startIndex...])
    }
}
