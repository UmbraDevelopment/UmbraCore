import Foundation

/// Error domain namespace for internal use in the Mapping module
public enum ErrorDomain {
  /// Security domain
  public static let security = "Security"
  /// Crypto domain
  public static let crypto = "Crypto"
  /// Application domain
  public static let application = "Application"
  /// Network domain
  public static let network = "Network"
  /// Repository domain
  public static let repository = "Repository"
  /// Storage domain
  public static let storage = "Storage"
}

/// Error context protocol for internal use in the Mapping module
public protocol ErrorContext {
  /// Domain of the error
  var domain: String { get }
  /// Code of the error
  var code: Int { get }
  /// Description of the error
  var description: String { get }
}

/// Base error context implementation
public struct BaseErrorContext: ErrorContext {
  /// Domain of the error
  public let domain: String
  /// Code of the error
  public let code: Int
  /// Description of the error
  public let description: String

  /// Initialise with domain, code and description
  public init(domain: String, code: Int, description: String) {
    self.domain = domain
    self.code = code
    self.description = description
  }
}

/// Application error type for the error handling system
public enum ApplicationError: Error {
  /// Core application error
  case coreError(UmbraErrors.Application.Core)
  /// Lifecycle error
  case lifecycleError(UmbraErrors.Application.Lifecycle)
  /// Lifecycle error with reason
  case lifecycleError(reason: String)
  /// UI error
  case uiError(UmbraErrors.Application.UI)
  /// View error
  case viewError(reason: String)
  /// Rendering error
  case renderingError(reason: String)
  /// Launch error
  case launchError(reason: String)
  /// Configuration error
  case configurationError(reason: String)
  /// Invalid configuration
  case invalidConfiguration(reason: String)
  /// Plugin error
  case pluginError(reason: String)
  /// Permission error
  case permissionError(reason: String)
  /// Resource error
  case resourceError(reason: String)
  /// Resource not found
  case resourceNotFound(reason: String)
  /// Resource already exists
  case resourceAlreadyExists(reason: String)
  /// Operation cancelled
  case operationCancelled(reason: String)
  /// State error
  case stateError(reason: String)
  /// Settings error
  case settingsError(reason: String)
  /// Initialisation failed
  case initialisationFailed(reason: String)
  /// Resource missing
  case resourceMissing(resource: String)
  /// Operation timeout
  case operationTimeout(operation: String, durationMs: Int)
  /// Operation timeout with reason
  case operationTimeout(reason: String)
  /// Invalid state
  case invalidState(current: String, expected: String)
  /// Unknown error
  case unknown(reason: String)
  /// Internal error
  case internalError(reason: String)
}

/// Network error type for the error handling system
public enum NetworkError: Error {
  /// Connection failed
  case connectionFailed(reason: String)
  /// Host unreachable
  case hostUnreachable(host: String)
  /// Service unavailable
  case serviceUnavailable(service: String, reason: String)
  /// Request failed
  case requestFailed(statusCode: Int, reason: String)
  /// Invalid request
  case invalidRequest(reason: String)
  /// Request rejected
  case requestRejected(code: Int, reason: String)
  /// Response invalid
  case responseInvalid(reason: String)
  /// Invalid response
  case invalidResponse(reason: String)
  /// Parsing failed
  case parsingFailed(reason: String)
  /// Certificate error
  case certificateError(reason: String)
  /// Untrusted host
  case untrustedHost(hostname: String)
  /// Data corruption
  case dataCorruption(reason: String)
  /// Request too large
  case requestTooLarge(sizeByte: Int64, maxSizeByte: Int64)
  /// Response too large
  case responseTooLarge(sizeByte: Int64, maxSizeByte: Int64)
  /// Rate limit exceeded
  case rateLimitExceeded(limitPerHour: Int, retryAfterMs: Int)
  /// Timeout during operation
  case timeout(operation: String, durationMs: Int)
  /// Operation interrupted
  case interrupted(reason: String)
  /// Unknown error
  case unknown(reason: String)
  /// Internal error
  case internalError(reason: String)
}

