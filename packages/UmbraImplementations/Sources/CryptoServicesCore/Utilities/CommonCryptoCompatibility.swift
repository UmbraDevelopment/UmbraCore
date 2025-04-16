import Foundation

/// CommonCrypto GCM Compatibility Layer
///
/// This file provides definitions for GCM-related constants and functions
/// that may not be available in all versions of CommonCrypto.
/// It allows us to use GCM mode encryption while maintaining compatibility
/// with older platforms.
#if canImport(CommonCrypto)
import CommonCrypto

// Add missing GCM constants if not already defined
#if !kCCModeGCM
public let kCCModeGCM: CCMode = 11
#endif

/// Adding Additional Authenticated Data for GCM mode
///
/// CCCryptorGCMAddAAD provides AAD for GCM mode operations
@_silgen_name("CCCryptorGCMAddAAD")
public func _CCCryptorGCMAddAAD(
    _ cryptorRef: CCCryptorRef,
    _ additionalData: UnsafeRawPointer,
    _ additionalDataLength: Int
) -> CCCryptorStatus

/// Get the GCM tag and finalize the encryption/decryption
///
/// CCCryptorGCMFinalize provides the tag for GCM mode operations
@_silgen_name("CCCryptorGCMFinalize")
public func _CCCryptorGCMFinalize(
    _ cryptorRef: CCCryptorRef,
    _ tag: UnsafeMutableRawPointer,
    _ tagLength: Int
) -> CCCryptorStatus

/// GCM Helper Function - Safe pointer wrapper for CCCryptorGCMAddAAD
///
/// This function safely handles the pointer management for the CCCryptorGCMAddAAD call
public func CCCryptorGCMAddAAD(
    _ cryptorRef: CCCryptorRef,
    _ additionalData: [UInt8],
    _ additionalDataLength: Int
) -> CCCryptorStatus {
    return additionalData.withUnsafeBytes { buffer in
        let baseAddress = buffer.baseAddress!
        return _CCCryptorGCMAddAAD(cryptorRef, baseAddress, additionalDataLength)
    }
}

/// GCM Helper Function - Safe pointer wrapper for CCCryptorGCMFinalize
///
/// This function safely handles the pointer management for the CCCryptorGCMFinalize call
public func CCCryptorGCMFinalize(
    _ cryptorRef: CCCryptorRef,
    _ tag: inout [UInt8],
    _ tagLength: Int
) -> CCCryptorStatus {
    return tag.withUnsafeMutableBytes { buffer in
        let baseAddress = buffer.baseAddress!
        return _CCCryptorGCMFinalize(cryptorRef, baseAddress, tagLength)
    }
}

/// GCM Helper - CCCryptorGCMFinal alias for naming consistency
///
/// Alias for CCCryptorGCMFinalize to match expected function name
public func CCCryptorGCMFinal(
    _ cryptorRef: CCCryptorRef,
    _ tag: inout [UInt8],
    _ tagLength: Int
) -> CCCryptorStatus {
    return CCCryptorGCMFinalize(cryptorRef, &tag, tagLength)
}

// Add missing padding constant if not defined
#if !ccNoPadding
public let ccNoPadding: CCPadding = 3
#endif

#endif // canImport(CommonCrypto)
