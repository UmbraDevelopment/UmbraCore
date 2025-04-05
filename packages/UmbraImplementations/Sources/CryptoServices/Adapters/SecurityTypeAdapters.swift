import Foundation
import SecurityCoreInterfaces

/**
 This file contains adapter types that bridge between different module implementations
 to resolve type compatibility issues. These adapters allow for seamless integration
 between modules with different type definitions for similar concepts.
 */

/**
 Adapter for converting between different encryption option types across modules.
 */
public enum EncryptionOptionsAdapter {
  /**
   Converts SecurityCoreInterfaces.EncryptionOptions to the local module's EncryptionOptions

   - Parameter options: The options to convert
   - Returns: The converted options or nil if input was nil
   */
  public static func convert(
    _ options: SecurityCoreInterfaces
      .EncryptionOptions?
  ) -> EncryptionOptions? {
    guard let options else { return nil }

    return EncryptionOptions(
      algorithm: convert(options.algorithm),
      mode: convert(options.mode),
      padding: convert(options.padding),
      additionalAuthenticatedData: options.additionalAuthenticatedData
    )
  }

  /**
   Converts local module's EncryptionOptions to SecurityCoreInterfaces.EncryptionOptions

   - Parameter options: The options to convert
   - Returns: The converted options or nil if input was nil
   */
  public static func convertToInterface(_ options: EncryptionOptions?) -> SecurityCoreInterfaces
  .EncryptionOptions? {
    guard let options else { return nil }

    return SecurityCoreInterfaces.EncryptionOptions(
      algorithm: convertToInterface(options.algorithm),
      mode: convertToInterface(options.mode),
      padding: convertToInterface(options.padding),
      additionalAuthenticatedData: options.additionalAuthenticatedData
    )
  }

  // Helper methods for algorithm conversion
  private static func convert(
    _ algorithm: SecurityCoreInterfaces
      .EncryptionAlgorithm
  ) -> EncryptionAlgorithm {
    switch algorithm {
      case .aes:
        return .aes
      case .chacha20:
        return .chacha20
      @unknown default:
        // Default to a safe algorithm if an unknown one is provided
        return .aes
    }
  }

  private static func convertToInterface(_ algorithm: EncryptionAlgorithm) -> SecurityCoreInterfaces
  .EncryptionAlgorithm {
    switch algorithm {
      case .aes:
        return .aes
      case .chacha20:
        return .chacha20
      @unknown default:
        return .aes
    }
  }

  // Helper methods for mode conversion
  private static func convert(_ mode: SecurityCoreInterfaces.EncryptionMode) -> EncryptionMode {
    switch mode {
      case .cbc:
        return .cbc
      case .gcm:
        return .gcm
      @unknown default:
        // Default to a secure mode if an unknown one is provided
        return .gcm
    }
  }

  private static func convertToInterface(_ mode: EncryptionMode) -> SecurityCoreInterfaces
  .EncryptionMode {
    switch mode {
      case .cbc:
        return .cbc
      case .gcm:
        return .gcm
      @unknown default:
        return .gcm
    }
  }

  // Helper methods for padding conversion
  private static func convert(
    _ padding: SecurityCoreInterfaces
      .EncryptionPadding
  ) -> EncryptionPadding {
    switch padding {
      case .none:
        return .none
      case .pkcs7:
        return .pkcs7
      @unknown default:
        // Default to a standard padding if an unknown one is provided
        return .pkcs7
    }
  }

  private static func convertToInterface(_ padding: EncryptionPadding) -> SecurityCoreInterfaces
  .EncryptionPadding {
    switch padding {
      case .none:
        return .none
      case .pkcs7:
        return .pkcs7
      @unknown default:
        return .pkcs7
    }
  }
}

/**
 Adapter for converting between different decryption option types across modules.
 */
public enum DecryptionOptionsAdapter {
  /**
   Converts SecurityCoreInterfaces.DecryptionOptions to the local module's DecryptionOptions

   - Parameter options: The options to convert
   - Returns: The converted options or nil if input was nil
   */
  public static func convert(
    _ options: SecurityCoreInterfaces
      .DecryptionOptions?
  ) -> DecryptionOptions? {
    guard let options else { return nil }

    return DecryptionOptions(
      algorithm: EncryptionOptionsAdapter.convert(options.algorithm),
      mode: EncryptionOptionsAdapter.convert(options.mode),
      padding: EncryptionOptionsAdapter.convert(options.padding),
      additionalAuthenticatedData: options.additionalAuthenticatedData
    )
  }

