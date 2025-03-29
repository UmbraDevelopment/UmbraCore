/// A string with associated privacy annotation
///
/// This type helps maintain privacy context for strings that may contain
/// sensitive information, allowing the logging system to properly
/// handle redaction based on privacy requirements.
public struct PrivacyAnnotatedString: Sendable, Hashable {
    /// The actual string content
    public let content: String
    
    /// The privacy level for this string
    public let privacy: LogPrivacy
    
    /// Initialise a new privacy-annotated string
    /// - Parameters:
    ///   - content: The string content
    ///   - privacy: The privacy level (defaults to .auto)
    public init(_ content: String, privacy: LogPrivacy = .auto) {
        self.content = content
        self.privacy = privacy
    }
    
    /// Create a public privacy-annotated string
    /// - Parameter content: The string content
    /// - Returns: A privacy-annotated string with public privacy
    public static func publicString(_ content: String) -> PrivacyAnnotatedString {
        PrivacyAnnotatedString(content, privacy: .public)
    }
    
    /// Create a private privacy-annotated string
    /// - Parameter content: The string content
    /// - Returns: A privacy-annotated string with private privacy
    public static func privateString(_ content: String) -> PrivacyAnnotatedString {
        PrivacyAnnotatedString(content, privacy: .private)
    }
    
    /// Create a sensitive privacy-annotated string
    /// - Parameter content: The string content
    /// - Returns: A privacy-annotated string with sensitive privacy
    public static func sensitiveString(_ content: String) -> PrivacyAnnotatedString {
        PrivacyAnnotatedString(content, privacy: .sensitive)
    }
}
