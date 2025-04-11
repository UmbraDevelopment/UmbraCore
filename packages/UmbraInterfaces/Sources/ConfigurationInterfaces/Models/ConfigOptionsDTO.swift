import Foundation

/**
 Options for loading configuration.
 
 Controls how configuration is loaded from a source.
 */
public struct ConfigLoadOptionsDTO: Codable, Equatable, Sendable {
    /// Whether to reload even if already loaded
    public let forceReload: Bool
    
    /// Additional sources to try if primary source fails
    public let fallbackSources: [ConfigSourceDTO]
    
    /// Whether to merge with existing configuration
    public let merge: Bool
    
    /// How to handle conflicts when merging
    public let mergeStrategy: MergeStrategy
    
    /// Whether to cache the loaded configuration
    public let enableCaching: Bool
    
    /// How to handle environment-specific overrides
    public let environmentOverrides: EnvironmentHandling
    
    /**
     Strategy for merging configurations.
     */
    public enum MergeStrategy: String, Codable, Sendable {
        /// New values override existing values
        case override
        /// Keep existing values if they exist
        case keepExisting
        /// Recursively merge nested objects
        case deepMerge
    }
    
    /**
     How to handle environment-specific configuration.
     */
    public enum EnvironmentHandling: String, Codable, Sendable {
        /// Apply environment overrides
        case apply
        /// Ignore environment overrides
        case ignore
        /// Only load environment-specific configuration
        case environmentOnly
    }
    
    /**
     Initialises configuration load options.
     
     - Parameters:
        - forceReload: Whether to reload even if already loaded
        - fallbackSources: Additional sources to try if primary source fails
        - merge: Whether to merge with existing configuration
        - mergeStrategy: How to handle conflicts when merging
        - enableCaching: Whether to cache the loaded configuration
        - environmentOverrides: How to handle environment-specific overrides
     */
    public init(
        forceReload: Bool = false,
        fallbackSources: [ConfigSourceDTO] = [],
        merge: Bool = true,
        mergeStrategy: MergeStrategy = .override,
        enableCaching: Bool = true,
        environmentOverrides: EnvironmentHandling = .apply
    ) {
        self.forceReload = forceReload
        self.fallbackSources = fallbackSources
        self.merge = merge
        self.mergeStrategy = mergeStrategy
        self.enableCaching = enableCaching
        self.environmentOverrides = environmentOverrides
    }
    
    /// Default load options
    public static let `default` = ConfigLoadOptionsDTO()
}

/**
 Options for saving configuration.
 
 Controls how configuration is saved to a destination.
 */
public struct ConfigSaveOptionsDTO: Codable, Equatable, Sendable {
    /// Whether to create backup of existing configuration
    public let createBackup: Bool
    
    /// Whether to pretty-print/format the output
    public let prettyPrint: Bool
    
    /// Whether to encrypt sensitive values
    public let encryptSensitiveValues: Bool
    
    /// Whether to validate before saving
    public let validateBeforeSaving: Bool
    
    /// Sections or keys to exclude when saving
    public let excludeSections: [String]
    
    /**
     Initialises configuration save options.
     
     - Parameters:
        - createBackup: Whether to create backup of existing configuration
        - prettyPrint: Whether to pretty-print/format the output
        - encryptSensitiveValues: Whether to encrypt sensitive values
        - validateBeforeSaving: Whether to validate before saving
        - excludeSections: Sections or keys to exclude when saving
     */
    public init(
        createBackup: Bool = true,
        prettyPrint: Bool = true,
        encryptSensitiveValues: Bool = true,
        validateBeforeSaving: Bool = true,
        excludeSections: [String] = []
    ) {
        self.createBackup = createBackup
        self.prettyPrint = prettyPrint
        self.encryptSensitiveValues = encryptSensitiveValues
        self.validateBeforeSaving = validateBeforeSaving
        self.excludeSections = excludeSections
    }
    
    /// Default save options
    public static let `default` = ConfigSaveOptionsDTO()
}

/**
 Options for updating configuration.
 
 Controls how updates are applied to configuration.
 */
public struct ConfigUpdateOptionsDTO: Codable, Equatable, Sendable {
    /// Whether to validate after update
    public let validateAfterUpdate: Bool
    
    /// Whether to save after update
    public let saveAfterUpdate: Bool
    
    /// Destination to save to after update
    public let saveDestination: ConfigSourceDTO?
    
    /// Whether to notify observers of changes
    public let notifyObservers: Bool
    
    /// Whether to create an update history entry
    public let trackHistory: Bool
    
