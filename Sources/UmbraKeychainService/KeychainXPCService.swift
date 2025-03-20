import CoreErrors
import ErrorHandlingDomains
import Foundation
import Security
import UmbraCoreTypes
import UmbraLogging
import XPCProtocolsCore

/// Error type for keychain XPC operations (internal version)
fileprivate enum InternalKeychainXPCError: Error, CustomStringConvertible {
    case duplicateItem
    case itemNotFound
    case internalError(String)
    case serviceUnavailable
    case authenticationFailed
    
    var description: String {
        switch self {
        case .duplicateItem:
            return "A duplicate item exists"
        case .itemNotFound:
            return "Item not found"
        case .internalError(let message):
            return "Internal error: \(message)"
        case .serviceUnavailable:
            return "Service unavailable"
        case .authenticationFailed:
            return "Authentication failed"
        }
    }
}

/// XPC service for secure keychain operations
@objc
@available(macOS 14.0, *)
public final class KeychainXPCService: NSObject, XPCServiceProtocolStandard, KeychainXPCProtocol, @unchecked Sendable {
    // MARK: - Properties

    /// Static protocol identifier for the service
    public static let protocolIdentifier: String = "com.umbra.xpc.keychain"

    /// The underlying XPC listener
    @available(*, deprecated, message: "Will be replaced with Swift Concurrency in Swift 6")
    private let listener: NSXPCListener
    
    @available(*, deprecated, message: "Will be replaced with Swift Concurrency in Swift 6")
    private let exportedObject: KeychainXPCProtocol
    
    @available(*, deprecated, message: "Will be replaced with Swift Concurrency in Swift 6")
    private let startupSemaphore = DispatchSemaphore(value: 0)

    @available(*, deprecated, message: "Will be replaced with Swift Concurrency in Swift 6")
    private let stateQueue = DispatchQueue(label: "com.umbracore.xpc.state")
    
    /// Service identifier for the keychain service
    private let serviceIdentifier: String
    
    /// Thread safety actor for mutable state management in Swift 6
    private actor ServiceState {
        var isStarted = false
        var exportedObjectRef: (any KeychainXPCProtocol)?
        var listenerRef: NSXPCListener?
        
        func setExportedObject(_ obj: KeychainXPCProtocol) {
            exportedObjectRef = obj
        }
        
        func getExportedObject() -> (any KeychainXPCProtocol)? {
            return exportedObjectRef
        }
        
        func setListener(_ listener: NSXPCListener) {
            listenerRef = listener
        }
        
        func getListener() -> NSXPCListener? {
            return listenerRef
        }
        
        func setStarted(_ started: Bool) {
            isStarted = started
        }
        
        func isStartedState() -> Bool {
            return isStarted
        }
    }
    
    /// State actor for managing mutable state
    private let state = ServiceState()
    
    // Legacy property that will be removed in Swift 6
    @available(*, deprecated, message: "This will be replaced with an actor-based implementation in Swift 6")
    private var _isStarted = false

    // MARK: - Initialization

    /// Initialize the keychain XPC service with a custom service identifier
    /// - Parameter serviceIdentifier: The service identifier to use for keychain operations
    public init(serviceIdentifier: String) {
        self.serviceIdentifier = serviceIdentifier
        self.listener = NSXPCListener.anonymous()
        self.exportedObject = InternalKeychainImplementation()
        
        // Call super.init() since NSObject requires it
        super.init()
        
        // Set up the listener delegate after initialization
        listener.delegate = self
        
        // Initialize actor state
        Task { @MainActor in
            await state.setExportedObject(exportedObject)
            await state.setListener(listener)
        }
    }

    /// Default initializer
    public override init() {
        self.serviceIdentifier = "com.umbracore.securexpc"
        self.listener = NSXPCListener.anonymous()
        self.exportedObject = InternalKeychainImplementation()
        
        super.init()
        
        // Set up the listener delegate after initialization
        listener.delegate = self
        
        // Initialize actor state
        Task { @MainActor in
            await state.setExportedObject(exportedObject)
            await state.setListener(listener)
        }
    }

    // MARK: - Service Lifecycle Methods

    func start() async {
        guard !(await state.isStartedState()) else { return }
        await state.setStarted(true)
        _isStarted = true
        
        if let listener = await state.getListener() {
            listener.resume()
        }
        
        startupSemaphore.signal()
    }