/// Storage error type for the error handling system
public enum StorageError: Error {
  /// File not found
  case fileNotFound(path: String)
  /// Resource not found
  case resourceNotFound(path: String)
  /// Permission denied
  case permissionDenied(reason: String)
  /// Access denied
  case accessDenied(reason: String)
  /// Invalid format
  case invalidFormat(reason: String)
  /// Write failed
  case writeFailed(reason: String)
  /// Copy failed
  case copyFailed(source: String, destination: String, reason: String)
  /// Query failed
  case queryFailed(reason: String)
  /// Transaction failed
  case transactionFailed(reason: String)
  /// Disk full
  case diskFull(path: String, requiredBytes: Int64)
  /// Insufficient space
  case insufficientSpace(required: Int64, available: Int64)
  /// Database error
  case databaseError(code: Int, reason: String)
  /// Unknown error
  case unknown(reason: String)
  /// Internal error
  case internalError(reason: String)
}

/// Stub namespace for UmbraErrors to break circular dependencies
public enum UmbraErrors {
  /// Stub namespace for GeneralSecurity
  public enum GeneralSecurity {
    /// Stub for Core errors
    public enum Core: Error {
      /// Invalid input provided
      case invalidInput(reason: String)
      /// Failed to encrypt data
      case encryptionFailed(reason: String)
      /// Failed to decrypt data
      case decryptionFailed(reason: String)
      /// Failed to generate cryptographic key
      case keyGenerationFailed(reason: String)
      /// Failed to verify hash
      case hashVerificationFailed(reason: String)
      /// Invalid cryptographic key
      case invalidKey(reason: String)
      /// Operation timed out
      case timeout(operation: String)
      /// Service returned an error
      case serviceError(code: Int, reason: String)
      /// Internal error occurred
      case internalError(_ message: String)
    }
  }
  
  /// Stub namespace for Security
  public enum Security {
    /// Stub for Protocol errors
    public enum Protocols: Error {
      /// Unknown protocol error
      case unknown(reason: String)
    }
    
    /// Stub for XPC errors
    public enum XPC: Error {
      /// Connection failed
      case connectionFailed(reason: String)
      /// Service unavailable
      case serviceUnavailable(service: String, reason: String)
      /// Invalid message
      case invalidMessage(reason: String)
      /// Permission denied
      case permissionDenied(reason: String)
    }
  }
  
  /// Stub namespace for XPC
  public enum XPC {
    /// Stub for Core errors
    public enum Core: Error {
      /// Connection failed
      case connectionFailed(reason: String)
      /// Service unavailable
      case serviceUnavailable(service: String, reason: String)
      /// Invalid message
      case invalidMessage(reason: String)
      /// Permission denied
      case permissionDenied(reason: String)
    }
  }
  
  /// Stub namespace for Application
  public enum Application {
    /// Stub for Core errors
    public enum Core: Error {
      /// Generic application error
      case generic(reason: String)
    }
    
    /// Stub for Lifecycle errors
    public enum Lifecycle: Error {
      /// Launch error
      case launchError(reason: String)
    }
    
    /// Stub for UI errors
    public enum UI: Error {
      /// Generic UI error
      case generic(reason: String)
    }
  }
  
  /// Stub namespace for Network
  public enum Network {
    /// Stub for Core errors
    public enum Core: Error {
      /// Connection failed
      case connectionFailed(reason: String)
    }
    
    /// Stub for HTTP errors
    public enum HTTP: Error {
      /// HTTP error
      case badRequest(reason: String)
    }
  }
  
  /// Stub namespace for Storage
  public enum Storage {
    /// Stub for Database errors
    public enum Database: Error {
      /// Database error
      case connectionFailed(reason: String)
      /// Connection closed
      case connectionClosed(reason: String)
      /// Query failed
      case queryFailed(reason: String)
      /// Invalid data
      case invalidData(reason: String)
      /// Schema incompatible
      case schemaIncompatible(expected: String, found: String)
      /// Migration failed
      case migrationFailed(reason: String)
      /// Transaction failed
      case transactionFailed(reason: String)
      /// Constraint violation
      case constraintViolation(constraint: String, reason: String)
      /// Database locked
      case databaseLocked(reason: String)
      /// Internal error
      case internalError(reason: String)
    }
    
