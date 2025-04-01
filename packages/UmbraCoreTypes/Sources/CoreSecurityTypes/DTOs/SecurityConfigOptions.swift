import Foundation

/**
 Configuration options for security operations.

 This structure provides additional configuration parameters for security
 operations beyond the core algorithm and provider settings. It follows the
 architecture's pattern for type-safe configuration.
 */
public struct SecurityConfigOptions: Sendable, Equatable, Codable {
  /// Whether to enable additional operation logging
  public let enableDetailedLogging: Bool

  /// Key derivation iterations (higher is more secure but slower)
  public let keyDerivationIterations: Int

  /// Memory limit for key derivation in bytes
  public let memoryLimitBytes: Int

  /// Whether to use hardware acceleration if available
  public let useHardwareAcceleration: Bool

  /// Operation timeout in seconds
  public let operationTimeoutSeconds: TimeInterval

  /// Whether to verify outputs of security operations
  public let verifyOperations: Bool

  /// Custom metadata for additional configuration options
  public var metadata: [String: String]?

  /**
   Initialises security configuration options.

   - Parameters:
     - enableDetailedLogging: Whether to enable detailed operation logging
     - keyDerivationIterations: Number of iterations for key derivation
     - memoryLimitBytes: Memory limit for key derivation
     - useHardwareAcceleration: Whether to use hardware acceleration
     - operationTimeoutSeconds: Timeout for operations in seconds
     - verifyOperations: Whether to verify operation outputs
     - metadata: Custom metadata for additional configuration options
   */
  public init(
    enableDetailedLogging: Bool=false,
    keyDerivationIterations: Int=100_000,
    memoryLimitBytes: Int=65536,
    useHardwareAcceleration: Bool=true,
    operationTimeoutSeconds: TimeInterval=30.0,
    verifyOperations: Bool=true,
    metadata: [String: String]?=nil
  ) {
    self.enableDetailedLogging=enableDetailedLogging
    self.keyDerivationIterations=keyDerivationIterations
    self.memoryLimitBytes=memoryLimitBytes
    self.useHardwareAcceleration=useHardwareAcceleration
    self.operationTimeoutSeconds=operationTimeoutSeconds
    self.verifyOperations=verifyOperations
    self.metadata=metadata
  }

  /// Default security configuration options
  public static let `default`=SecurityConfigOptions()

  /// High-security configuration options
  public static let highSecurity=SecurityConfigOptions(
    enableDetailedLogging: true,
    keyDerivationIterations: 500_000,
    memoryLimitBytes: 131_072,
    useHardwareAcceleration: true,
    operationTimeoutSeconds: 60.0,
    verifyOperations: true
  )

  /// Performance-optimised configuration options
  public static let performanceOptimised=SecurityConfigOptions(
    enableDetailedLogging: false,
    keyDerivationIterations: 50000,
    memoryLimitBytes: 32768,
    useHardwareAcceleration: true,
    operationTimeoutSeconds: 15.0,
    verifyOperations: false
  )
}
