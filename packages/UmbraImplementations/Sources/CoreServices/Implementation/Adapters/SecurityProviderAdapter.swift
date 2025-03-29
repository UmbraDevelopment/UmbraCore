import CoreInterfaces
import Foundation
import SecurityCoreInterfaces
import SecurityCoreTypes

/**
 # Security Provider Adapter

 This class implements the adapter pattern to bridge between the CoreSecurityProviderProtocol
 and the full SecurityProviderProtocol implementation.

 ## Purpose

 - Provides a simplified interface for core modules to access security functionality
 - Delegates operations to the actual security implementation
 - Converts between data types as necessary

 ## Design Pattern

 This adapter follows the classic adapter design pattern, where it implements
 one interface (CoreSecurityProviderProtocol) while wrapping an instance of another
 interface (SecurityProviderProtocol).
 */
public class SecurityProviderAdapter: CoreSecurityProviderProtocol {
  // MARK: - Properties

  /**
   The underlying security provider implementation

   This is the actual implementation that performs the security operations.
   */
  private let securityProvider: SecurityCoreInterfaces.SecurityProviderProtocol

  // MARK: - Initialisation

  /**
   Initialises a new adapter with the provided security provider

   - Parameter securityProvider: The security provider implementation to adapt
   */
  public init(securityProvider: SecurityCoreInterfaces.SecurityProviderProtocol) {
    self.securityProvider=securityProvider
  }

  // MARK: - CoreSecurityProviderProtocol Implementation

  /**
   Initialises the security provider

   Delegates to the underlying security provider implementation.

   - Throws: SecurityError if initialisation fails
   */
  public func initialise() async throws {
    try await securityProvider.initialise()
  }

  /**
   Authenticates a user using the provided identifier and credentials

   Delegates to the underlying security provider implementation.

   - Parameters:
       - identifier: User identifier
       - credentials: Authentication credentials
   - Returns: True if authentication is successful, false otherwise
   - Throws: SecurityError if authentication fails
   */
  public func authenticate(identifier: String, credentials: Data) async throws -> Bool {
    try await securityProvider.authenticate(identifier: identifier, credentials: credentials)
  }

  /**
   Authorises access to a resource at the specified access level

   Delegates to the underlying security provider implementation.

   - Parameters:
       - resource: The resource identifier
       - accessLevel: The requested access level
   - Returns: True if authorisation is granted, false otherwise
   - Throws: SecurityError if authorisation check fails
   */
  public func authorise(resource: String, accessLevel: String) async throws -> Bool {
    try await securityProvider.authorise(resource: resource, accessLevel: accessLevel)
  }

  /**
   Verifies the integrity of data using the provided signature

   Delegates to the underlying security provider implementation.

   - Parameters:
       - data: Data to verify
       - signature: Digital signature
   - Returns: True if verification is successful, false otherwise
   - Throws: SecurityError if verification process fails
   */
  public func verifySignature(data: Data, signature: Data) async throws -> Bool {
    try await securityProvider.verify(data: data, signature: signature)
  }
}
