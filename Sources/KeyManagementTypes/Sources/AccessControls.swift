import Foundation

/// Access control settings for cryptographic keys
/// 
/// This type defines the access control settings that can be applied to
/// cryptographic keys within the UmbraCore system, determining how they
/// can be accessed and by whom.
public struct AccessControls: Sendable, Codable, Equatable {
    /// The required authentication level to access this key
    public let requiredAuthentication: AuthenticationLevel
    
    /// Indicates whether additional approval is required for key usage
    public let requiresApproval: Bool
    
    /// Optional time-based restrictions on key usage
    public let timeRestrictions: TimeRestrictions?
    
    /// Users or roles authorized to access this key
    public let authorizedEntities: [AuthorizedEntity]
    
    /// A default instance with no access controls
    public static let none = AccessControls(
        requiredAuthentication: .standard,
        requiresApproval: false,
        timeRestrictions: nil,
        authorizedEntities: []
    )
    
    /// Creates a new AccessControls instance
    /// - Parameters:
    ///   - requiredAuthentication: The minimum authentication level required
    ///   - requiresApproval: Whether additional approval is needed for key usage
    ///   - timeRestrictions: Optional time-based restrictions
    ///   - authorizedEntities: Users or roles authorized to access the key
    public init(
        requiredAuthentication: AuthenticationLevel = .standard,
        requiresApproval: Bool = false,
        timeRestrictions: TimeRestrictions? = nil,
        authorizedEntities: [AuthorizedEntity] = []
    ) {
        self.requiredAuthentication = requiredAuthentication
        self.requiresApproval = requiresApproval
        self.timeRestrictions = timeRestrictions
        self.authorizedEntities = authorizedEntities
    }
    
    // Implement Equatable manually
    public static func == (lhs: AccessControls, rhs: AccessControls) -> Bool {
        return lhs.requiredAuthentication == rhs.requiredAuthentication &&
            lhs.requiresApproval == rhs.requiresApproval &&
            lhs.timeRestrictions == rhs.timeRestrictions &&
            lhs.authorizedEntities == rhs.authorizedEntities
    }
}

/// Authentication levels required for key access
public enum AuthenticationLevel: String, Codable, Equatable, CaseIterable, Sendable {
    /// Standard authentication (e.g., password)
    case standard
    
    /// Multi-factor authentication required
    case multiFactorAuthentication
    
    /// High security authentication (e.g., hardware token + password)
    case highSecurity
}

/// Time-based restrictions for key usage
public struct TimeRestrictions: Sendable, Codable, Equatable {
    /// The start time when the key can be used
    public let validFrom: Date?
    
    /// The end time after which the key cannot be used
    public let validUntil: Date?
    
    /// Days of the week when the key can be used
    public let allowedDays: [Weekday]?
    
    /// Hours of the day when the key can be used (in 24-hour format)
    public let allowedHours: ClosedRange<Int>?
    
    /// Creates a new TimeRestrictions instance
    /// - Parameters:
    ///   - validFrom: Optional start date for validity
    ///   - validUntil: Optional end date for validity
    ///   - allowedDays: Optional allowed days of the week
    ///   - allowedHours: Optional allowed hours range (e.g., 9...17 for 9am-5pm)
    public init(
        validFrom: Date? = nil,
        validUntil: Date? = nil,
        allowedDays: [Weekday]? = nil,
        allowedHours: ClosedRange<Int>? = nil
    ) {
        self.validFrom = validFrom
        self.validUntil = validUntil
        self.allowedDays = allowedDays
        self.allowedHours = allowedHours
    }
    
    // Implement Equatable manually
    public static func == (lhs: TimeRestrictions, rhs: TimeRestrictions) -> Bool {
        return lhs.validFrom == rhs.validFrom &&
            lhs.validUntil == rhs.validUntil &&
            lhs.allowedDays == rhs.allowedDays &&
            lhs.allowedHours?.lowerBound == rhs.allowedHours?.lowerBound &&
            lhs.allowedHours?.upperBound == rhs.allowedHours?.upperBound
    }
    
    // Custom Codable implementation for ClosedRange<Int>
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        validFrom = try container.decodeIfPresent(Date.self, forKey: .validFrom)
        validUntil = try container.decodeIfPresent(Date.self, forKey: .validUntil)
        allowedDays = try container.decodeIfPresent([Weekday].self, forKey: .allowedDays)
        
        if let lowerBound = try container.decodeIfPresent(Int.self, forKey: .hoursLowerBound),
           let upperBound = try container.decodeIfPresent(Int.self, forKey: .hoursUpperBound) {
            allowedHours = lowerBound...upperBound
        } else {
            allowedHours = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(validFrom, forKey: .validFrom)
        try container.encodeIfPresent(validUntil, forKey: .validUntil)
        try container.encodeIfPresent(allowedDays, forKey: .allowedDays)
        
        if let hours = allowedHours {
            try container.encode(hours.lowerBound, forKey: .hoursLowerBound)
            try container.encode(hours.upperBound, forKey: .hoursUpperBound)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case validFrom
        case validUntil
        case allowedDays
        case hoursLowerBound
        case hoursUpperBound
    }
}

/// Days of the week for time restrictions
public enum Weekday: Int, Codable, Equatable, CaseIterable, Sendable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
}

/// Entity authorized to access a key
public struct AuthorizedEntity: Sendable, Codable, Equatable {
    /// Type of the authorized entity
    public let type: EntityType
    
    /// Identifier for the entity
    public let identifier: String
    
    /// Creates a new AuthorizedEntity instance
    /// - Parameters:
    ///   - type: The type of entity (user, role, service)
    ///   - identifier: The unique identifier for the entity
    public init(type: EntityType, identifier: String) {
        self.type = type
        self.identifier = identifier
    }
}

/// Types of entities that can be authorized
public enum EntityType: String, Codable, Equatable, CaseIterable, Sendable {
    /// Individual user
    case user
    
    /// Role or group
    case role
    
    /// Service or application
    case service
}
