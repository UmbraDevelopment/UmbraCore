/// Represents privacy annotations for log entries
///
/// This type provides a Foundation-independent way to specify privacy
/// settings for log entries, which will be mapped to appropriate OSLogPrivacy
/// values when using OSLog destinations.
///
/// Privacy controls help protect sensitive data in logs while ensuring
/// that debugging information remains useful.
@frozen
public enum LogPrivacy: Sendable, Hashable, Equatable, CustomStringConvertible {
    /// Information can be freely viewed
    ///
    /// Equivalent to OSLogPrivacy.public
    case `public`
    
    /// Information is private but can be viewed for debugging
    ///
    /// Equivalent to OSLogPrivacy.private
    case `private`
    
    /// Information is sensitive and redacted in released versions
    ///
    /// Equivalent to OSLogPrivacy.sensitive
    case sensitive
    
    /// Information is auto-redacted by the logging system
    ///
    /// Equivalent to OSLogPrivacy.auto
    case auto
    
    /// String representation of the privacy level
    public var description: String {
        switch self {
        case .public:
            return "public"
        case .private:
            return "private"
        case .sensitive:
            return "sensitive"
        case .auto:
            return "auto"
        }
    }
}
