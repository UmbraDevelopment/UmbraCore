import CryptoInterfaces
import Foundation
import LoggingInterfaces

/**
 Enhanced log context for crypto operations with privacy controls
 */
public struct EnhancedLogContext: LogContextDTO {
  /// Domain name for the log context
  public let domainName: String
  
  /// Operation name 
  public let operationName: String
  
  /// Additional context metadata as key-value pairs
  public let metadata: [String: String]
  
  /// Privacy level for each metadata field
  public let privacyLevels: [String: PrivacyClassification]
  
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
   Get metadata collection to use with loggers
   
   - Returns: A metadata collection with privacy annotations
   */
  public func getMetadataCollection() -> LogMetadataDTOCollection {
    let collection = LogMetadataDTOCollection()
    
    for (key, value) in metadata {
      let privacy = privacyLevel(for: key)
      
      switch privacy {
      case .private:
        _ = collection.withPrivate(key: key, value: value)
      case .public:
        _ = collection.withPublic(key: key, value: value)
      case .sensitive:
        _ = collection.withSensitive(key: key, value: value)
      case .auto:
        _ = collection.withPublic(key: key, value: value)
      }
    }
    
    return collection
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
