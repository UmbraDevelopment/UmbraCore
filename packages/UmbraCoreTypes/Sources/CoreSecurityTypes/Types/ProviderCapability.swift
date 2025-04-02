import Foundation

/**
 Defines the capabilities that security providers can support.
 
 These capabilities are used for provider selection and configuration
 to ensure that the chosen provider meets the security requirements.
 */
public enum ProviderCapability: String, CaseIterable, Sendable {
    /// Standard encryption operations
    case standardEncryption
    
    /// FIPS compliant operations
    case fipsCompliant
    
    /// High-performance optimisations
    case highPerformance
    
    /// Low-power optimisations
    case lowPower
}