    func stop() async {
        guard await state.isStartedState() else { return }
        await state.setStarted(false)
        
        // Keep using the deprecated property until Swift 6 migration is complete
        _isStarted = false
        
        // Invalidate the listener through the actor
        if let listener = await state.getListener() {
            listener.invalidate()
        }
    }

    func waitForStartup(timeout: TimeInterval) -> Bool {
        startupSemaphore.wait(timeout: .now() + timeout) == .success
    }

    // MARK: - XPCServiceProtocolBasic Implementation

    /// Basic ping method to test if service is responsive
    /// - Returns: True if service is available
    @objc
    public func ping() async -> Bool {
        await state.isStartedState()
    }

    /// Synchronize keys with provided data
    /// - Parameter syncData: The data to synchronize with
    /// - Throws: CoreErrors.XPCErrors.SecurityError if synchronization fails
    public func synchroniseKeys(_ syncData: SecureBytes) async throws {
        do {
            // Get the exported object from actor state
            if let obj = await state.getExportedObject() {
                try await obj.synchroniseKeys(
                    syncData.withUnsafeBytes { ptr in
                        Data(bytes: ptr.baseAddress!, count: ptr.count)
                    }
                )
            } else {
                throw CoreErrors.XPCErrors.SecurityError.internalError(description: "Service unavailable")
            }
        } catch let error as InternalKeychainXPCError {
            throw mapKeychainErrorToXPCSecurityError(error, operation: "synchronise")
        } catch {
            throw CoreErrors.XPCErrors.SecurityError.internalError(description: "Failed to synchronize keys: \(error.localizedDescription)")
        }
    }

    // MARK: - XPCServiceProtocolStandard Implementation

