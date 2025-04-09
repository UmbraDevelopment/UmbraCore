import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # Privacy-Aware Log DTO

 A Data Transfer Object for privacy-aware logging that conforms to the LogContextDTO protocol.
 This DTO provides a structured way to handle privacy classifications and sensitive data
 in accordance with the Alpha Dot Five architecture principles.

 ## Features

 - Structured privacy metadata with clear classifications
 - Support for different privacy levels (public, private, sensitive, hash)
 - Conversion utilities to bridge between different logging interfaces
 - Immutable design for thread safety

 ## Usage Examples

 ### Basic Usage

 ```swift
 // Create a simple log context
 let context = PrivacyAwareLogDTO(
     source: "UserService",
     domainName: "Authentication"
 )

 // Log with the context
 await logger.info("User login attempt", context: context)
 ```

 ### With Privacy Metadata

 ```swift
 // Create a context with privacy-classified metadata
 let context = PrivacyAwareLogDTO(
     source: "PaymentService",
     domainName: "Transactions",
     metadata: [
         "transaction_id": (value: transactionId, privacy: .public),
         "amount": (value: amount, privacy: .public),
         "card_number": (value: cardNumber, privacy: .sensitive),
         "user_id": (value: userId, privacy: .private)
     ]
 )

 // Log with the context
 await logger.info("Payment processed", context: context)
 ```

 ### Adding Additional Metadata

 ```swift
 // Add additional metadata to an existing context
 let enhancedContext = existingContext.with(metadata: [
     "error_code": (value: errorCode, privacy: .public),
     "stack_trace": (value: stackTrace, privacy: .private)
 ])

 // Log with the enhanced context
 await logger.error("Operation failed", context: enhancedContext)
 ```
 */
public struct PrivacyAwareLogDTO: LogContextDTO, Sendable {
  /// The source of the log (e.g., class, file, function)
  public let source: String?

  /// Domain name for the log context
  public let domainName: String

  /// Correlation ID for tracking related logs
  public let correlationID: String?

  /// Privacy-aware metadata collection
  public let metadata: LoggingTypes.LogMetadataDTOCollection

  /// The deployment environment
  private let environment: LoggingTypes.DeploymentEnvironment

  /**
   Initializes a new privacy-aware log DTO.

   This initializer creates a new DTO with the specified parameters. The metadata
   dictionary allows for attaching privacy-classified data to the log context.

   - Parameters:
     - source: The source of the log, typically the class or component name
     - domainName: The domain name for the log context, used for filtering and categorization
     - correlationID: Optional correlation ID for tracking related logs across services
     - metadata: Dictionary of metadata with privacy classifications for each value
     - environment: The deployment environment, which affects how privacy controls are applied

   ## Example

   ```swift
   let context = PrivacyAwareLogDTO(
       source: "AuthenticationService",
       domainName: "Security",
       correlationID: requestID,
       metadata: [
           "user_id": (value: userId, privacy: .private),
           "ip_address": (value: ipAddress, privacy: .sensitive)
       ],
       environment: .production
   )
   */
  public init(
    source: String?=nil,
    domainName: String="UmbraCore",
    correlationID: String?=nil,
    metadata: [String: (value: Any, privacy: LogPrivacyLevel)]=[:],
    environment: LoggingTypes.DeploymentEnvironment = .development
  ) {
    self.source=source
    self.domainName=domainName
    self.correlationID=correlationID
    self.environment=environment
    self.metadata=PrivacyAwareLogDTO.createMetadataCollection(from: metadata)
  }

  /**
   Creates a new DTO with additional metadata.

   This method allows for adding or overriding metadata in the current context
   without modifying the original instance, maintaining immutability.

   - Parameter metadata: Additional metadata to add or override
   - Returns: A new DTO with the combined metadata

   ## Example

   ```swift
   let enhancedContext = baseContext.with(metadata: [
       "duration_ms": (value: operationDuration, privacy: .public),
       "result_code": (value: resultCode, privacy: .public)
   ])
   */
  public func with(metadata additionalMetadata: [String: (value: Any, privacy: LogPrivacyLevel)])
  -> PrivacyAwareLogDTO {
    let combinedMetadata=extractRawMetadata()

    // Add the additional metadata
    var updatedMetadata=combinedMetadata
    for (key, value) in additionalMetadata {
      updatedMetadata[key]=value
    }

    return PrivacyAwareLogDTO(
      source: source,
      domainName: domainName,
      correlationID: correlationID,
      metadata: updatedMetadata,
      environment: environment
    )
  }

