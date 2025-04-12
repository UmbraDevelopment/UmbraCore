import Foundation

/**
 Result of saving configuration.
 
 Contains information about the save operation result.
 */
public struct ConfigSaveResultDTO: Codable, Equatable, Sendable {
    /// Whether the save operation was successful
    public let success: Bool
    
    /// Path or identifier where configuration was saved
    public let savedLocation: String
    
    /// Timestamp when the save occurred
    public let timestamp: Date
    
    /// Additional result metadata
    public let metadata: [String: String]
    
    /**
     Initialises a configuration save result.
     
     - Parameters:
        - success: Whether the save operation was successful
        - savedLocation: Path or identifier where configuration was saved
        - timestamp: Timestamp when the save occurred
        - metadata: Additional result metadata
     */
    public init(
        success: Bool,
        savedLocation: String,
        timestamp: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.success = success
        self.savedLocation = savedLocation
        self.timestamp = timestamp
        self.metadata = metadata
    }
    
    /// Returns a successful save result
    public static func success(location: String) -> ConfigSaveResultDTO {
        return ConfigSaveResultDTO(success: true, savedLocation: location)
    }
    
    /// Returns a failed save result
    public static func failure(location: String, reason: String) -> ConfigSaveResultDTO {
        return ConfigSaveResultDTO(
            success: false,
            savedLocation: location,
            metadata: ["error": reason]
        )
    }
}
