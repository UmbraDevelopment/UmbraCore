import Foundation
import KeychainInterfaces
import LoggingInterfaces
import SecurityCoreTypes
import UmbraErrors
import XPCProtocolsCore
import XPCServices

/**
 # KeychainXPCService

 Provides XPC-based keychain services that operate across process boundaries
 while ensuring proper security isolation. This implementation follows the
 Alpha Dot Five architecture with actor-based concurrency, type safety, and
 proper error handling.

 ## Thread Safety

 This service uses actors to ensure thread safety and proper state isolation.
 All operations are performed asynchronously using Swift's structured concurrency.

 ## Usage Example

 ```swift
 // Create and start the service
 let xpcService = await KeychainXPCServices.createService()
 try await xpcService.start()

 // Store a password
 try await xpcService.storePassword("securePassword", for: "user123")

 // Retrieve the password
 let password = try await xpcService.retrievePassword(for: "user123")

 // Stop the service when done
 await xpcService.stop()
 ```
 */
public actor KeychainXPCService: KeychainServiceProtocol {
  /// The underlying XPC service
  private let xpcService: XPCServiceProtocol

  /// Service identifier for the keychain items
  public let serviceIdentifier: String

  /// Logger for operation recording
  private let logger: LoggingProtocol?

  /**
   Initialises a new KeychainXPCService.

   - Parameters:
      - xpcService: The underlying XPC service
      - serviceIdentifier: The service identifier for keychain items
      - logger: Optional logger for operation recording
   */
  public init(
    xpcService: XPCServiceProtocol,
    serviceIdentifier: String,
    logger: LoggingProtocol?=nil
  ) {
    self.xpcService=xpcService
    self.serviceIdentifier=serviceIdentifier
    self.logger=logger
  }

  /**
   Starts the XPC service and ensures it's ready for operation.

   - Throws: KeychainError if the service cannot be started
   */
  public func start() async throws {
    await log(.info, "Starting KeychainXPCService")

    do {
      try await xpcService.start()
      await log(.info, "KeychainXPCService started successfully")
    } catch {
      await log(.error, "Failed to start KeychainXPCService: \(error)")
      throw KeychainError
        .serviceStartFailed("Failed to start XPC service: \(error.localizedDescription)")
    }
  }

  /**
   Stops the XPC service.
   */
  public func stop() async {
    await log(.info, "Stopping KeychainXPCService")
    await xpcService.stop()
  }

  /**
   Stores a password securely in the keychain via XPC.

   - Parameters:
      - password: The password string to store
      - account: The account identifier for the password
      - accessOptions: Optional access control options

   - Throws: KeychainError if the operation fails
   */
  public func storePassword(
    _ password: String,
    for account: String,
    accessOptions: KeychainAccessOptions?=nil
  ) async throws {
    await log(.info, "Storing password for account: \(account)")

    let request=KeychainStoreRequest(
      type: .password,
      account: account,
      serviceIdentifier: serviceIdentifier,
      stringValue: password,
      accessOptions: accessOptions
    )

    do {
      try await sendVoidRequest(request, to: .storePassword)
      await log(.info, "Password stored successfully for account: \(account)")
    } catch {
      await log(.error, "Failed to store password: \(error)")
      throw mapError(error, operation: "store password")
    }
  }

  /**
   Retrieves a password from the keychain via XPC.

   - Parameter account: The account identifier for the password

   - Returns: The stored password as a string
   - Throws: KeychainError if the password doesn't exist or retrieval fails
   */
  public func retrievePassword(for account: String) async throws -> String {
    await log(.info, "Retrieving password for account: \(account)")

    let request=KeychainRetrieveRequest(
      type: .password,
      account: account,
      serviceIdentifier: serviceIdentifier
    )

    do {
      let response=try await sendRequestForStringResponse(request, to: .retrievePassword)
      await log(.info, "Password retrieved successfully for account: \(account)")
      return response.value
    } catch {
      await log(.error, "Failed to retrieve password: \(error)")
      throw mapError(error, operation: "retrieve password")
    }
  }

  /**
   Deletes a password from the keychain via XPC.

   - Parameter account: The account identifier for the password to delete

   - Throws: KeychainError if the deletion fails
   */
  public func deletePassword(for account: String) async throws {
    await log(.info, "Deleting password for account: \(account)")

    let request=KeychainDeleteRequest(
      type: .password,
      account: account,
      serviceIdentifier: serviceIdentifier
    )

    do {
      try await sendVoidRequest(request, to: .deleteItem)
      await log(.info, "Password deleted successfully for account: \(account)")
    } catch {
      await log(.error, "Failed to delete password: \(error)")
      throw mapError(error, operation: "delete password")
    }
  }

  /**
   Stores binary data securely in the keychain via XPC.

   - Parameters:
      - data: The binary data to store
      - account: The account identifier for the data
      - accessOptions: Optional access control options

   - Throws: KeychainError if the operation fails
   */
  public func storeData(
    _ data: Data,
    for account: String,
    accessOptions: KeychainAccessOptions?=nil
  ) async throws {
    await log(.info, "Storing data for account: \(account)")

    let request=KeychainStoreRequest(
      type: .data,
      account: account,
      serviceIdentifier: serviceIdentifier,
      dataValue: data,
      accessOptions: accessOptions
    )

    do {
      try await sendVoidRequest(request, to: .storeData)
      await log(.info, "Data stored successfully for account: \(account)")
    } catch {
      await log(.error, "Failed to store data: \(error)")
      throw mapError(error, operation: "store data")
    }
  }

  /**
   Retrieves binary data from the keychain via XPC.

   - Parameter account: The account identifier for the data

   - Returns: The stored data
   - Throws: KeychainError if the data doesn't exist or retrieval fails
   */
  public func retrieveData(for account: String) async throws -> Data {
    await log(.info, "Retrieving data for account: \(account)")

    let request=KeychainRetrieveRequest(
      type: .data,
      account: account,
      serviceIdentifier: serviceIdentifier
    )

    do {
      let response=try await sendRequestForDataResponse(request, to: .retrieveData)
      await log(.info, "Data retrieved successfully for account: \(account)")
      return response.value
    } catch {
      await log(.error, "Failed to retrieve data: \(error)")
      throw mapError(error, operation: "retrieve data")
    }
  }

  /**
   Deletes binary data from the keychain via XPC.

   - Parameter account: The account identifier for the data to delete

   - Throws: KeychainError if the deletion fails
   */
  public func deleteData(for account: String) async throws {
    await log(.info, "Deleting data for account: \(account)")

    let request=KeychainDeleteRequest(
      type: .data,
      account: account,
      serviceIdentifier: serviceIdentifier
    )

    do {
      try await sendVoidRequest(request, to: .deleteItem)
      await log(.info, "Data deleted successfully for account: \(account)")
    } catch {
      await log(.error, "Failed to delete data: \(error)")
      throw mapError(error, operation: "delete data")
    }
  }

  /**
   Checks if a password exists for the specified account.

   - Parameter account: The account identifier to check

   - Returns: True if a password exists for the account, false otherwise
   */
  public func passwordExists(for account: String) async -> Bool {
    await log(.debug, "Checking if password exists for account: \(account)")

    let request=KeychainExistsRequest(
      account: account,
      serviceIdentifier: serviceIdentifier
    )

    do {
      let response=try await sendRequestForBoolResponse(request, to: .passwordExists)
      await log(.debug, "Password existence check complete for account: \(account)")
      return response.value
    } catch {
      await log(.warning, "Error checking password existence: \(error)")
      return false
    }
  }

  /**
   Updates an existing password in the keychain.

   - Parameters:
      - newPassword: The new password to store
      - account: The account identifier for the password

   - Throws: KeychainError if the operation fails or the password doesn't exist
   */
  public func updatePassword(_ newPassword: String, for account: String) async throws {
    await log(.debug, "Updating password for account: \(account)")

    let request=KeychainStoreRequest(
      type: .password,
      account: account,
      serviceIdentifier: serviceIdentifier,
      stringValue: newPassword,
      accessOptions: nil
    )

    do {
      try await sendVoidRequest(request, to: .updatePassword)
      await log(.info, "Password updated successfully for account: \(account)")
    } catch {
      await log(.error, "Failed to update password: \(error)")
      throw mapError(error, operation: "update password")
    }
  }

  // MARK: - Private Helper Methods

  /**
   Sends a void request to the XPC service.

   - Parameters:
      - request: The request to send
      - endpoint: The endpoint to send the request to

   - Throws: XPCServiceError if the request cannot be sent or processed
   */
  private func sendVoidRequest(
    _ request: some Sendable,
    to endpoint: KeychainXPCEndpoint
  ) async throws {
    guard await xpcService.isRunning() else {
      throw KeychainError.serviceNotRunning("KeychainXPCService is not running")
    }

    let xpcEndpoint=XPCEndpointIdentifier(name: endpoint.rawValue)

    try await xpcService.sendMessage(request, to: xpcEndpoint) as Void
  }

  /**
   Sends a request to the XPC service and returns a data response.

   - Parameters:
      - request: The request to send
      - endpoint: The endpoint to send the request to

   - Returns: The data response from the XPC service
   - Throws: XPCServiceError if the request cannot be sent or processed
   */
  private func sendRequestForDataResponse(
    _ request: some Sendable,
    to endpoint: KeychainXPCEndpoint
  ) async throws -> KeychainDataResponse {
    guard await xpcService.isRunning() else {
      throw KeychainError.serviceNotRunning("KeychainXPCService is not running")
    }

    let xpcEndpoint=XPCEndpointIdentifier(name: endpoint.rawValue)

    return try await xpcService.sendMessage(request, to: xpcEndpoint)
  }

  /**
   Sends a request to the XPC service and returns a string response.

   - Parameters:
      - request: The request to send
      - endpoint: The endpoint to send the request to

   - Returns: The string response from the XPC service
   - Throws: XPCServiceError if the request cannot be sent or processed
   */
  private func sendRequestForStringResponse(
    _ request: some Sendable,
    to endpoint: KeychainXPCEndpoint
  ) async throws -> KeychainStringResponse {
    guard await xpcService.isRunning() else {
      throw KeychainError.serviceNotRunning("KeychainXPCService is not running")
    }

    let xpcEndpoint=XPCEndpointIdentifier(name: endpoint.rawValue)

    return try await xpcService.sendMessage(request, to: xpcEndpoint)
  }

  /**
   Sends a request to the XPC service and returns a boolean response.

   - Parameters:
      - request: The request to send
      - endpoint: The endpoint to send the request to

   - Returns: The boolean response from the XPC service
   - Throws: XPCServiceError if the request cannot be sent or processed
   */
  private func sendRequestForBoolResponse(
    _ request: some Sendable,
    to endpoint: KeychainXPCEndpoint
  ) async throws -> KeychainBoolResponse {
    guard await xpcService.isRunning() else {
      throw KeychainError.serviceNotRunning("KeychainXPCService is not running")
    }

    let xpcEndpoint=XPCEndpointIdentifier(name: endpoint.rawValue)

    return try await xpcService.sendMessage(request, to: xpcEndpoint)
  }

  /**
   Maps XPC errors to KeychainError types.

   - Parameters:
      - error: The original error
      - operation: The operation that failed

   - Returns: A KeychainError representing the failure
   */
  private func mapError(_ error: Error, operation: String) -> KeychainError {
    if let xpcError=error as? XPCServiceError {
      switch xpcError {
        case .serviceNotRunning:
          return KeychainError.serviceNotRunning("XPC service not running")
        case .connectionFailed:
          return KeychainError.serviceConnectionFailed("XPC connection failed for \(operation)")
        case .endpointNotFound:
          return KeychainError.operationFailed("XPC endpoint not found for \(operation)")
        case .messageEncodingFailed, .responseDecodingFailed:
          return KeychainError.dataCorruption("XPC data corruption during \(operation)")
        case let .handlerError(_, underlyingError):
          if let keychainError=underlyingError as? KeychainError {
            return keychainError
          }
          return KeychainError
            .operationFailed("Handler error during \(operation): \(underlyingError)")
        case .cancelled:
          return KeychainError.operationFailed("XPC operation failed during \(operation)")
        default:
          return KeychainError
            .operationFailed("XPC error during \(operation): \(error.localizedDescription)")
      }
    } else if let keychainError=error as? KeychainError {
      return keychainError
    }

    return KeychainError.operationFailed("Failed to \(operation): \(error.localizedDescription)")
  }

  /**
   Logs a message using the configured logger.

   - Parameters:
      - level: The log level
      - message: The message to log
   */
  private func log(_ level: LogLevel, _ message: String) async {
    if let logger {
      await logger.logMessage(level, message, context: .init(source: "KeychainXPCService"))
    }
  }
}

