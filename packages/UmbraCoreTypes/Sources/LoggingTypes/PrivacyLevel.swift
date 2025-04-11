import Foundation

/// Privacy level for log metadata and content
///
/// Used to control how data is exposed in logs, particularly in production environments.
public enum PrivacyLevel: String, Sendable, Equatable, Hashable, CaseIterable, Codable {
    /// Public data that can be logged freely
    case `public`
    
    /// Protected data with minimal sensitivity
    case protected
    
    /// Private data that should be masked or redacted in most environments
    case `private`
    
    /// Sensitive data that should be strictly controlled
    case sensitive
    
    /// Data that should be hashed before logging
    case hash
    
    /// Data that should never be logged
    case never
    
    /// Automatically determine privacy level based on content patterns
    case auto
}
