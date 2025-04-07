import CoreSecurityTypes
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
   Converts CoreSecurityTypes.EncryptionOptions to the local module's EncryptionOptions

   - Parameter options: The options to convert
   - Returns: The converted options or nil if input was nil
   */
  public static func convert(
    _ options: CoreSecurityTypes
      .EncryptionOptions?
  ) -> LocalEncryptionOptions? {
    guard let options else { return nil }

    return LocalEncryptionOptions(
      algorithm: convert(options.algorithm),
      mode: convert(options.mode),
      padding: convert(options.padding),
      additionalAuthenticatedData: options.additionalAuthenticatedData
    )
  }

  /**
   Converts local module's EncryptionOptions to CoreSecurityTypes.EncryptionOptions

   - Parameter options: The options to convert
   - Returns: The converted options or nil if input was nil
   */
  public static func convertToInterface(_ options: LocalEncryptionOptions?)
    -> CoreSecurityTypes
    .EncryptionOptions?
  {
    guard let options else { return nil }

    return CoreSecurityTypes.EncryptionOptions(
      algorithm: convertToInterface(options.algorithm),
      mode: convertToInterface(options.mode),
      padding: convertToInterface(options.padding),
      additionalAuthenticatedData: options.additionalAuthenticatedData
    )
  }

  // Helper methods for algorithm conversion
  private static func convert(
    _ algorithm: CoreSecurityTypes
      .EncryptionAlgorithm
  ) -> EncryptionAlgorithm {
    switch algorithm {
      case .aes256CBC:
        return .aesCBC
      case .aes256GCM:
        return .aesGCM
      case .chacha20Poly1305:
        return .chacha20Poly1305
      @unknown default:
        // Default to a safe algorithm if an unknown one is provided
        return .aesGCM
    }
  }

  private static func convertToInterface(
    _ algorithm: EncryptionAlgorithm
  ) -> CoreSecurityTypes
  .EncryptionAlgorithm {
    switch algorithm {
      case .aesCBC:
        return .aes256CBC
      case .aesGCM:
        return .aes256GCM
      case .chacha20Poly1305:
        return .chacha20Poly1305
      @unknown default:
        return .aes256GCM
    }
  }

  // Helper methods for mode conversion
  private static func convert(_ mode: CoreSecurityTypes.EncryptionMode) -> EncryptionMode {
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

  private static func convertToInterface(_ mode: EncryptionMode) -> CoreSecurityTypes
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
    _ padding: CoreSecurityTypes
      .EncryptionPadding
  ) -> PaddingMode {
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

  private static func convertToInterface(_ padding: PaddingMode) -> CoreSecurityTypes
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
   Converts CoreSecurityTypes.DecryptionOptions to the local module's DecryptionOptions

   - Parameter options: The options to convert
   - Returns: The converted options or nil if input was nil
   */
  public static func convert(
    _ options: CoreSecurityTypes
      .DecryptionOptions?
  ) -> LocalDecryptionOptions? {
    guard let options else { return nil }

    return LocalDecryptionOptions(
      algorithm: EncryptionOptionsAdapter.convert(options.algorithm),
      mode: EncryptionOptionsAdapter.convert(options.mode),
      padding: EncryptionOptionsAdapter.convert(options.padding),
      additionalAuthenticatedData: options.additionalAuthenticatedData
    )
  }

  /**
   Converts local module's DecryptionOptions to CoreSecurityTypes.DecryptionOptions

   - Parameter options: The options to convert
   - Returns: The converted options or nil if input was nil
   */
  public static func convertToInterface(_ options: LocalDecryptionOptions?)
    -> CoreSecurityTypes
    .DecryptionOptions?
  {
    guard let options else { return nil }

    return CoreSecurityTypes.DecryptionOptions(
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
   Converts CoreSecurityTypes.HashingOptions to the local module's HashingOptions

   - Parameter options: The options to convert
   - Returns: The converted options or nil if input was nil
   */
  public static func convert(
    _ options: CoreSecurityTypes
      .HashingOptions?
  ) -> LocalHashingOptions? {
    guard let options else { return nil }

    return LocalHashingOptions(
      algorithm: convert(options.algorithm),
      useSalt: options.salt != nil
    )
  }

  /**
   Converts local module's HashingOptions to CoreSecurityTypes.HashingOptions

   - Parameter options: The options to convert
   - Returns: The converted options or nil if input was nil
   */
  public static func convertToInterface(_ options: LocalHashingOptions?) -> CoreSecurityTypes
  .HashingOptions? {
    guard let options else { return nil }

    return CoreSecurityTypes.HashingOptions(
      algorithm: convertToInterface(options.algorithm),
      salt: options.useSalt ? [0x01, 0x02, 0x03, 0x04] : nil // Default salt if needed
    )
  }

  // Helper methods for algorithm conversion
  private static func convert(
    _ algorithm: CoreSecurityTypes.HashAlgorithm
  ) -> HashingAlgorithm {
    switch algorithm {
      case .sha1:
        return .sha1
      case .sha224:
        return .sha224
      case .sha256:
        return .sha256
      case .sha384:
        return .sha384
      case .sha512:
        return .sha512
      @unknown default:
        return .sha256
    }
  }

  private static func convertToInterface(
    _ algorithm: HashingAlgorithm
  ) -> CoreSecurityTypes.HashAlgorithm {
    switch algorithm {
      case .sha1:
        return .sha1
      case .sha224:
        return .sha224
      case .sha256:
        return .sha256
      case .sha384:
        return .sha384
      case .sha512:
        return .sha512
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
   Converts CoreSecurityTypes.KeyGenerationOptions to the local module's KeyGenerationOptions

   - Parameter options: The options to convert
   - Returns: The converted options or nil if input was nil
   */
  public static func convert(
    _ options: CoreSecurityTypes.KeyGenerationOptions?
  ) -> KeyGenerationOptions? {
    guard let options else { return nil }

    return KeyGenerationOptions(
      keyType: convert(options.keyType),
      useSecureEnclave: options.useSecureEnclave,
      isExtractable: options.isExtractable,
      options: options.options
    )
  }

  /**
   Converts local module's KeyGenerationOptions to CoreSecurityTypes.KeyGenerationOptions

   - Parameter options: The options to convert
   - Returns: The converted options or nil if input was nil
   */
  public static func convertToInterface(
    _ options: KeyGenerationOptions?
  ) -> CoreSecurityTypes.KeyGenerationOptions? {
    guard let options else { return nil }

    return CoreSecurityTypes.KeyGenerationOptions(
      keyType: convertToInterface(options.keyType),
      useSecureEnclave: options.useSecureEnclave,
      isExtractable: options.isExtractable,
      options: options.options?.dictionary
    )
  }

  // Helper methods for key type conversion
  private static func convert(
    _ keyType: CoreSecurityTypes.KeyType
  ) -> KeyType {
    switch keyType {
      case .aes:
        return .aes
      case .rsa:
        return .rsa
      case .ec:
        return .ec
      @unknown default:
        // Default to AES if an unknown type is provided
        return .aes
    }
  }

  private static func convertToInterface(
    _ keyType: KeyType
  ) -> CoreSecurityTypes.KeyType {
    switch keyType {
      case .aes:
        return .aes
      case .rsa:
        return .rsa
      case .ec:
        return .ec
      @unknown default:
        return .aes
    }
  }
}
