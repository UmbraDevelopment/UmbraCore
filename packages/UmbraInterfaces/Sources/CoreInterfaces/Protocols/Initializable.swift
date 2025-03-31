import Foundation

/**
 # Initializable Protocol

 Defines a protocol for types that require explicit initialisation.

 This protocol allows components to separate construction from initialisation,
 which is particularly useful for services that need asynchronous setup
 or resource allocation before they are ready for use.

 ## Usage

 ```swift
 let service = MyService()
 try await service.initialize() // Perform async setup tasks
 ```
 */
public protocol Initializable: Sendable {
  /**
   Initializes the implementing object.

   This method performs any necessary setup that must occur before the object
   is ready for use. This may include resource allocation, network connections,
   or other asynchronous operations.

   - Throws: Error if initialization fails
   */
  func initialize() async throws
}