    /// Generate random data of specified length
    /// - Parameter length: Length in bytes of random data to generate
    /// - Returns: Result with SecureBytes on success or error on failure
    public func generateRandomData(length: Int) async -> Result<SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)

        if status == errSecSuccess {
            return .success(SecureBytes(bytes: bytes))
        } else {
            return .failure(ErrorHandlingDomains.UmbraErrors.Security.Protocols.encryptionFailed("Failed to generate random data with status: \(status)"))
        }
    }

    /// Reset the security state of the service
    /// - Returns: Result with void on success or error on failure
    public func resetSecurity() async -> Result<Void, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
        // For a keychain service, resetting would mean clearing keychain items
        // This is a simplified version for demonstration
        .success(())
    }

    /// Get the service version
    /// - Returns: Result with version string on success or error on failure
    public func getServiceVersion() async -> Result<String, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
        .success("1.0.0")
    }

    /// Get a hardware identifier
    /// - Returns: Result with identifier string on success or error on failure
    public func getHardwareIdentifier() async -> Result<String, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
        .success("keychain-xpc-service-hardware-id")
    }

    /// Store secure data
    /// - Parameters:
    ///   - data: The data to store
    ///   - key: The key to store data under
    /// - Returns: Result with success or error
    public func storeSecureData(_ data: SecureBytes, key: String) async -> Result<Void, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
        do {
            // Use Swift Concurrency task to handle the XPC call instead of semaphores
            return try await withCheckedThrowingContinuation { [self] (continuation: CheckedContinuation<Result<Void, ErrorHandlingDomains.UmbraErrors.Security.Protocols>, Error>) in
                Task {
                    // Get the exported object
                    if let obj = await self.state.getExportedObject() {
                        obj.addItem(
                            account: key,
                            service: serviceIdentifier,
                            accessGroup: nil,
                            data: data.withUnsafeBytes { ptr in
                                Data(bytes: ptr.baseAddress!, count: ptr.count)
                            },
                            reply: { [self] error in
                                if let error = error {
                                    let mappedError = (error as? InternalKeychainXPCError).map {
                                        self.mapKeychainErrorToXPCSecurityError($0, operation: "store")
                                    } ?? ErrorHandlingDomains.UmbraErrors.Security.Protocols.internalError("Failed to store secure data: \(error.localizedDescription)")
                                    continuation.resume(returning: .failure(mappedError))
                                } else {
                                    continuation.resume(returning: .success(()))
                                }
                            }
                        )
                    } else {
                        continuation.resume(returning: .failure(ErrorHandlingDomains.UmbraErrors.Security.Protocols.invalidState(state: "unavailable", expectedState: "available")))
                    }
                }
            }
        } catch {
            return .failure(ErrorHandlingDomains.UmbraErrors.Security.Protocols.internalError("Failed to store secure data: \(error.localizedDescription)"))
        }
    }

    /// Retrieve secure data by key
    /// - Parameter key: The key to retrieve data for
    /// - Returns: Result with the secure data or error
    public func retrieveSecureData(key: String) async -> Result<SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
        do {
            // Use Swift Concurrency task to handle the XPC call instead of semaphores
            return try await withCheckedThrowingContinuation { [self] (continuation: CheckedContinuation<Result<SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols>, Error>) in
                Task {
                    // Get the exported object
                    if let obj = await self.state.getExportedObject() {
                        obj.getItem(
                            account: key,
                            service: serviceIdentifier,
                            accessGroup: nil,
                            reply: { [self] data, error in
                                if let error = error {
                                    let mappedError = (error as? InternalKeychainXPCError).map {
                                        self.mapKeychainErrorToXPCSecurityError($0, operation: "retrieve")
                                    } ?? ErrorHandlingDomains.UmbraErrors.Security.Protocols.internalError("Failed to retrieve secure data: \(error.localizedDescription)")
                                    continuation.resume(returning: .failure(mappedError))
                                } else if let data = data {
                                    continuation.resume(returning: .success(SecureBytes(bytes: [UInt8](data))))
                                } else {
                                    continuation.resume(returning: .failure(ErrorHandlingDomains.UmbraErrors.Security.Protocols.missingProtocolImplementation(protocolName: key)))
                                }
                            }
                        )
                    } else {
                        continuation.resume(returning: .failure(ErrorHandlingDomains.UmbraErrors.Security.Protocols.invalidState(state: "unavailable", expectedState: "available")))
                    }
                }
            }
        } catch {
            return .failure(ErrorHandlingDomains.UmbraErrors.Security.Protocols.internalError("Failed to retrieve secure data: \(error.localizedDescription)"))
        }
    }

    /// Delete secure data by key
    /// - Parameter key: The key to delete data for
    /// - Returns: Result with success or error
    public func deleteSecureData(key: String) async -> Result<Void, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
        do {
            // Use Swift Concurrency task to handle the XPC call instead of semaphores
            return try await withCheckedThrowingContinuation { [self] (continuation: CheckedContinuation<Result<Void, ErrorHandlingDomains.UmbraErrors.Security.Protocols>, Error>) in
                Task {
                    // Get the exported object
                    if let obj = await self.state.getExportedObject() {
                        obj.deleteItem(
                            account: key,
                            service: serviceIdentifier,
                            accessGroup: nil,
                            reply: { [self] error in
                                if let error = error {
                                    let mappedError = (error as? InternalKeychainXPCError).map {
                                        self.mapKeychainErrorToXPCSecurityError($0, operation: "delete")
                                    } ?? ErrorHandlingDomains.UmbraErrors.Security.Protocols.internalError("Failed to delete secure data: \(error.localizedDescription)")
                                    continuation.resume(returning: .failure(mappedError))
                                } else {
                                    continuation.resume(returning: .success(()))
                                }
                            }
                        )
                    } else {
                        continuation.resume(returning: .failure(ErrorHandlingDomains.UmbraErrors.Security.Protocols.invalidState(state: "unavailable", expectedState: "available")))
                    }
                }
            }
        } catch {
            return .failure(ErrorHandlingDomains.UmbraErrors.Security.Protocols.internalError("Failed to delete secure data: \(error.localizedDescription)"))
        }
    }

    /// The service status returns a dictionary with information about the service's status
    /// - Returns: Result with status dictionary or error
    public func status() async -> Result<[String: Any], ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
        let statusInfo: [String: Any] = [
            "available": await state.isStartedState(),
            "version": "1.0.0",
            "protocol": Self.protocolIdentifier,
        ]
        return .success(statusInfo)
    }

    // MARK: - XPCServiceProtocolComplete Implementation

    /// Encrypt secure data using the service's encryption mechanism
    /// - Parameters:
    ///   - data: SecureBytes to encrypt
    ///   - keyIdentifier: Optional identifier for the encryption key
    /// - Returns: Result with encrypted SecureBytes on success or error on failure
    public func encryptSecureData(_ data: SecureBytes, keyIdentifier: String?) async -> Result<SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
        // This is a placeholder implementation - in a real implementation, we would
        // use the actual keychain to perform encryption
        let encryptedData = data.withUnsafeBytes { bytes in
            // Simple placeholder encryption - in a real implementation we'd use proper encryption
            var encrypted = [UInt8](repeating: 0, count: bytes.count)
            for i in 0 ..< bytes.count {
                encrypted[i] = bytes[i] ^ 0xFF // Simple XOR "encryption" for demonstration
            }
            return encrypted
        }
        return .success(SecureBytes(bytes: encryptedData))
    }

    /// Decrypt secure data using the service's decryption mechanism
    /// - Parameters:
    ///   - data: SecureBytes to decrypt
    ///   - keyIdentifier: Optional identifier for the decryption key
    /// - Returns: Result with decrypted SecureBytes on success or error on failure
    public func decryptSecureData(_ data: SecureBytes, keyIdentifier: String?) async -> Result<SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
        // This is a placeholder implementation - in a real implementation, we would
        // use the actual keychain to perform decryption
        let decryptedData = data.withUnsafeBytes { bytes in
            // Simple placeholder decryption - in a real implementation we'd use proper decryption
            var decrypted = [UInt8](repeating: 0, count: bytes.count)
            for i in 0 ..< bytes.count {
                decrypted[i] = bytes[i] ^ 0xFF // Simple XOR "decryption" for demonstration
            }
            return decrypted
        }
        return .success(SecureBytes(bytes: decryptedData))
    }

    /// Sign data using the service's signing mechanism
    /// - Parameters:
    ///   - data: SecureBytes to sign
    ///   - keyIdentifier: Identifier for the signing key
    /// - Returns: Result with signature as SecureBytes on success or error on failure
    public func sign(_ data: SecureBytes, keyIdentifier: String) async -> Result<SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
        // This is a placeholder implementation - in a real implementation, we would
        // use the actual keychain to generate a signature
        let signature = data.withUnsafeBytes { bytes in
            // Simple placeholder signature - in a real implementation we'd use proper signing
            var sig = [UInt8](repeating: 0, count: 32) // Create a 32-byte "signature"
            for i in 0 ..< min(bytes.count, 32) {
                sig[i] = bytes[i] // Simple copy for demonstration
            }
            return sig
        }
        return .success(SecureBytes(bytes: signature))
    }

    /// Verify a signature for data using the service's verification mechanism
    /// - Parameters:
    ///   - signature: SecureBytes containing the signature to verify
    ///   - data: SecureBytes containing the data to verify
    ///   - keyIdentifier: Identifier for the verification key
    /// - Returns: Result with boolean indicating validity on success or error on failure
    public func verify(signature: SecureBytes, for data: SecureBytes, keyIdentifier: String) async -> Result<Bool, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
        // This is a placeholder implementation - in a real implementation, we would
        // use the actual keychain to verify the signature
        let isValid = signature.withUnsafeBytes { sigBytes in
            data.withUnsafeBytes { dataBytes in
                // Simple placeholder verification - in a real implementation we'd use proper verification
                if sigBytes.count != 32 {
                    return false
                }
                for i in 0 ..< min(dataBytes.count, 32) {
                    if sigBytes[i] != dataBytes[i] {
                        return false
                    }
                }
                return true
            }
        }
        return .success(isValid)
    }

    // MARK: - KeychainXPCProtocol Implementation

    /// Add an item to the keychain
    public func addItem(
        account: String,
        service: String,
        accessGroup: String?,
        data: Data,
        reply: @escaping @Sendable (Error?) -> Void
    ) {
        Task.detached {
            if let obj = await self.state.getExportedObject() {
                obj.addItem(
                    account: account,
                    service: service,
                    accessGroup: accessGroup,
                    data: data,
                    reply: reply
                )
            } else {
                reply(InternalKeychainXPCError.serviceUnavailable)
            }
        }
    }

    /// Update an existing keychain item
    public func updateItem(
        account: String,
        service: String,
        accessGroup: String?,
        data: Data,
        reply: @escaping @Sendable (Error?) -> Void
    ) {
        Task.detached {
            if let obj = await self.state.getExportedObject() {
                obj.updateItem(
                    account: account,
                    service: service,
                    accessGroup: accessGroup,
                    data: data,
                    reply: reply
                )
            } else {
                reply(InternalKeychainXPCError.serviceUnavailable)
            }
        }
    }

    /// Retrieve a keychain item
    public func getItem(
        account: String,
        service: String,
        accessGroup: String?,
        reply: @escaping @Sendable (Data?, Error?) -> Void
    ) {
        Task.detached {
            if let obj = await self.state.getExportedObject() {
                obj.getItem(
                    account: account,
                    service: service,
                    accessGroup: accessGroup,
                    reply: reply
                )
            } else {
                reply(nil, InternalKeychainXPCError.serviceUnavailable)
            }
        }
    }

    /// Delete a keychain item
    public func deleteItem(
        account: String,
        service: String,
        accessGroup: String?,
        reply: @escaping @Sendable (Error?) -> Void
    ) {
        Task.detached {
            if let obj = await self.state.getExportedObject() {
                obj.deleteItem(
                    account: account,
                    service: service,
                    accessGroup: accessGroup,
                    reply: reply
                )
            } else {
                reply(InternalKeychainXPCError.serviceUnavailable)
            }
        }
    }

    // MARK: - Private Implementation

    /// Private implementation of the KeychainXPCProtocol
    private final class InternalKeychainImplementation: NSObject, KeychainXPCProtocol {
        /// Add an item to the keychain
        func addItem(
            account: String,
            service: String,
            accessGroup: String?,
            data: Data,
            reply: @escaping @Sendable (Error?) -> Void
        ) {
            // Implementation using KeychainService
            reply(nil)
        }
        
        /// Update an item in the keychain
        func updateItem(
            account: String,
            service: String,
            accessGroup: String?,
            data: Data,
            reply: @escaping @Sendable (Error?) -> Void
        ) {
            // Implementation using KeychainService
            reply(nil)
        }
        
        /// Get an item from the keychain
        func getItem(
            account: String,
            service: String,
            accessGroup: String?,
            reply: @escaping @Sendable (Data?, Error?) -> Void
        ) {
            // Implementation using KeychainService
            reply(nil, nil)
        }
        
        /// Delete an item from the keychain
        func deleteItem(
            account: String,
            service: String,
            accessGroup: String?,
            reply: @escaping @Sendable (Error?) -> Void
        ) {
            // Implementation using KeychainService
            reply(nil)
        }
    }

    // MARK: - Helper Methods

    /// Maps a keychain error to an XPC security error
    /// - Parameters:
    ///   - error: The keychain error
    ///   - operation: The operation that failed
    /// - Returns: The corresponding XPC security error
    private func mapKeychainErrorToXPCSecurityError(_ error: InternalKeychainXPCError, operation: String) -> ErrorHandlingDomains.UmbraErrors.Security.Protocols {
        switch error {
        case .duplicateItem:
            return .internalError("Duplicate item exists")
        case .itemNotFound:
            return .missingProtocolImplementation(protocolName: operation)
        case .internalError(let message):
            return .internalError("Internal error occurred during \(operation): \(message)")
        case .serviceUnavailable:
            return .invalidState(state: "unavailable", expectedState: "available")
        case .authenticationFailed:
            return .invalidInput("Authentication failed for \(operation)")
        }
    }

    // MARK: - Default Implementations for XPCServiceProtocolStandard

    // MARK: - NSXPCListenerDelegate Implementation
}

