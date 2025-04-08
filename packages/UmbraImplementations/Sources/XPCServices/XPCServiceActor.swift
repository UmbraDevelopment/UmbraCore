import CoreDTOs
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import UmbraErrors
import XPCProtocolsCore

/**
 # XPC Service Actor

 Concrete implementation of the XPC service protocol using Swift actors
 for thread safety and isolation. This actor manages the lifecycle of
 an XPC connection and handles message routing.

 This implementation follows the Alpha Dot Five architecture principles
 with proper actor isolation and structured concurrency.
 */
public actor XPCServiceActor: XPCServiceProtocol {
  /// Underlying XPC connection
  private var connection: NSXPCConnection?

  /// Service name for the XPC connection
  private let serviceName: String

  /// Whether the service is currently running
  private var isServiceRunning: Bool=false

  /// Registered message handlers for endpoints
  private var handlers: [XPCEndpointIdentifier: AnyXPCHandler]=[:]

  /// Logger for recording operations and errors
  private let logger: LoggingProtocol?

  /**
   Initialises a new XPC service actor.

   - Parameters:
      - serviceName: The name of the XPC service bundle
      - logger: Optional logger for recording operations and errors
   */
  public init(serviceName: String, logger: LoggingProtocol?=nil) {
    self.serviceName=serviceName
    self.logger=logger
  }

  /**
   Starts the XPC service.

   This method initialises the underlying XPC connection and prepares
   the service for receiving messages.

   - Throws: XPCServiceError if the service cannot be started
   */
  public func start() async throws {
    if isServiceRunning {
      return
    }

    await log(.info, "Starting XPC service: \(serviceName)")

    // Create connection to the XPC service
    let newConnection=NSXPCConnection(serviceName: serviceName)

    // Set up security and configure the connection
    configureConnection(newConnection)

    // Resume the connection
    newConnection.resume()

    // Validate connection
    do {
      try await validateConnection(newConnection)
      connection=newConnection
      isServiceRunning=true
      await log(.info, "XPC service started successfully: \(serviceName)")
    } catch {
      await log(.error, "Failed to start XPC service: \(error)")
      newConnection.invalidate()
      throw XPCServiceError
        .connectionFailed("Failed to start XPC service: \(error.localizedDescription)")
    }
  }

  /**
   Stops the XPC service.

   This method terminates the underlying XPC connection and cleans up resources.
   */
  public func stop() async {
    await log(.info, "Stopping XPC service: \(serviceName)")

    if let existingConnection=connection {
      existingConnection.invalidate()
      connection=nil
    }

    isServiceRunning=false
    await log(.info, "XPC service stopped: \(serviceName)")
  }

  /**
   Sends a message to the XPC service and awaits a response.

   - Parameters:
      - message: The message to send
      - endpoint: Optional endpoint identifier for routing the message

   - Returns: The response data
   - Throws: XPCServiceError if the message cannot be sent or processed
   */
  public func sendMessage<R: Sendable>(
    _ message: some Sendable,
    to endpoint: XPCEndpointIdentifier?
  ) async throws -> R {
    // Ensure the service is running
    guard isServiceRunning, let activeConnection=connection else {
      throw XPCServiceError.serviceNotRunning("XPC service not running")
    }

    let endpointName=endpoint?.name ?? "default"
    await log(.debug, "Sending message to endpoint: \(endpointName)")

    return try await withCheckedThrowingContinuation { continuation in
      do {
        // Get the remote proxy object
        guard let proxy=activeConnection.remoteObjectProxy as? XPCMessageHandler else {
          throw XPCServiceError.connectionFailed("Failed to get remote object proxy")
        }

        // Encode the message
        let data: Data
        do {
          data=try NSKeyedArchiver.archivedData(
            withRootObject: message,
            requiringSecureCoding: true
          )
        } catch {
          throw XPCServiceError
            .messageEncodingFailed("Failed to encode message: \(error.localizedDescription)")
        }

        // Send the message
        proxy.handleMessage(data, forEndpoint: endpoint?.name ?? "default") { responseData, error in
          if let error {
            continuation.resume(throwing: XPCServiceError.handlerError(
              "Remote handler error",
              error
            ))
            return
          }

          guard let responseData else {
            continuation
              .resume(throwing: XPCServiceError.responseDecodingFailed("No response data received"))
            return
          }

          do {
            // Handle two cases: types that conform to NSSecureCoding and types that support JSON
            if let decodable=R.self as? NSSecureCoding.Type {
              // Use NSKeyedUnarchiver for NSSecureCoding types
              let messageObject=try NSKeyedUnarchiver.unarchivedObject(
                ofClasses: [decodable as AnyClass],
                from: responseData
              )
              guard let response=messageObject as? R else {
                throw XPCServiceError
                  .responseDecodingFailed("Failed to decode response as expected type")
              }
              continuation.resume(returning: response)
            } else {
              // For types that don't conform to NSSecureCoding, try JSON
              let dictionary=try JSONSerialization.jsonObject(with: responseData)
              guard let response=dictionary as? R else {
                throw XPCServiceError
                  .responseDecodingFailed("Failed to decode response as expected type")
              }
              continuation.resume(returning: response)
            }
          } catch {
            continuation
              .resume(
                throwing: XPCServiceError
                  .responseDecodingFailed(
                    "Failed to decode response: \(error.localizedDescription)"
                  )
              )
          }
        }
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }

  /**
   Registers a message handler for processing incoming messages.

   - Parameters:
      - endpoint: The endpoint identifier to register the handler for
      - handler: The async function to handle messages sent to this endpoint

   - Throws: XPCServiceError if the handler cannot be registered
   */
  public func registerHandler<T: Sendable>(
    for endpoint: XPCEndpointIdentifier,
    handler: @Sendable @escaping (T) async throws -> some Sendable
  ) async throws {
    await log(.info, "Registering handler for endpoint: \(endpoint.name)")

    // The wrapped handler must also be Sendable
    let wrappedHandler=AnyXPCHandler(handler: { @Sendable data in
      // Decode the message
      do {
        // Handle two cases: types that conform to NSSecureCoding and types that support JSON
        if
          let decodable=T.self as? NSSecureCoding.Type,
          let messageObject=try NSKeyedUnarchiver.unarchivedObject(
            ofClasses: [decodable as AnyClass],
            from: data
          ),
          let message=messageObject as? T
        {

          // Call the handler with the decoded message
          let response=try await handler(message)

          // If response conforms to NSSecureCoding, use NSKeyedArchiver
          if let secureCodingResponse=response as? NSSecureCoding {
            return try NSKeyedArchiver.archivedData(
              withRootObject: secureCodingResponse,
              requiringSecureCoding: true
            )
          } else {
            // Fallback to JSON for types that don't conform to NSSecureCoding
            let dictionary=try JSONSerialization.data(withJSONObject: response, options: [])
            return dictionary
          }
        } else {
          // For types that don't conform to NSSecureCoding, try JSON
          let dictionary=try JSONSerialization.jsonObject(with: data)
          guard let message=dictionary as? T else {
            throw XPCServiceError.messageEncodingFailed("Failed to decode message as expected type")
          }

          // Call the handler
          let response=try await handler(message)

          // Encode the response
          return try JSONSerialization.data(withJSONObject: response, options: [])
        }
      } catch {
        throw XPCServiceError
          .messageEncodingFailed("Failed to decode message: \(error.localizedDescription)")
      }
    })

    handlers[endpoint]=wrappedHandler
  }

  /**
   Checks if the service is currently running.

   - Returns: True if the service is running, false otherwise
   */
  public func isRunning() async -> Bool {
    isServiceRunning
  }

  /**
   Gets the service's listener endpoint for clients to connect to.

   - Returns: The endpoint identifier or nil if the service is not running
   */
  public func getListenerEndpoint() async -> XPCEndpointIdentifier? {
    guard isServiceRunning else {
      return nil
    }

    return XPCEndpointIdentifier(name: "listener.\(serviceName)")
  }

  // MARK: - Private Methods

  /**
   Configures the XPC connection with security settings and interface requirements.

   - Parameter connection: The XPC connection to configure
   */
  private func configureConnection(_ connection: NSXPCConnection) {
    // Set the interface
    let interface=NSXPCInterface(with: XPCMessageHandler.self)
    connection.remoteObjectInterface=interface

    // Configure security
    connection.exportedInterface=interface
    connection.exportedObject=LocalXPCMessageHandler(actor: self)

    // Set up interruption and invalidation handlers
    connection.interruptionHandler={
      Task {
        await self.handleConnectionInterruption()
      }
    }

    connection.invalidationHandler={
      Task {
        await self.handleConnectionInvalidation()
      }
    }
  }

  /**
   Validates that the XPC connection is functioning properly.

   - Parameter connection: The XPC connection to validate
   - Throws: XPCServiceError if the connection cannot be validated
   */
  private func validateConnection(_ connection: NSXPCConnection) async throws {
    // Perform a simple ping to validate the connection
    let proxy=connection.remoteObjectProxy as? XPCMessageHandler
    guard proxy != nil else {
      throw XPCServiceError.connectionFailed("Failed to get remote object proxy during validation")
    }

    // Additional validation could be performed here
  }

  /**
   Handles a connection interruption.
   */
  private func handleConnectionInterruption() async {
    await log(.warning, "XPC connection interrupted: \(serviceName)")
    isServiceRunning=false
  }

  /**
   Handles a connection invalidation.
   */
  private func handleConnectionInvalidation() async {
    await log(.warning, "XPC connection invalidated: \(serviceName)")
    connection=nil
    isServiceRunning=false
  }

  /**
   Logs a message using the configured logger.

   - Parameters:
      - level: The log level
      - message: The message to log
   */
  private func log(_ level: LogLevel, _ message: String) async {
    if let logger {
      let context=BaseLogContextDTO(domainName: "XPCService", source: "XPCServiceActor")
      await logger.log(level, message, context: context)
    }
  }

  /**
   Handles an incoming message from the XPC connection.

   - Parameters:
      - messageData: The encoded message data
      - endpointName: The name of the target endpoint

   - Returns: The encoded response data
   - Throws: XPCServiceError if the message cannot be handled
   */
  fileprivate func handleIncomingMessage(
    _ messageData: Data,
    forEndpoint endpointName: String
  ) async throws -> Data {
    let endpoint=XPCEndpointIdentifier(name: endpointName)

    guard let handler=handlers[endpoint] else {
      throw XPCServiceError.endpointNotFound("No handler registered for endpoint: \(endpointName)")
    }

    return try await handler.handle(messageData)
  }
}

/**
 Protocol for handling XPC messages between processes.
 This is used for the remote object proxy interface.
 */
@objc
private protocol XPCMessageHandler {
  /// Type alias for the completion handler to ensure Sendable conformance
  typealias XPCMessageHandlerCompletion=@Sendable (Data?, Error?) -> Void

  /**
   Handles a message and returns a response.

   - Parameters:
      - message: The message data
      - endpoint: The endpoint name
      - completion: Callback for the response or error
   */
  func handleMessage(
    _ message: Data,
    forEndpoint endpoint: String,
    withCompletion completion: @escaping XPCMessageHandlerCompletion
  )
}

/**
 Local implementation of the XPC message handler that delegates to the actor.
 */
private class LocalXPCMessageHandler: NSObject, XPCMessageHandler {
  /// The parent actor
  private weak var actor: XPCServiceActor?

  /**
   Initialises a new local XPC message handler.

   - Parameter actor: The parent XPC service actor
   */
  init(actor: XPCServiceActor) {
    self.actor=actor
    super.init()
  }

  /**
   Handles an incoming message by delegating to the actor.

   - Parameters:
      - message: The message data
      - endpoint: The endpoint name
      - completion: Callback for the response or error
   */
  func handleMessage(
    _ message: Data,
    forEndpoint endpoint: String,
    withCompletion completion: @escaping XPCMessageHandlerCompletion
  ) {
    guard let actor else {
      completion(nil, XPCServiceError.serviceNotRunning("XPC service actor has been deallocated"))
      return
    }

    Task {
      do {
        let response=try await actor.handleIncomingMessage(message, forEndpoint: endpoint)
        completion(response, nil)
      } catch {
        completion(nil, error)
      }
    }
  }
}

/**
 Type-erased handler for XPC messages.
 This allows storing handlers of different types in a dictionary.
 */
private struct AnyXPCHandler: Sendable {
  /// The handling function - must be Sendable
  private let handler: @Sendable (Data) async throws -> Data

  /**
   Initialises a new type-erased XPC handler.

   - Parameter handler: The Sendable handling function
   */
  init(handler: @Sendable @escaping (Data) async throws -> Data) {
    self.handler=handler
  }

  /**
   Handles a message by delegating to the stored handler.

   - Parameter message: The message data
   - Returns: The response data
   - Throws: Any error thrown by the handler
   */
  func handle(_ message: Data) async throws -> Data {
    try await handler(message)
  }
}