    /**
     Initialises configuration update options.
     
     - Parameters:
        - validateAfterUpdate: Whether to validate after update
        - saveAfterUpdate: Whether to save after update
        - saveDestination: Destination to save to after update
        - notifyObservers: Whether to notify observers of changes
        - trackHistory: Whether to create an update history entry
     */
    public init(
        validateAfterUpdate: Bool = true,
        saveAfterUpdate: Bool = true,
        saveDestination: ConfigSourceDTO? = nil,
        notifyObservers: Bool = true,
        trackHistory: Bool = true
    ) {
        self.validateAfterUpdate = validateAfterUpdate
        self.saveAfterUpdate = saveAfterUpdate
        self.saveDestination = saveDestination
        self.notifyObservers = notifyObservers
        self.trackHistory = trackHistory
    }
    
    /// Default update options
    public static let `default` = ConfigUpdateOptionsDTO()
}

/**
 Options for exporting configuration.
 
 Controls how configuration is exported to a specific format.
 */
public struct ConfigExportOptionsDTO: Codable, Equatable, Sendable {
    /// Whether to pretty-print/format the output
    public let prettyPrint: Bool
    
    /// Whether to include metadata
    public let includeMetadata: Bool
    
    /// Whether to encrypt sensitive values
    public let encryptSensitiveValues: Bool
    
    /// Sections or keys to exclude when exporting
    public let excludeSections: [String]
    
    /// Format-specific options
    public let formatOptions: [String: String]
    
    /**
     Initialises configuration export options.
     
     - Parameters:
        - prettyPrint: Whether to pretty-print/format the output
        - includeMetadata: Whether to include metadata
        - encryptSensitiveValues: Whether to encrypt sensitive values
        - excludeSections: Sections or keys to exclude when exporting
        - formatOptions: Format-specific options
     */
    public init(
        prettyPrint: Bool = true,
        includeMetadata: Bool = true,
        encryptSensitiveValues: Bool = true,
        excludeSections: [String] = [],
        formatOptions: [String: String] = [:]
    ) {
        self.prettyPrint = prettyPrint
        self.includeMetadata = includeMetadata
        self.encryptSensitiveValues = encryptSensitiveValues
        self.excludeSections = excludeSections
        self.formatOptions = formatOptions
    }
    
    /// Default export options
    public static let `default` = ConfigExportOptionsDTO()
}

/**
 Options for importing configuration.
 
 Controls how configuration is imported from external data.
 */
public struct ConfigImportOptionsDTO: Codable, Equatable, Sendable {
    /// Whether to validate imported configuration
    public let validateAfterImport: Bool
    
    /// Whether to merge with existing configuration
    public let merge: Bool
    
    /// How to handle conflicts when merging
    public let mergeStrategy: ConfigLoadOptionsDTO.MergeStrategy
    
    /// Whether to set as active configuration
    public let setActive: Bool
    
    /// Whether to save imported configuration
    public let saveAfterImport: Bool
    
    /// Destination to save to after import
    public let saveDestination: ConfigSourceDTO?
    
    /**
     Initialises configuration import options.
     
     - Parameters:
        - validateAfterImport: Whether to validate imported configuration
        - merge: Whether to merge with existing configuration
        - mergeStrategy: How to handle conflicts when merging
        - setActive: Whether to set as active configuration
        - saveAfterImport: Whether to save imported configuration
        - saveDestination: Destination to save to after import
     */
    public init(
        validateAfterImport: Bool = true,
        merge: Bool = false,
        mergeStrategy: ConfigLoadOptionsDTO.MergeStrategy = .override,
        setActive: Bool = true,
        saveAfterImport: Bool = false,
        saveDestination: ConfigSourceDTO? = nil
    ) {
        self.validateAfterImport = validateAfterImport
        self.merge = merge
        self.mergeStrategy = mergeStrategy
        self.setActive = setActive
        self.saveAfterImport = saveAfterImport
        self.saveDestination = saveDestination
    }
    
    /// Default import options
    public static let `default` = ConfigImportOptionsDTO()
}

/**
 Options for activating a configuration.
 
 Controls how configuration is set as active.
 */
public struct ConfigActivateOptionsDTO: Codable, Equatable, Sendable {
    /// Whether to validate before activating
    public let validateBeforeActivating: Bool
    
    /// Whether to notify observers of changes
    public let notifyObservers: Bool
    
    /// Whether to save active configuration
    public let saveActiveConfiguration: Bool
    
    /// Destination to save active configuration
    public let saveDestination: ConfigSourceDTO?
    
    /**
     Initialises configuration activation options.
     
     - Parameters:
        - validateBeforeActivating: Whether to validate before activating
        - notifyObservers: Whether to notify observers of changes
        - saveActiveConfiguration: Whether to save active configuration
        - saveDestination: Destination to save active configuration
     */
    public init(
        validateBeforeActivating: Bool = true,
        notifyObservers: Bool = true,
        saveActiveConfiguration: Bool = false,
        saveDestination: ConfigSourceDTO? = nil
    ) {
        self.validateBeforeActivating = validateBeforeActivating
        self.notifyObservers = notifyObservers
        self.saveActiveConfiguration = saveActiveConfiguration
        self.saveDestination = saveDestination
    }
    
    /// Default activation options
    public static let `default` = ConfigActivateOptionsDTO()
}