/**
 Factory for creating KeychainXPCService instances.
 */
public enum KeychainXPCServices {
  /**
   Creates a KeychainXPCService with the specified service name.

   - Parameters:
      - serviceName: The name of the XPC service bundle
      - serviceIdentifier: The service identifier for keychain items
      - logger: Optional logger for operation recording

   - Returns: A configured KeychainXPCService
   */
  public static func createService(
    serviceName: String,
    serviceIdentifier: String="dev.mpy.umbra.keychain",
    logger: LoggingProtocol?=nil
  ) async -> KeychainXPCService {
    let xpcService=await XPCServices.createService(
      serviceName: serviceName,
      logger: logger
    )

    return KeychainXPCService(
      xpcService: xpcService,
      serviceIdentifier: serviceIdentifier,
      logger: logger
    )
  }
}

/**
 Keychain item types for XPC requests.
 */
private enum KeychainItemType: String, Sendable, Codable {
  case password
  case data
}

/**
 XPC endpoints for keychain operations.
 */
private enum KeychainXPCEndpoint: String {
  case storePassword="umbra.keychain.store.password"
  case retrievePassword="umbra.keychain.retrieve.password"
  case storeData="umbra.keychain.store.data"
  case retrieveData="umbra.keychain.retrieve.data"
  case deleteItem="umbra.keychain.delete"
  case passwordExists="umbra.keychain.exists.password"
  case updatePassword="umbra.keychain.update.password"
}