    /// Stub for FileSystem errors
    public enum FileSystem: Error {
      /// File not found
      case fileNotFound(path: String)
      /// Directory not found
      case directoryNotFound(path: String)
      /// Directory creation failed
      case directoryCreationFailed(path: String, reason: String)
      /// Rename failed
      case renameFailed(source: String, destination: String, reason: String)
      /// Copy failed
      case copyFailed(source: String, destination: String, reason: String)
      /// Permission denied
      case permissionDenied(path: String)
      /// Invalid path
      case invalidPath(path: String)
      /// Read-only file system
      case readOnlyFileSystem(path: String)
      /// File in use
      case fileInUse(path: String)
      /// Unsupported operation
      case unsupportedOperation(operation: String, filesystem: String)
      /// Filesystem full
      case filesystemFull
      /// Internal error
      case internalError(reason: String)
    }
  }
  
  /// Stub namespace for Repository
  public enum Repository {
    /// Stub for Core errors
    public enum Core: Error {
      /// Repository not found
      case repositoryNotFound(resource: String)
      /// Repository open failed
      case repositoryOpenFailed(reason: String)
      /// Repository corrupt
      case repositoryCorrupt(reason: String)
    }
  }
  
  /// Stub namespace for Resource
  public enum Resource {
    /// Stub for File errors
    public enum File: Error {
      /// File not found
      case fileNotFound(path: String)
      /// File corrupt
      case fileCorrupt(path: String, reason: String)
      /// No access
      case noAccess(path: String)
    }
    
    /// Stub for Core errors
    public enum Core: Error {
      /// Resource not found
      case resourceNotFound(resource: String)
      /// Resource already exists
      case resourceAlreadyExists(resource: String)
      /// Resource invalid
      case resourceInvalid(resource: String, reason: String)
    }
    
    /// Stub for Pool errors
    public enum Pool: Error {
      /// Resource pool exhausted
      case poolExhausted(poolName: String)
      /// Invalid resource in pool
      case invalidResource(resourceId: String, reason: String)
      /// Resource allocation failed
      case allocationFailed(reason: String)
    }
  }
  
  /// Stub namespace for Logging
  public enum Logging {
    /// Stub for Core errors
    public enum Core: Error {
      /// Failed to initialize logger
      case initializationFailed(reason: String)
      /// Failed to write log
      case writeFailure(reason: String)
      /// Invalid log level
      case invalidLogLevel(level: String)
      /// Log destination unavailable
      case destinationUnavailable(destination: String, reason: String)
    }
  }
  
  /// Stub namespace for Bookmark
  public enum Bookmark {
    /// Stub for Core errors
    public enum Core: Error {
      /// Failed to create bookmark
      case creationFailed(reason: String)
      /// Failed to resolve bookmark
      case resolutionFailed(reason: String)
      /// Bookmark invalid
      case invalidBookmark(reason: String)
      /// Bookmark expired
      case expired(reason: String)
    }
  }
  
  /// Stub namespace for Crypto
  public enum Crypto {
    /// Stub for Core errors
    public enum Core: Error {
      /// Encryption failed
      case encryptionFailed(reason: String)
      /// Decryption failed
      case decryptionFailed(reason: String)
      /// Key generation failed
      case keyGenerationFailed(reason: String)
      /// Invalid key
      case invalidKey(reason: String)
      /// Hash verification failed
      case hashVerificationFailed(reason: String)
    }
  }
}

/// Stub namespace for ErrorHandlingTypes to break circular dependencies
public enum ErrorHandlingTypes {
  /// Stub for SecurityError
  public enum SecurityError: Error {
    /// Core security error
    case domainCoreError(UmbraErrors.GeneralSecurity.Core)
    /// Protocol error
    case domainProtocolError(UmbraErrors.Security.Protocols)
    /// XPC error
    case domainXPCError(UmbraErrors.Security.XPC)
    /// Authentication failed
    case authenticationFailed(reason: String)
    /// Permission denied
    case permissionDenied(reason: String)
    /// Unauthorized access
    case unauthorizedAccess(reason: String)
    /// Encryption failed
    case encryptionFailed(reason: String)
    /// Decryption failed
    case decryptionFailed(reason: String)
    /// Key generation failed
    case keyGenerationFailed(reason: String)
    /// Hashing failed
    case hashingFailed(reason: String)
    /// Signature invalid
    case signatureInvalid(reason: String)
    /// Internal error
    case internalError(reason: String)
  }
  
