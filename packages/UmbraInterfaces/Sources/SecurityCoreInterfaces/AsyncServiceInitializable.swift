import Foundation

/**
 # AsyncServiceInitializable Protocol

 Defines a protocol for services that require explicit asynchronous initialisation.

 This protocol allows components to separate construction from initialisation,
 which is particularly useful for services that need asynchronous setup
 or resource allocation before they are ready for use.

 ## Usage

 ```swift
 let service = MyService()
 try await service.initialize() // Perform async setup tasks
 ```
 */
public protocol AsyncServiceInitializable: Sendable {
  /**
   Initializes the implementing service.

   This method performs any necessary setup that must occur before the service
   is ready for use. This may include resource allocation, network connections,
   or other asynchronous operations.

   - Throws: Error if initialization fails
   */
  func initialize() async throws
}
