import BuildConfig
import Foundation

/**
 # CryptoServiceType
 
 Defines the available cryptographic service implementation types.
 
 Developers must explicitly choose which implementation to use based on their
 requirements, rather than rely on automatic selection. Each type provides different
 features, compatibility, and security characteristics.
 
 ## Implementation Types
 
 - `standard`: Default implementation using AES encryption, standard privacy controls,
   and standard logging. Best for general use cases with Restic integration.
 
 - `crossPlatform`: Implementation using RingFFI cryptography library with Argon2id.
   Features strict privacy controls and works in any environment (Apple, Windows,
   Linux). Optimised for cross-platform compatibility.
 
 - `applePlatform`: Apple-native implementation using CryptoKit, with strict macOS
   sandboxing. Optimised specifically for Apple platforms with hardware acceleration
   where available.
 */
public enum CryptoServiceType: String, Sendable {
    /// Default implementation using AES, standard privacy, for general use
    case standard
    
    /// Cross-platform implementation using RingFFI and Argon2id
    case crossPlatform
    
    /// Apple-specific implementation using CryptoKit
    case applePlatform
    
    /**
     Maps the service type to a corresponding backend strategy.
     
     This provides compatibility with the existing BuildConfig mechanism
     and ensures the appropriate backend is selected for each implementation.
     */
    public var backendStrategy: BackendStrategy {
        switch self {
        case .standard:
            return .restic
        case .crossPlatform:
            return .ringFFI
        case .applePlatform:
            return .appleCK
        }
    }
}
