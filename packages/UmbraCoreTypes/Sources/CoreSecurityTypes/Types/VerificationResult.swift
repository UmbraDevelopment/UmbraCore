import Foundation

/**
 # SecurityVerificationResultDTO

 Represents the result of a digital signature verification operation in the Alpha Dot Five architecture.
 Provides strong typing and additional context for verification operations.

 ## Usage
 ```swift
 let result = SecurityVerificationResultDTO(
     isValid: true,
     algorithm: .ed25519
 )
 ```
 */
public struct SecurityVerificationResultDTO: Sendable, Equatable {
  /// Indicates whether the signature is valid
  public let isValid: Bool

  /// The algorithm used for verification
  public let algorithm: SigningAlgorithm

  /// Additional metadata about the verification process (using Sendable-compatible types)
  public let metadata: [String: String]

  /// Creates a new verification result
  public init(isValid: Bool, algorithm: SigningAlgorithm, metadata: [String: String]=[:]) {
    self.isValid=isValid
    self.algorithm=algorithm
    self.metadata=metadata
  }

  /// Check equality by comparing isValid and algorithm (metadata isn't Equatable)
  public static func == (
    lhs: SecurityVerificationResultDTO,
    rhs: SecurityVerificationResultDTO
  ) -> Bool {
    lhs.isValid == rhs.isValid &&
      lhs.algorithm == rhs.algorithm
  }
}