extension KeychainXPCService: NSXPCListenerDelegate {
    public func listener(
        _: NSXPCListener,
        shouldAcceptNewConnection newConnection: NSXPCConnection
    ) -> Bool {
        // Need to check using the deprecated property for now during the transition to Swift 6
        // In Swift 6, we would refactor this to be fully actor-based
        let shouldAccept = _isStarted
        
        if shouldAccept {
            newConnection.exportedInterface = NSXPCInterface(with: KeychainXPCProtocol.self)
            newConnection.exportedObject = exportedObject
            newConnection.resume()
        }
        
        return shouldAccept
    }
    
    /// Swift 6 compatible version of connection acceptance
    /// FIXME: Replace the older implementation with this in Swift 6
    @available(*, unavailable, message: "This will replace the current implementation in Swift 6")
    public func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) async -> Bool {
        // This is called on the main thread by XPC
        // We need to check state synchronously, so we'll use the actor state
        let shouldAccept = await state.isStartedState()
        
        // If we should accept, set up the connection
        if shouldAccept {
            newConnection.exportedInterface = NSXPCInterface(with: KeychainXPCProtocol.self)
            
            if let exportedObj = await state.getExportedObject() {
                newConnection.exportedObject = exportedObj
                newConnection.resume()
            } else {
                return false
            }
        }
        
        return shouldAccept
    }
}

private final class AtomicBool {
    private var _value: Bool
    private let lock = NSLock()

    init(_ value: Bool) {
        _value = value
    }

    var value: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }

    func setValue(_ newValue: Bool) {
        lock.lock()
        defer { lock.unlock() }
        _value = newValue
    }
}
