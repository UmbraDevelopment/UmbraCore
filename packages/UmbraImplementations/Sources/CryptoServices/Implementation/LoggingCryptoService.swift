import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # Logging Crypto Service

 A wrapper implementation that adds logging capabilities to any CryptoServiceProtocol.
 This follows the decorator pattern from the Alpha Dot Five architecture, allowing
 logging to be added to any implementation without modifying it.

 This service logs information about:
 - Operation types and parameters
 - Success or failure status
 - Performance metrics
 - Error details when applicable

 All logs use British spelling conventions.
 */
public actor LoggingCryptoService: CryptoServiceProtocol {
  /// The wrapped implementation
  private let wrapped: any CryptoServiceProtocol

  /// The logger to use for recording operations
  private let logger: any LoggingProtocol

  /// Source identifier for logging
  private let sourceID="CryptoServices"

  /// Initialises a new logging wrapper around a crypto service
  /// - Parameters:
  ///   - wrapping: The service to wrap with logging
  ///   - logger: The logger to use
  public init(wrapping: any CryptoServiceProtocol, logger: any LoggingProtocol) {
    wrapped=wrapping
    self.logger=logger
    Task {
      await self.logger.debug(
        "Created LoggingCryptoService wrapper",
        metadata: nil,
        source: sourceID
      )
    }
  }

  /**
   Logs and forwards encryption operation to the wrapped implementation.

   - Parameters:
     - data: Data to encrypt
     - key: Encryption key
     - iv: Initialisation vector
   - Returns: Encrypted data from the wrapped implementation
   - Throws: Rethrows any errors from the wrapped implementation
   */
  public func encrypt(
    _ data: SecureBytes,
    using key: SecureBytes,
    iv: SecureBytes
  ) async throws -> SecureBytes {
    let startTime=DispatchTime.now()
    await logger.info("Encrypting \(data.count) bytes of data", metadata: nil, source: sourceID)

    do {
      let result=try await wrapped.encrypt(data, using: key, iv: iv)
      let endTime=DispatchTime.now()
      let durationNano=endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
      let durationMs=Double(durationNano) / 1_000_000

      await logger.info(
        "Successfully encrypted \(data.count) bytes to \(result.count) bytes in \(String(format: "%.2f", durationMs))ms",
        metadata: nil,
        source: sourceID
      )
      return result
    } catch {
      await logger.error(
        "Encryption failed: \(error.localizedDescription)",
        metadata: nil,
        source: sourceID
      )
      throw error
    }
  }

  /**
   Logs and forwards decryption operation to the wrapped implementation.

   - Parameters:
     - data: Data to decrypt
     - key: Decryption key
     - iv: Initialisation vector
   - Returns: Decrypted data from the wrapped implementation
   - Throws: Rethrows any errors from the wrapped implementation
   */
  public func decrypt(
    _ data: SecureBytes,
    using key: SecureBytes,
    iv: SecureBytes
  ) async throws -> SecureBytes {
    let startTime=DispatchTime.now()
    await logger.info("Decrypting \(data.count) bytes of data", metadata: nil, source: sourceID)

    do {
      let result=try await wrapped.decrypt(data, using: key, iv: iv)
      let endTime=DispatchTime.now()
      let durationNano=endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
      let durationMs=Double(durationNano) / 1_000_000

      await logger.info(
        "Successfully decrypted \(data.count) bytes to \(result.count) bytes in \(String(format: "%.2f", durationMs))ms",
        metadata: nil,
        source: sourceID
      )
      return result
    } catch {
      await logger.error(
        "Decryption failed: \(error.localizedDescription)",
        metadata: nil,
        source: sourceID
      )
      throw error
    }
  }

  /**
   Logs and forwards key derivation operation to the wrapped implementation.

   - Parameters:
     - password: Password to derive key from
     - salt: Salt for key derivation
     - iterations: Number of iterations for key derivation
   - Returns: Derived key from the wrapped implementation
   - Throws: Rethrows any errors from the wrapped implementation
   */
  public func deriveKey(
    from password: String,
    salt: SecureBytes,
    iterations: Int
  ) async throws -> SecureBytes {
    let startTime=DispatchTime.now()
    await logger.info(
      "Deriving key from password using \(iterations) iterations",
      metadata: nil,
      source: sourceID
    )

    do {
      let result=try await wrapped.deriveKey(from: password, salt: salt, iterations: iterations)
      let endTime=DispatchTime.now()
      let durationNano=endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
      let durationMs=Double(durationNano) / 1_000_000

      await logger.info(
        "Successfully derived \(result.count)-byte key in \(String(format: "%.2f", durationMs))ms",
        metadata: nil,
        source: sourceID
      )
      return result
    } catch {
      await logger.error(
        "Key derivation failed: \(error.localizedDescription)",
        metadata: nil,
        source: sourceID
      )
      throw error
    }
  }

  /**
   Logs and forwards secure random key generation to the wrapped implementation.

   - Parameter length: Length of the key in bytes
   - Returns: Generated key from the wrapped implementation
   - Throws: Rethrows any errors from the wrapped implementation
   */
  public func generateSecureRandomKey(length: Int) async throws -> SecureBytes {
    let startTime=DispatchTime.now()
    await logger.info(
      "Generating secure random key of \(length) bytes",
      metadata: nil,
      source: sourceID
    )

    do {
      let result=try await wrapped.generateSecureRandomKey(length: length)
      let endTime=DispatchTime.now()
      let durationNano=endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
      let durationMs=Double(durationNano) / 1_000_000

      await logger.info(
        "Successfully generated \(result.count)-byte secure random key in \(String(format: "%.2f", durationMs))ms",
        metadata: nil,
        source: sourceID
      )
      return result
    } catch {
      await logger.error(
        "Secure random key generation failed: \(error.localizedDescription)",
        metadata: nil,
        source: sourceID
      )
      throw error
    }
  }

  /**
   Logs and forwards HMAC generation to the wrapped implementation.

   - Parameters:
     - data: Data to authenticate
     - key: Authentication key
   - Returns: Authentication code from the wrapped implementation
   - Throws: Rethrows any errors from the wrapped implementation
   */
  public func generateHMAC(
    for data: SecureBytes,
    using key: SecureBytes
  ) async throws -> SecureBytes {
    let startTime=DispatchTime.now()
    await logger.info(
      "Generating HMAC for \(data.count) bytes of data",
      metadata: nil,
      source: sourceID
    )

    do {
      let result=try await wrapped.generateHMAC(for: data, using: key)
      let endTime=DispatchTime.now()
      let durationNano=endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
      let durationMs=Double(durationNano) / 1_000_000

      await logger.info(
        "Successfully generated \(result.count)-byte HMAC in \(String(format: "%.2f", durationMs))ms",
        metadata: nil,
        source: sourceID
      )
      return result
    } catch {
      await logger.error(
        "HMAC generation failed: \(error.localizedDescription)",
        metadata: nil,
        source: sourceID
      )
      throw error
    }
  }
}