  /**
   Converts local module's DecryptionOptions to SecurityCoreInterfaces.DecryptionOptions

   - Parameter options: The options to convert
   - Returns: The converted options or nil if input was nil
   */
  public static func convertToInterface(_ options: DecryptionOptions?) -> SecurityCoreInterfaces
  .DecryptionOptions? {
    guard let options else { return nil }

    return SecurityCoreInterfaces.DecryptionOptions(
      algorithm: EncryptionOptionsAdapter.convertToInterface(options.algorithm),
      mode: EncryptionOptionsAdapter.convertToInterface(options.mode),
      padding: EncryptionOptionsAdapter.convertToInterface(options.padding),
      additionalAuthenticatedData: options.additionalAuthenticatedData
    )
  }
}

/**
 Adapter for converting between different hashing option types across modules.
 */
public enum HashingOptionsAdapter {
  /**
   Converts SecurityCoreInterfaces.HashingOptions to the local module's HashingOptions

   - Parameter options: The options to convert
   - Returns: The converted options or nil if input was nil
   */
  public static func convert(_ options: SecurityCoreInterfaces.HashingOptions?) -> HashingOptions? {
    guard let options else { return nil }

    return HashingOptions(
      algorithm: convert(options.algorithm),
      salt: options.salt
    )
  }

  /**
   Converts local module's HashingOptions to SecurityCoreInterfaces.HashingOptions

   - Parameter options: The options to convert
   - Returns: The converted options or nil if input was nil
   */
  public static func convertToInterface(_ options: HashingOptions?) -> SecurityCoreInterfaces
  .HashingOptions? {
    guard let options else { return nil }

    return SecurityCoreInterfaces.HashingOptions(
      algorithm: convertToInterface(options.algorithm),
      salt: options.salt
    )
  }

  // Helper methods for algorithm conversion
  private static func convert(
    _ algorithm: SecurityCoreInterfaces
      .HashingAlgorithm
  ) -> HashingAlgorithm {
    switch algorithm {
      case .sha256:
        return .sha256
      case .sha512:
        return .sha512
      case .blake2b:
        return .blake2b
      @unknown default:
        // Default to a secure algorithm if an unknown one is provided
        return .sha256
    }
  }

  private static func convertToInterface(_ algorithm: HashingAlgorithm) -> SecurityCoreInterfaces
  .HashingAlgorithm {
    switch algorithm {
      case .sha256:
        return .sha256
      case .sha512:
        return .sha512
      case .blake2b:
        return .blake2b
      @unknown default:
        return .sha256
    }
  }
}

/**
 Adapter for converting between different key generation option types across modules.
 */
public enum KeyGenerationOptionsAdapter {
  /**
   Converts SecurityCoreInterfaces.KeyGenerationOptions to the local module's KeyGenerationOptions

   - Parameter options: The options to convert
   - Returns: The converted options or nil if input was nil
   */
  public static func convert(
    _ options: SecurityCoreInterfaces
      .KeyGenerationOptions?
  ) -> KeyGenerationOptions? {
    guard let options else { return nil }

    return KeyGenerationOptions(
      keyType: convert(options.keyType),
      useSecureEnclave: options.useSecureEnclave,
      customIdentifier: options.customIdentifier
    )
  }

  /**
   Converts local module's KeyGenerationOptions to SecurityCoreInterfaces.KeyGenerationOptions

   - Parameter options: The options to convert
   - Returns: The converted options or nil if input was nil
   */
  public static func convertToInterface(_ options: KeyGenerationOptions?) -> SecurityCoreInterfaces
  .KeyGenerationOptions? {
    guard let options else { return nil }

    return SecurityCoreInterfaces.KeyGenerationOptions(
      keyType: convertToInterface(options.keyType),
      useSecureEnclave: options.useSecureEnclave,
      customIdentifier: options.customIdentifier
    )
  }

  // Helper methods for key type conversion
  private static func convert(_ keyType: SecurityCoreInterfaces.KeyType) -> KeyType {
    switch keyType {
      case .symmetric:
        return .symmetric
      case .asymmetric:
        return .asymmetric
      @unknown default:
        // Default to symmetric if unknown
        return .symmetric
    }
  }

  private static func convertToInterface(_ keyType: KeyType) -> SecurityCoreInterfaces.KeyType {
    switch keyType {
      case .symmetric:
        return .symmetric
      case .asymmetric:
        return .asymmetric
      @unknown default:
        return .symmetric
    }
  }
}
