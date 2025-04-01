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
  private let sourceID = "CryptoServices"

  /// Initialises a new logging wrapper around a crypto service
  /// - Parameters:
  ///   - wrapping: The service to wrap with logging
  ///   - logger: The logger to use
  public init(wrapping: any CryptoServiceProtocol, logger: any LoggingProtocol) {
    wrapped = wrapping
    self.logger = logger
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
     - cryptoOptions: Optional encryption configuration
   - Returns: Encrypted data from the wrapped implementation
   - Throws: Rethrows any errors from the wrapped implementation
   */
  public func encrypt(
    _ data: Data,
    using key: Data,
    iv: Data,
    cryptoOptions: CryptoOptions?
  ) async throws -> Data {
    let startTime = DispatchTime.now()
    await logger.info("Encrypting \(data.count) bytes of data", metadata: nil, source: sourceID)

    do {
      let result = try await wrapped.encrypt(data, using: key, iv: iv, cryptoOptions: cryptoOptions)
      let endTime = DispatchTime.now()
      let durationNano = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
      let durationMs = Double(durationNano) / 1_000_000

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
     - cryptoOptions: Optional decryption configuration
   - Returns: Decrypted data from the wrapped implementation
   - Throws: Rethrows any errors from the wrapped implementation
   */
  public func decrypt(
    _ data: Data,
    using key: Data,
    iv: Data,
    cryptoOptions: CryptoOptions?
  ) async throws -> Data {
    let startTime = DispatchTime.now()
    await logger.info("Decrypting \(data.count) bytes of data", metadata: nil, source: sourceID)

    do {
      let result = try await wrapped.decrypt(data, using: key, iv: iv, cryptoOptions: cryptoOptions)
      let endTime = DispatchTime.now()
      let durationNano = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
      let durationMs = Double(durationNano) / 1_000_000

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
     - password: Password to derive the key from
     - salt: Salt value for the derivation
     - iterations: Number of iterations for the derivation
     - derivationOptions: Optional key derivation configuration
   - Returns: Derived key data from the wrapped implementation
   - Throws: Rethrows any errors from the wrapped implementation
   */
  public func deriveKey(
    from password: String,
    salt: Data,
    iterations: Int,
    derivationOptions: KeyDerivationOptions?
  ) async throws -> Data {
    let startTime = DispatchTime.now()
    await logger.info(
      "Deriving key from password with \(iterations) iterations",
      metadata: nil,
      source: sourceID
    )

    do {
      let result = try await wrapped.deriveKey(
        from: password, 
        salt: salt, 
        iterations: iterations,
        derivationOptions: derivationOptions
      )
      let endTime = DispatchTime.now()
      let durationNano = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
      let durationMs = Double(durationNano) / 1_000_000

      await logger.info(
        "Successfully derived \(result.count) bytes key in \(String(format: "%.2f", durationMs))ms",
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
   Logs and forwards key generation operation to the wrapped implementation.

   - Parameter length: Length of the key to generate
   - Parameter keyOptions: Optional key generation configuration
   - Returns: Generated key data from the wrapped implementation
   - Throws: Rethrows any errors from the wrapped implementation
   */
  public func generateKey(length: Int, keyOptions: KeyGenerationOptions?) async throws -> Data {
    let startTime = DispatchTime.now()
    await logger.info(
      "Generating secure random key of \(length) bytes",
      metadata: nil,
      source: sourceID
    )

    do {
      let result = try await wrapped.generateKey(length: length, keyOptions: keyOptions)
      let endTime = DispatchTime.now()
      let durationNano = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
      let durationMs = Double(durationNano) / 1_000_000

      await logger.info(
        "Successfully generated \(result.count) bytes key in \(String(format: "%.2f", durationMs))ms",
        metadata: nil,
        source: sourceID
      )
      return result
    } catch {
      await logger.error(
        "Key generation failed: \(error.localizedDescription)",
        metadata: nil,
        source: sourceID
      )
      throw error
    }
  }

  /**
   Logs and forwards HMAC generation operation to the wrapped implementation.

   - Parameters:
     - data: Data to authenticate
     - key: The authentication key
     - hmacOptions: Optional HMAC configuration
   - Returns: HMAC data from the wrapped implementation
   - Throws: Rethrows any errors from the wrapped implementation
   */
  public func generateHMAC(
    for data: Data,
    using key: Data,
    hmacOptions: HMACOptions?
  ) async throws -> Data {
    let startTime = DispatchTime.now()
    await logger.info(
      "Generating HMAC for \(data.count) bytes of data",
      metadata: nil,
      source: sourceID
    )

    do {
      let result = try await wrapped.generateHMAC(for: data, using: key, hmacOptions: hmacOptions)
      let endTime = DispatchTime.now()
      let durationNano = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
      let durationMs = Double(durationNano) / 1_000_000

      await logger.info(
        "Successfully generated \(result.count) bytes HMAC in \(String(format: "%.2f", durationMs))ms",
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