  /**
   Creates a new DTO with a different source.

   This method allows for changing the source in the current context
   without modifying the original instance, maintaining immutability.

   - Parameter source: The new source
   - Returns: A new DTO with the updated source

   ## Example

   ```swift
   let childContext = parentContext.with(source: "PaymentProcessor.validateCard")
   */
  public func with(source: String?) -> PrivacyAwareLogDTO {
    PrivacyAwareLogDTO(
      source: source,
      domainName: domainName,
      correlationID: correlationID,
      metadata: extractRawMetadata(),
      environment: environment
    )
  }

  /**
   Extracts the raw metadata as a dictionary.

   This method converts the structured LogMetadataDTOCollection back to a raw dictionary
   format with privacy classifications, which can be useful for serialization or
   when combining metadata from different sources.

   - Returns: The metadata as a dictionary with privacy classifications
   */
  public func extractRawMetadata() -> [String: (value: Any, privacy: LogPrivacyLevel)] {
    var result: [String: (value: Any, privacy: LogPrivacyLevel)]=[:]

    // Extract metadata from LogMetadataDTOCollection
    for entry in metadata.entries {
      let privacyLevel: LogPrivacyLevel

        // Map PrivacyClassification to LogPrivacyLevel
        = switch entry.privacyLevel
      {
        case .public:
          .public
        case .private:
          .private
        case .sensitive:
          .sensitive
        // There's no direct hashed case in PrivacyClassification, so we'll handle it differently
        // For now, we'll map any other case to hash (though this shouldn't happen)
        default:
          .hash
      }

      result[entry.key]=(value: entry.value, privacy: privacyLevel)
    }

    return result
  }

  /**
   Creates a LogMetadataDTOCollection from a dictionary.

   This static method converts a raw metadata dictionary with privacy classifications
   into a structured LogMetadataDTOCollection, which is the format used by the
   logging system.

   - Parameter dict: The dictionary to convert
   - Returns: A LogMetadataDTOCollection
   */
  private static func createMetadataCollection(from dict: [String: (
    value: Any,
    privacy: LogPrivacyLevel
  )]) -> LoggingTypes.LogMetadataDTOCollection {
    var collection=LoggingTypes.LogMetadataDTOCollection()

    // Convert the dictionary to a LogMetadataDTOCollection
    for (key, value) in dict {
      switch value.privacy {
        case .public:
          collection=collection.withPublic(key: key, value: String(describing: value.value))
        case .private:
          collection=collection.withPrivate(key: key, value: String(describing: value.value))
        case .sensitive:
          collection=collection.withSensitive(key: key, value: String(describing: value.value))
        case .hash:
          collection=collection.withHashed(key: key, value: String(describing: value.value))
        case .auto:
          // For auto, default to private
          collection=collection.withPrivate(key: key, value: String(describing: value.value))
      }
    }

    return collection
  }

  /**
   Converts this DTO to a standard LogContext.

   This method provides compatibility with older APIs that expect a LogContext
   rather than a LogContextDTO.

   - Returns: A LogContext with the same data
   */
  public func toLogContext() -> LogContext {
    LogContext(
      source: source ?? "UmbraCore",
      metadata: metadata
    )
  }

  /**
   Gets the source of the log.

   - Returns: The source as a string
   */
  public func getSource() -> String {
    source ?? "UmbraCore"
  }

  /**
   Converts the metadata to PrivacyMetadata for compatibility with older APIs.

   - Returns: The metadata as PrivacyMetadata
   */
  public func toPrivacyMetadata() -> PrivacyMetadata {
    metadata.toPrivacyMetadata()
  }
}

/**
 A wrapper for privacy-tagged values to avoid conflicts with other PrivacyMetadataValue types.

 This struct provides a simple way to associate a value with a privacy classification,
 which is used when constructing metadata for logging.

 ## Example

 ```swift
 let value = PrivacyValueWrapper(value: "user@example.com", privacy: .sensitive)
 */
public struct PrivacyValueWrapper {
  /// The string value
  public let valueString: String

  /// The privacy classification
  public let privacyClassification: LogPrivacyLevel

  /**
   Initializes a new privacy metadata value.

   - Parameters:
     - value: The value as a string
     - privacy: The privacy classification
   */
  public init(value: String, privacy: LogPrivacyLevel) {
    valueString=value
    privacyClassification=privacy
  }
}
