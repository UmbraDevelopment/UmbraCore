import Foundation

/**
 # Core Security Provider Protocol
 
 This protocol defines a simplified interface for security operations required by Core modules.
 
 ## Purpose
 
 - Provides an abstraction layer over the complete security service implementation
 - Isolates Core modules from changes in the security implementation details
 - Follows the adapter pattern to reduce coupling between modules
 
 ## Implementation Notes
 
 This protocol should be implemented by an adapter class that delegates to the actual
 SecurityProviderProtocol implementation, converting between simplified Core types and
 security-specific types as needed.
 */
public protocol CoreSecurityProviderProtocol: Sendable {
    /**
     Initialises the security provider
     
     Performs any required setup for the security provider service.
     
     - Throws: Error if initialisation fails
     */
    func initialise() async throws
    
    /**
     Authenticates a user using the provided identifier and credentials
     
     - Parameters:
         - identifier: User identifier
         - credentials: Authentication credentials
     - Returns: True if authentication is successful, false otherwise
     - Throws: Error if authentication fails
     */
    func authenticate(identifier: String, credentials: Data) async throws -> Bool
    
    /**
     Authorises access to a resource at the specified access level
     
     - Parameters:
         - resource: The resource identifier
         - accessLevel: The requested access level
     - Returns: True if authorisation is granted, false otherwise
     - Throws: Error if authorisation check fails
     */
    func authorise(resource: String, accessLevel: String) async throws -> Bool
    
    /**
     Verifies the integrity of data using the provided signature
     
     - Parameters:
         - data: Data to verify
         - signature: Digital signature
     - Returns: True if verification is successful, false otherwise
     - Throws: Error if verification process fails
     */
    func verifySignature(data: Data, signature: Data) async throws -> Bool
}
