import Foundation
import UmbraCoreTypes
import UmbraErrors
import UmbraErrorsCore

/// XPC Service Migration Examples
///
/// This file contains concrete examples of migrating from legacy XPC service protocols
/// to the modern XPCProtocolsCore implementations.
///
/// The examples show side-by-side comparisons of code before and after migration,
/// highlighting the improvements in error handling, async/await usage, and type safety.
public enum XPCMigrationExamples {
  // MARK: - Client Usage Examples

  /// Example of how to use legacy vs modern XPC service protocols in client code
  public static func clientUsageExample() {
    /*
     // BEFORE: Using legacy XPC service with completion handlers
     let legacyService = obtainLegacyXPCService()

     // Legacy API call with nested completion handlers - prone to callback hell
     legacyService.validateConnection { isValid, error in
         guard isValid, error == nil else {
             handleError(error)
             return
         }

         legacyService.encryptData(sensitiveData) { encryptedData, encryptError in
             guard let encryptedData = encryptedData, encryptError == nil else {
                 handleError(encryptError)
                 return
             }

             // More nested completion handlers...
             legacyService.storeSecurely(encryptedData, identifier: "user-data") { storeError in
                 if let storeError = storeError {
                     handleError(storeError)
                 } else {
                     operationComplete()
                 }
             }
         }
     }
     */

    /*
     // AFTER: Using modern XPC service with async/await and structured concurrency

     // Option 1: Create a new modern service
     let modernService = ModernXPCService()

     // Option 2: Migrate an existing legacy service using the factory
     // let modernService = XPCProtocolMigrationFactory.createCompleteAdapter()

     Task {
         // Modern API call with async/await - sequential, readable code
         let pingResult = await modernService.ping()

         guard case .success(true) = pingResult else {
             if case .failure(let error) = pingResult {
                 handleError(error)
             }
             return
         }

         // Clean error handling with Result type
         let encryptResult = await modernService.encrypt(data: sensitiveData)

         switch encryptResult {
         case .success(let encryptedData):
             // Store the encrypted data
             let storeResult = await modernService.storeSecurely(
                 encryptedData,
                 identifier: "user-data",
                 metadata: ["created": Date().ISO8601Format()]
             )

             if case .failure(let error) = storeResult {
                 handleError(error)
             } else {
                 operationComplete()
             }

         case .failure(let error):
             handleError(error)
         }
     }
     */
  }

  // MARK: - Service Implementation Examples

  /// Example of implementing a legacy vs modern XPC service
  public static func serviceImplementationExample() {
    /*
     // BEFORE: Legacy XPC service implementation with @objc compatibility

     class LegacyXPCService: XPCServiceProtocol {
         func validateConnection(withReply reply: @escaping (Bool, Error?) -> Void) {
             // Implementation
             reply(true, nil)
         }

         func getServiceVersion(withReply reply: @escaping (String) -> Void) {
             reply("1.0.0")
         }

         func encryptData(_ data: Data, withReply reply: @escaping (Data?, Error?) -> Void) {
             do {
                 let encryptedData = try performEncryption(data)
                 reply(encryptedData, nil)
             } catch {
                 reply(nil, error)
             }
         }

         func storeSecurely(_ data: Data, identifier: String, withReply reply: @escaping (Error?) -> Void) {
             do {
                 try saveToSecureStorage(data, identifier: identifier)
                 reply(nil)
             } catch {
                 reply(error)
             }
         }
     }
     */

    /*
     // AFTER: Modern XPC service implementation using protocol conformance

     class ModernXPCServiceImpl: XPCServiceProtocolComplete {
         // Implement required methods

         func ping() async -> Result<Bool, UmbraErrors.Security.Protocols> {
             return .success(true)
         }

         func getVersion() async -> Result<String, UmbraErrors.Security.Protocols> {
             return .success("2.0.0")
         }

         func encrypt(data: SecureBytes) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
             do {
                 let encryptedData = try performModernEncryption(data)
                 return .success(encryptedData)
             } catch {
                 return .failure(.cryptographicError(operation: "encryption", details: error.localizedDescription))
             }
         }

         func storeSecurely(
             _ data: SecureBytes,
             identifier: String,
             metadata: [String: String]?
         ) async -> Result<Void, UmbraErrors.Security.Protocols> {
             do {
                 try saveToModernSecureStorage(data, identifier: identifier, metadata: metadata)
                 return .success(())
             } catch {
                 return .failure(.operationFailed(operation: "storage", reason: error.localizedDescription))
             }
         }
     }
     */
  }

