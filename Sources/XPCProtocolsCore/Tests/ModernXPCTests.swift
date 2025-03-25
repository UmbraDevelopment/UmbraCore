import Foundation
import XCTest
@testable import XPCProtocolsCore

@available(macOS 14.0, *)
final class ModernXPCTests: XCTestCase {
    
    // MARK: - XPCError Tests
    
    func testXPCErrorDescription() {
        let errors: [XPCError] = [
            .connectionFailed("Failed to connect"),
            .messageFailed("Failed to send"),
            .invalidMessage("Invalid format"),
            .connectionError(message: "Connection dropped"),
            .invalidRequest(message: "Bad request"),
            .operationCancelled(reason: "User cancelled"),
            .timeout(operation: "Key exchange"),
            .securityValidationFailed(reason: "Invalid signature"),
            .serviceUnavailable(name: "CryptoService"),
            .invalidData(message: "Corrupted data"),
            .serviceError(category: .crypto, underlying: NSError(domain: "test", code: 1), message: "Crypto failed")
        ]
        
        // Test that all error types have descriptions
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
        }
        
        // Test specific error descriptions
        XCTAssertEqual(XPCError.connectionFailed("Test").errorDescription, 
                      "[Connection] XPC connection failed: Test")
        XCTAssertEqual(XPCError.messageFailed("Test").errorDescription, 
                      "[Message] Failed to send XPC message: Test")
        XCTAssertEqual(XPCError.invalidMessage("Test").errorDescription, 
                      "[Message] Invalid XPC message format: Test")
    }
    
    func testXPCErrorRecoverability() {
        // Test recoverable errors
        let recoverableErrors: [XPCError] = [
            .connectionError(message: "Connection dropped"),
            .timeout(operation: "Key exchange"),
            .serviceUnavailable(name: "CryptoService"),
            .connectionFailed("Connection failed"),
            .serviceError(category: .connection, underlying: NSError(domain: "test", code: 1), message: "Connection error")
        ]
        
        for error in recoverableErrors {
            XCTAssertTrue(error.isRecoverable, "Error should be recoverable: \(error)")
        }
        
        // Test non-recoverable errors
        let nonRecoverableErrors: [XPCError] = [
            .invalidRequest(message: "Bad request"),
            .operationCancelled(reason: "User cancelled"),
            .securityValidationFailed(reason: "Invalid signature"),
            .messageFailed("Message failed"),
            .invalidMessage("Invalid message"),
            .invalidData(message: "Corrupted data"),
            .serviceError(category: .crypto, underlying: NSError(domain: "test", code: 1), message: "Crypto failed")
        ]
        
        for error in nonRecoverableErrors {
            XCTAssertFalse(error.isRecoverable, "Error should not be recoverable: \(error)")
        }
    }
    
    func testXPCErrorConversion() {
        // Test conversion to Security Protocol Error
        let xpcError = XPCError.connectionFailed("Test connection")
        
        // Verify the error has a localized description
        XCTAssertTrue(xpcError.localizedDescription.contains("Test connection"))
    }
    
    // MARK: - XPCConnectionManager Tests
    
    func testXPCConnectionManagerCreation() async throws {
        // Create a mock protocol
        class MockProtocol: NSObject {}
        let mockProtocolObj = MockProtocol()
        
        // Create the manager
        let manager = XPCConnectionManager(serviceName: "com.test.service", 
                                          interfaceProtocol: MockProtocol.self)
        
        // Test that the manager was created successfully
        XCTAssertNotNil(manager)
    }
    
    func testXPCConnectionManagerInvalidation() async throws {
        // Skip this test in CI environments where XPC connections can't be established
        guard ProcessInfo.processInfo.environment["CI"] == nil else {
            return
        }
        
        // Create a mock protocol
        class MockProtocol: NSObject {}
        
        // Create the manager
        let manager = XPCConnectionManager(serviceName: "com.test.service", 
                                          interfaceProtocol: MockProtocol.self)
        
        // Test invalidation
        manager.invalidateAll()
        
        // Test invalidating a specific connection
        manager.invalidateConnection(for: "com.test.service")
    }
    
    // MARK: - XPCConnection Protocol Tests
    
    func testXPCConnectionProtocolImplementation() async {
        // Create a mock implementation of XPCConnectionProtocol
        actor MockXPCConnection: XPCConnectionProtocol {
            var connectCalled = false
            var disconnectCalled = false
            var sendCalled = false
            
            var endpoint: String {
                return "com.test.mockservice"
            }
            
            func connect() async throws {
                connectCalled = true
            }
            
            func disconnect() {
                disconnectCalled = true
            }
            
            func send(_ message: [String: Any], replyHandler: ((xpc_object_t) -> Void)?) {
                sendCalled = true
            }
        }
        
        // Create an instance and test the protocol methods
        let connection = MockXPCConnection()
        
        try? await connection.connect()
        XCTAssertTrue(await connection.connectCalled)
        
        await connection.disconnect()
        XCTAssertTrue(await connection.disconnectCalled)
        
        await connection.send(["test": "value"], replyHandler: nil)
        XCTAssertTrue(await connection.sendCalled)
        
        XCTAssertEqual(await connection.endpoint, "com.test.mockservice")
    }
}
