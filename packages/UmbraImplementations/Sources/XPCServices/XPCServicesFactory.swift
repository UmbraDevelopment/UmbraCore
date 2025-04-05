import Foundation
import LoggingInterfaces
import UmbraErrors
import XPCProtocolsCore

/**
 # XPC Services Factory

 Factory for creating XPC service instances following the Alpha Dot Five
 architecture principles of dependency injection and actor-based concurrency.

 This factory provides convenient methods for creating various types of
 XPC services with appropriate configuration.
 */
public enum XPCServices {
  /**
   Creates an XPC service for communicating with a specific service bundle.

   - Parameters:
      - serviceName: The name of the XPC service bundle
      - logger: Optional logger for recording operations

   - Returns: A configured XPC service
   */
  public static func createService(
    serviceName: String,
    logger: LoggingProtocol?=nil
  ) async -> XPCServiceProtocol {
    XPCServiceActor(serviceName: serviceName, logger: logger)
  }

  /**
   Creates an XPC service with mocked responses for testing.

   - Parameters:
      - logger: Optional logger for recording operations

   - Returns: A mocked XPC service suitable for testing
   */
  public static func createMockService(
    logger: LoggingProtocol?=nil
  ) async -> XPCServiceProtocol {
    MockXPCServiceActor(logger: logger)
  }
}

/**
 Mock implementation of XPC service for testing.
 This actor simulates an XPC service without actual inter-process communication.
 */
actor MockXPCServiceActor: XPCServiceProtocol {
  /// Whether the service is currently running
  private var isServiceRunning: Bool=false

  /// Registered message handlers
  private var handlers: [XPCEndpointIdentifier: AnyObject]=[:]

  /// Configured mock responses
  private var mockResponses: [String: AnyObject]=[:]

  /// Logger for recording operations and errors
  private let logger: LoggingProtocol?

  /**
   Initialises a new mock XPC service actor.

   - Parameter logger: Optional logger for recording operations
   */
  init(logger: LoggingProtocol?=nil) {
    self.logger=logger
  }

  /**
   Starts the mock XPC service.

   - Throws: XPCServiceError if the service cannot be started
   */
  public func start() async throws {
    await log(.info, "Starting mock XPC service")
    isServiceRunning=true
  }

  /**
   Stops the mock XPC service.
   */
  public func stop() async {
    await log(.info, "Stopping mock XPC service")
    isServiceRunning=false
  }

  /**
   Simulates sending a message and returns a mock response.

   - Parameters:
      - message: The message to send
      - endpoint: Optional endpoint identifier

   - Returns: The mock response
   - Throws: XPCServiceError if the service is not running
   */
  public func sendMessage<R: Sendable>(
    _: some Sendable,
    to endpoint: XPCEndpointIdentifier?
  ) async throws -> R {
    guard isServiceRunning else {
      throw XPCServiceError.serviceNotRunning("Mock XPC service not running")
    }

    let endpointName=endpoint?.name ?? "default"
    await log(.debug, "Mock: Sending message to endpoint: \(endpointName)")

    // Check for configured mock response
    if let mockResponse=mockResponses[endpointName] as? R {
      return mockResponse
    }

    // If no mock response is configured, throw an error
    throw XPCServiceError
      .endpointNotFound("No mock response configured for endpoint: \(endpointName)")
  }

  /**
   Registers a handler for an endpoint.

   - Parameters:
      - endpoint: The endpoint identifier
      - handler: The handler function

   - Throws: XPCServiceError if the handler cannot be registered
   */
  public func registerHandler<T: Sendable>(
    for endpoint: XPCEndpointIdentifier,
    handler: @Sendable @escaping (T) async throws -> some Sendable
  ) async throws {
    await log(.info, "Mock: Registering handler for endpoint: \(endpoint.name)")

    // Store the handler in a type-erased form
    let handlerBox=HandlerBox(handler: handler)
    handlers[endpoint]=handlerBox
  }

  /**
   Configures a mock response for a specific endpoint.

   - Parameters:
      - response: The response to return
      - endpoint: The endpoint to configure
   */
  public func configureMockResponse(
    _ response: some Sendable,
    for endpoint: XPCEndpointIdentifier
  ) async {
    await log(.info, "Configuring mock response for endpoint: \(endpoint.name)")
    mockResponses[endpoint.name]=response as AnyObject
  }

  /**
   Checks if the service is running.

   - Returns: True if the service is running
   */
  public func isRunning() async -> Bool {
    isServiceRunning
  }

  /**
   Gets the listener endpoint.

   - Returns: A mock endpoint identifier
   */
  public func getListenerEndpoint() async -> XPCEndpointIdentifier? {
    guard isServiceRunning else {
      return nil
    }

    return XPCEndpointIdentifier(name: "mock.listener")
  }

  /**
   Logs a message using the configured logger.

   - Parameters:
      - level: The log level
      - message: The message to log
   */
  private func log(_ level: LogLevel, _ message: String) async {
    if let logger {
      let context = BaseLogContextDTO(domainName: "XPCService", source: "MockXPCService")
      await logger.log(level, message, context: context)
    }
  }
}

/**
 Type-erased box for storing handler functions of different types.
 */
private class HandlerBox<T: Sendable, R: Sendable>: @unchecked Sendable {
  /// The handler function
  private let handler: @Sendable (T) async throws -> R

  /**
   Initialises a new handler box.

   - Parameter handler: The handler function to store
   */
  init(handler: @Sendable @escaping (T) async throws -> R) {
    self.handler=handler
  }

  /**
   Calls the stored handler.

   - Parameter input: The input to the handler
   - Returns: The handler's response
   - Throws: Any error thrown by the handler
   */
  func call(_ input: T) async throws -> R {
    try await handler(input)
  }
}