/**
 Request to store an item in the keychain.
 */
private struct KeychainStoreRequest: Sendable, Codable {
  let type: KeychainItemType
  let account: String
  let serviceIdentifier: String
  let stringValue: String?
  let dataValue: Data?
  let accessOptions: KeychainAccessOptions?

  init(
    type: KeychainItemType,
    account: String,
    serviceIdentifier: String,
    stringValue: String?=nil,
    dataValue: Data?=nil,
    accessOptions: KeychainAccessOptions?=nil
  ) {
    self.type=type
    self.account=account
    self.serviceIdentifier=serviceIdentifier
    self.stringValue=stringValue
    self.dataValue=dataValue
    self.accessOptions=accessOptions
  }
}

/**
 Request to retrieve an item from the keychain.
 */
private struct KeychainRetrieveRequest: Sendable, Codable {
  let type: KeychainItemType
  let account: String
  let serviceIdentifier: String
}

/**
 Request to delete an item from the keychain.
 */
private struct KeychainDeleteRequest: Sendable, Codable {
  let type: KeychainItemType
  let account: String
  let serviceIdentifier: String
}

/**
 Request to check if an item exists in the keychain.
 */
private struct KeychainExistsRequest: Sendable, Codable {
  let account: String
  let serviceIdentifier: String
}

/**
 Response containing a string value from the keychain.
 */
private struct KeychainStringResponse: Sendable, Codable {
  let value: String
}

/**
 Response containing binary data from the keychain.
 */
private struct KeychainDataResponse: Sendable, Codable {
  let value: Data
}

/**
 Response containing a boolean value from the keychain.
 */
private struct KeychainBoolResponse: Sendable, Codable {
  let value: Bool
}