  // MARK: - Gradual Migration Examples

  /// Example of gradually migrating from legacy to modern XPC services
  public static func gradualMigrationExample() {
    /*
     // LEGACY APPROACH (Historical Reference Only)
     // This code example shows how a legacy implementation might have looked.
     // Modern implementations should use the approach shown in Step 2 directly.
     class MyAppXPCManager {
         private let legacyService: OldXPCService

         init() {
             self.legacyService = OldXPCService()
         }

         func encryptUserData(_ data: Data, completion: @escaping (Data?, Error?) -> Void) {
             legacyService.encryptData(data, withReply: completion)
         }
     }

     // MODERN APPROACH (Recommended Implementation)
     class MyAppXPCManager {
         private let modernService: any XPCServiceProtocolComplete

         init() {
             // Use the factory to create a modern service
             self.modernService = XPCProtocolMigrationFactory.createCompleteAdapter()
         }

         // Legacy interface preserved for backward compatibility
         func encryptUserData(_ data: Data, completion: @escaping (Data?, Error?) -> Void) {
             Task {
                 // Convert Data to SecureBytes
                 let secureData = SecureBytes(bytes: [UInt8](data))

                 // Use modern API
                 let result = await modernService.encrypt(data: secureData)

                 // Map back to legacy completion handler
                 switch result {
                 case .success(let encrypted):
                     completion(Data(encrypted), nil)
                 case .failure(let error):
                     completion(nil, error)
                 }
             }
         }

         // Modern interface using async/await
         func encryptUserData(_ data: Data) async -> Result<Data, Error> {
             let secureData = SecureBytes(bytes: [UInt8](data))
             let result = await modernService.encrypt(data: secureData)
             return result.map { Data($0) }
         }
     }
     */
  }

  // MARK: - Helper Functions

  private static func handleError(_: Error?) {
    // Example implementation
  }

  private static func operationComplete() {
    // Example implementation
  }
}

// MARK: - Migration Helper Functions

/// Extension providing helper functions for use in migrations
extension XPCMigrationExamples {
  /// Demo helper to convert Data to SecureBytes
  ///
  /// Example of how to convert legacy Data types
  /// to modern code that uses SecureBytes
  static func convertDataToSecureBytes(_ data: Data) -> SecureBytes {
    SecureBytes(bytes: [UInt8](data))
  }

  /// Demo helper to convert Error to UmbraErrors.Security.Protocols
  ///
  /// This is provided as a reference for migrating legacy code that uses Error
  /// to modern code that uses UmbraErrors.Security.Protocols
  static func convertLegacyError(_ error: Error) -> ErrorHandlingDomains.UmbraErrors.Security
  .Protocols {
    // If it's already the correct type, return it
    if let securityError=error as? UmbraErrors.Security.Protocols {
      return securityError
    }

    // Otherwise map based on error properties
    let errorObject=error as NSError
    let errorDomain=errorObject.domain
    let code=errorObject.code
    let description=error.localizedDescription

    if errorDomain.contains("encryption") {
      return .cryptographicError(
        operation: "encryption",
        details: "Error \(code): \(description)"
      )
    } else if errorDomain.contains("storage") {
      return .invalidState(details: "Storage error: \(description)")
    } else if errorDomain.contains("key") {
      return .keyGenerationFailed(reason: "Error \(code): \(description)")
    } else if errorDomain.contains("signature") {
      return .cryptographicError(operation: "signature", details: "Error \(code): \(description)")
    }

    // Default error case
    return .internalError(reason: error.localizedDescription)
  }
}
