import Foundation

/// Extension to convert from LogPrivacyLevel to PrivacyClassification
///
/// This addresses the need for bidirectional conversion between the privacy
/// level types used in the Alpha Dot Five architecture.
extension LogPrivacyLevel {
    /// Convert to PrivacyClassification
    ///
    /// Maps each LogPrivacyLevel to the corresponding PrivacyClassification,
    /// ensuring consistent handling of privacy levels throughout the system.
    ///
    /// - Returns: The equivalent PrivacyClassification
    public func toPrivacyClassification() -> PrivacyClassification {
        switch self {
        case .public:
            return .public
        case .private:
            return .private
        case .sensitive:
            return .sensitive
        case .hash:
            return .hash
        case .auto:
            return .auto
        }
    }
}

/// Extension to add compatibility for protected, never cases to LogPrivacyLevel
///
/// This extension addresses the presence of `.protected` and `.never` in code
/// that was written against the older PrivacyLevel enum, providing compatibility
/// for those cases.
extension LogPrivacyLevel {
    /// Equivalent to private level, provided for backward compatibility
    public static var protected: LogPrivacyLevel {
        return .private
    }
    
    /// Maps to public level, provided for backward compatibility
    public static var never: LogPrivacyLevel {
        return .public
    }
}
