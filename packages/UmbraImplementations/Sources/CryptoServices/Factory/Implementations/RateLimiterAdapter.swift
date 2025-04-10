import CryptoInterfaces
import Foundation

/**
 Adapter for the actor-based TokenBucketRateLimiter to be compatible with the
 EnhancedSecureCryptoServiceImpl's expected BaseRateLimiter interface.

 This adapter bridges the gap between the actor-based RateLimiterProtocol interface
 and the protocol-based BaseRateLimiter required by other components.
 */
public final class RateLimiterAdapter: BaseRateLimiter {
  /// The wrapped actor-based rate limiter
  private let actorRateLimiter: RateLimiterProtocol

  /// The domain for rate limiting operations
  private let domain: String

  /// Maximum number of operations per minute (for configuration)
  private let maxOperationsPerMinute: Int

  /// Cooldown period after reaching limits (in seconds)
  private let cooldownPeriod: TimeInterval

  /**
   Initialises a new rate limiter adapter.

   - Parameters:
     - rateLimiter: The actor-based rate limiter to wrap
     - domain: The domain for rate limiting operations
     - maxOperationsPerMinute: Maximum operations allowed per minute
     - cooldownPeriod: Cooldown period in seconds after reaching limits
   */
  public init(
    rateLimiter: RateLimiterProtocol,
    domain: String,
    maxOperationsPerMinute: Int=30,
    cooldownPeriod: TimeInterval=30
  ) {
    actorRateLimiter=rateLimiter
    self.domain=domain
    self.maxOperationsPerMinute=maxOperationsPerMinute
    self.cooldownPeriod=cooldownPeriod
  }

  /**
   Check if an operation is currently rate limited.

   - Parameter operation: The operation to check
   - Returns: true if the operation is rate limited, false otherwise
   */
  public func isRateLimited(_: String) async -> Bool {
    // Call the underlying rate limiter
    await !actorRateLimiter.tryConsume(count: 1)
  }

  /**
   Records an operation for rate limiting purposes.
   This is a no-op in this implementation because the TokenBucketRateLimiter
   already accounts for operations in the tryConsume method.

   - Parameter operation: The operation to record
   */
  public func recordOperation(_: String) async {
    // No-op: TokenBucketRateLimiter already accounts for operations in tryConsume
  }

  /**
   Resets the rate limiter for an operation.

   - Parameter operation: The operation to reset
   */
  public func reset(_: String) async {
    // This is a no-op because the TokenBucketRateLimiter doesn't support resetting
    // for individual operations. In a more complete implementation, we might
    // track operations separately.
  }

  /**
   Provides a description of this adapter for debugging purposes.

   - Returns: A standardised description string
   */
  public var description: String {
    "RateLimiterAdapter(domain: \(domain), maxOperationsPerMinute: \(maxOperationsPerMinute))"
  }
}
