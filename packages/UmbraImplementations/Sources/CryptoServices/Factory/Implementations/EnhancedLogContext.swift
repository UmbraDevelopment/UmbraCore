import CryptoInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Enhanced log context for crypto operations with privacy controls
 */
public struct EnhancedLogContext: LogContextDTO {
  /// Domain name for the log context
  public let domainName: String
  
  /// Operation name 
  public let operationName: String
  
  /// Additional context metadata as key-value pairs
  public private(set) var metadata: [String: String]
  
  /// Privacy level for each metadata field
  public private(set) var privacyLevels: [String: PrivacyClassification]
  
  /**
   Initialize a new enhanced log context
   
   - Parameters:
     - domainName: The domain name for this context
     - operationName: The operation name
     - metadata: Additional metadata as key-value pairs
     - privacyLevels: Privacy levels for each metadata field
   */
  public init(
    domainName: String,
    operationName: String,
    metadata: [String: String] = [:],
    privacyLevels: [String: PrivacyClassification] = [:]
  ) {
    self.domainName = domainName
    self.operationName = operationName
    self.metadata = metadata
    self.privacyLevels = privacyLevels
  }
  
  /**
   Get the privacy level for a specific metadata key
   
   - Parameter key: The metadata key
   - Returns: The privacy level, or .auto if not specified
   */
  public func privacyLevel(for key: String) -> PrivacyClassification {
    return privacyLevels[key] ?? .auto
  }
  
  /**
   Updates metadata values with new values
   
   - Parameter metadataUpdates: Dictionary of metadata updates with privacy annotations
   */
  public mutating func updateMetadata(_ metadataUpdates: [String: PrivacyLevel]) {
    for (key, privacyValue) in metadataUpdates {
      switch privacyValue {
      case let .public(value):
        metadata[key] = value
        privacyLevels[key] = .public
      case let .private(value):
        metadata[key] = value
        privacyLevels[key] = .private
      case let .hash(value):
        metadata[key] = value
        privacyLevels[key] = .hash
      }
    }
  }
  
  /**
   Get metadata collection to use with loggers
   
   - Returns: A metadata collection with privacy annotations
   */
  public func createMetadataCollection() -> LogMetadataDTOCollection {
    var collection = LogMetadataDTOCollection()
    
    for (key, value) in metadata {
      let privacy = privacyLevel(for: key)
      
      switch privacy {
      case .private:
        collection = collection.withPrivate(key: key, value: value)
      case .public:
        collection = collection.withPublic(key: key, value: value)
      case .sensitive:
        collection = collection.withSensitive(key: key, value: value)
      case .hash:
        collection = collection.withHashed(key: key, value: value)
      case .auto:
        collection = collection.withAuto(key: key, value: value)
      }
    }
    
    return collection
  }
  
  /**
   @deprecated Use createMetadataCollection() instead.
   */
  public func getMetadataCollection() -> LogMetadataDTOCollection {
    return createMetadataCollection()
  }
}

/**
 Privacy level for logging sensitive information.
 */
public enum PrivacyLevel {
  /// Public information that can be logged in plain text
  case `public`(String)

  /// Private information that should be redacted in logs
  case `private`(String)

  /// Information that should be hashed in logs
  case hash(String)
}