  /// Stub for NetworkError
  public enum NetworkError: Error {
    /// Connection failed
    case connectionFailed(reason: String)
    /// Host unreachable
    case hostUnreachable(host: String)
    /// Service unavailable
    case serviceUnavailable(service: String, reason: String)
    /// Request failed
    case requestFailed(statusCode: Int, reason: String)
    /// Invalid request
    case invalidRequest(reason: String)
    /// Request rejected
    case requestRejected(code: Int, reason: String)
    /// Response invalid
    case responseInvalid(reason: String)
    /// Invalid response
    case invalidResponse(reason: String)
    /// Parsing failed
    case parsingFailed(reason: String)
    /// Certificate error
    case certificateError(reason: String)
    /// Untrusted host
    case untrustedHost(hostname: String)
    /// Data corruption
    case dataCorruption(reason: String)
    /// Request too large
    case requestTooLarge(sizeByte: Int64, maxSizeByte: Int64)
    /// Response too large
    case responseTooLarge(sizeByte: Int64, maxSizeByte: Int64)
    /// Rate limit exceeded
    case rateLimitExceeded(limitPerHour: Int, retryAfterMs: Int)
    /// Timeout during operation
    case timeout(operation: String, durationMs: Int)
    /// Operation interrupted
    case interrupted(reason: String)
    /// Unknown error
    case unknown(reason: String)
    /// Internal error
    case internalError(reason: String)
  }
  
  /// Stub for ApplicationError
  public enum ApplicationError: Error {
    /// Core application error
    case coreError(UmbraErrors.Application.Core)
    /// Lifecycle error
    case lifecycleError(UmbraErrors.Application.Lifecycle)
    /// Lifecycle error with reason
    case lifecycleError(reason: String)
    /// UI error
    case uiError(UmbraErrors.Application.UI)
    /// View error
    case viewError(reason: String)
    /// Rendering error
    case renderingError(reason: String)
    /// Launch error
    case launchError(reason: String)
    /// Configuration error
    case configurationError(reason: String)
    /// Invalid configuration
    case invalidConfiguration(reason: String)
    /// Plugin error
    case pluginError(reason: String)
    /// Permission error
    case permissionError(reason: String)
    /// Resource error
    case resourceError(reason: String)
    /// Resource not found
    case resourceNotFound(reason: String)
    /// Resource already exists
    case resourceAlreadyExists(reason: String)
    /// Operation cancelled
    case operationCancelled(reason: String)
    /// State error
    case stateError(reason: String)
    /// Settings error
    case settingsError(reason: String)
    /// Initialisation failed
    case initialisationFailed(reason: String)
    /// Resource missing
    case resourceMissing(resource: String)
    /// Operation timeout
    case operationTimeout(operation: String, durationMs: Int)
    /// Operation timeout with reason
    case operationTimeout(reason: String)
    /// Invalid state
    case invalidState(current: String, expected: String)
    /// Unknown error
    case unknown(reason: String)
    /// Internal error
    case internalError(reason: String)
  }
  
  /// Stub for StorageError
  public enum StorageError: Error {
    /// File not found
    case fileNotFound(path: String)
    /// Resource not found
    case resourceNotFound(path: String)
    /// Permission denied
    case permissionDenied(reason: String)
    /// Access denied
    case accessDenied(reason: String)
    /// Invalid format
    case invalidFormat(reason: String)
    /// Write failed
    case writeFailed(reason: String)
    /// Copy failed
    case copyFailed(source: String, destination: String, reason: String)
    /// Query failed
    case queryFailed(reason: String)
    /// Transaction failed
    case transactionFailed(reason: String)
    /// Disk full
    case diskFull(path: String, requiredBytes: Int64)
    /// Insufficient space
    case insufficientSpace(required: Int64, available: Int64)
    /// Database error
    case databaseError(code: Int, reason: String)
    /// Unknown error
    case unknown(reason: String)
    /// Internal error
    case internalError(reason: String)
  }
}

/// Interface for error mappers
public protocol ErrorMapper {
    associatedtype SourceError: Error
    associatedtype TargetError
    
    /// Maps from the source error type to the target error type
    func mapError(_ error: SourceError) -> TargetError
}

/// Interface for bidirectional error mappers
public protocol BidirectionalErrorMapper: ErrorMapper {
    /// Maps from source error type A to target error type B
    func mapAtoB(_ error: SourceError) -> TargetError
    
    /// Maps from target error type B to source error type A
    func mapBtoA(_ error: TargetError) -> SourceError
}
