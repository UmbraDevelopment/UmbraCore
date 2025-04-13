import CoreSecurityTypes
import Foundation

/**
 # CryptoServiceType
 
 This file maintains backward compatibility with the SecurityProviderType from CoreSecurityTypes.
 
 In the Alpha Dot Five architecture, we explicitly use SecurityProviderType instead of the
 legacy CryptoServiceType. This file maps between the two for transitional purposes.
 
 Developers must explicitly choose which implementation to use based on their
 requirements, rather than rely on automatic selection. Each type provides different
 features, compatibility, and security characteristics.
 
 ## Implementation Types
 
 - `basic`: Default implementation using AES encryption, for general use cases.
 
 - `ring`: Implementation using Ring cryptography library.
   Features cross-platform compatibility and works in any environment.
 
 - `appleCryptoKit`: Apple-native implementation using CryptoKit.
   Optimised specifically for Apple platforms with hardware acceleration.
 
 - `platform`: Platform-specific implementation that selects the best
   provider for the current platform.
 */
@available(*, deprecated, message: "Use SecurityProviderType directly instead")
public enum CryptoServiceType: String, Sendable {
    /// Default implementation using AES for general use
    case standard
    
    /// Cross-platform implementation using Ring
    case crossPlatform
    
    /// Apple-specific implementation using CryptoKit
    case applePlatform
    
    /// Custom implementation
    case custom
    
    /// Platform-specific implementation
    case platform
    
    /// Hardware security implementation
    case hardwareSecurity
    
    /**
     Maps the legacy service type to the corresponding SecurityProviderType
     in the Alpha Dot Five architecture.
     */
    public var securityProviderType: SecurityProviderType {
        switch self {
        case .standard:
            return .basic
        case .crossPlatform:
            return .ring
        case .applePlatform:
            return .appleCryptoKit
        case .custom:
            return .custom
        case .platform:
            return .platform
        case .hardwareSecurity:
            return .hsm
        }
    }
    
    /**
     Initialize a CryptoServiceType from a SecurityProviderType.
     
     This is for backward compatibility during the transition.
     
     - Parameter providerType: The provider type to convert
     */
    public init(fromSecurityProviderType providerType: SecurityProviderType) {
        switch providerType {
        case .basic:
            self = .standard
        case .custom:
            self = .custom
        case .platform:
            self = .platform
        case .appleCryptoKit:
            self = .applePlatform
        case .ring:
            self = .crossPlatform
        case .cryptoKit:
            self = .applePlatform // Map to platform as it's the closest Apple-specific option
        case .system:
            self = .standard // Map to standard as fallback
        case .hsm:
            self = .hardwareSecurity // Map to hardware security
        @unknown default:
            self = .standard // Fallback to standard for any future additions
        }
    }
}
