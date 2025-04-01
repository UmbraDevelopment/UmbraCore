import Foundation

/**
 # EncryptionResult

 Represents the result of an encryption operation in the Alpha Dot Five architecture.
 Provides strong typing for encryption outputs with additional metadata.

 ## Usage
 ```swift
 let result = EncryptionResult(
     ciphertext: encryptedData,
     algorithm: .aesGCM,
     metadata: ["iv": ivData]
 )
 ```
 */
public struct EncryptionResult: Sendable, Equatable {
  /// The encrypted data (ciphertext)
  public let ciphertext: Data

  /// The algorithm used for encryption
  public let algorithm: EncryptionAlgorithm

  /// Additional metadata required for decryption (e.g., IV, salt)
  public let metadata: [String: Data]

  /// Creates a new encryption result
  public init(ciphertext: Data, algorithm: EncryptionAlgorithm, metadata: [String: Data]=[:]) {
    self.ciphertext=ciphertext
    self.algorithm=algorithm
    self.metadata=metadata
  }
}
