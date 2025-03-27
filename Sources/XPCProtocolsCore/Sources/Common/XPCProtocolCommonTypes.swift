/**
 # XPC Protocol Common Types
 
 This file contains the minimal shared type definitions required by both XPCProtocolsCore
 and SecurityInterfaces modules to prevent circular dependencies. It only includes
 types essential for cross-module communication.

 This common foundation enables a clean separation of concerns while maintaining
 type safety across module boundaries.
 */

import Foundation
import UmbraCoreTypes
import UmbraErrorsCore

/// Common namespace for XPC Protocol types that need to be shared across module boundaries
public enum XPCProtocolCommon {
  /// Security error types used in XPC communications
  public enum SecurityErrorType: Int, Codable, Sendable {
    /// Access denied or permission error
    case accessDenied = 1
    
    /// Authentication failed
    case authenticationFailed = 2
    
    /// Operation timed out
    case timeout = 3
    
    /// Service not available
    case serviceUnavailable = 4
    
    /// Invalid parameter or input
    case invalidParameter = 5
    
    /// Unknown or unclassified error
    case unknown = 999
    
    /// Converts to an error code
    public var code: Int {
      return self.rawValue
    }
  }
  
  /// Basic operation result status
  public enum OperationStatus: String, Codable, Sendable {
    /// Operation completed successfully
    case success
    
    /// Operation failed
    case failure
    
    /// Operation pending or in progress
    case pending
  }
  
  /// Represents the basic connection status for XPC services
  public enum ConnectionStatus: String, Codable, Sendable {
    /// Connection is active and healthy
    case connected
    
    /// Connection is in process of being established
    case connecting
    
    /// Connection has been terminated
    case disconnected
    
    /// Connection encountered an error
    case error
  }
  
  /// Direction of data flow in XPC operations
  public enum DataDirection: String, Codable, Sendable {
    /// Data is flowing from client to service
    case clientToService
    
    /// Data is flowing from service to client
    case serviceToClient
    
    /// Data is flowing in both directions
    case bidirectional
  }
}
