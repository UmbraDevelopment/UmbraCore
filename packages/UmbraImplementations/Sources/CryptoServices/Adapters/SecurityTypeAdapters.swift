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
      algorithm: options.algorithm,
      mode: options.mode,
      padding: options.padding,
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
      algorithm: options.algorithm,
      mode: options.mode,
      padding: options.padding,
      additionalAuthenticatedData: options.additionalAuthenticatedData
    )
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
      algorithm: options.algorithm,
      mode: options.mode,
      padding: options.padding,
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
      algorithm: options.algorithm,
      mode: options.mode,
      padding: options.padding,
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

    return LocalHashingOptions(algorithm: options.algorithm, useSalt: options.salt != nil)
  }

  /**
   Converts local module's HashingOptions to CoreSecurityTypes.HashingOptions

   - Parameter options: The options to convert
   - Returns: The converted options or nil if input was nil
   */
  public static func convertToInterface(_ options: LocalHashingOptions?) -> CoreSecurityTypes
  .HashingOptions? {
    guard let options else { return nil }

    return CoreSecurityTypes.HashingOptions(algorithm: options.algorithm, salt: options.useSalt ? [0x01, 0x02, 0x03, 0x04] : nil)
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
      keyType: options.keyType,
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
      keyType: options.keyType,
      useSecureEnclave: options.useSecureEnclave,
      isExtractable: options.isExtractable,
      options: options.options
    )
  }
}
