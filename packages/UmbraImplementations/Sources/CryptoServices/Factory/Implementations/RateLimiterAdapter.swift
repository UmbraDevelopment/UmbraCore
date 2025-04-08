import Foundation

/**
 Adapter for the new actor-based TokenBucketRateLimiter to be compatible with the
 EnhancedSecureCryptoServiceImpl's expected RateLimiter interface.

 This adapter bridges the gap between the old class-based RateLimiter interface
 and the new actor-based TokenBucketRateLimiter implementation.
 */
public actor RateLimiterAdapter: Sendable {
  /// The wrapped actor-based rate limiter
  public let actorRateLimiter: TokenBucketRateLimiter

  /// The domain for rate limiting operations
  private let domain: String

  /**
   Initialises a new rate limiter adapter.

   - Parameters:
     - rateLimiter: The actor-based rate limiter to wrap
     - domain: The domain for rate limiting operations
   */
  public init(rateLimiter: TokenBucketRateLimiter, domain: String) {
    actorRateLimiter=rateLimiter
    self.domain=domain
  }

  /**
   Check if an operation is currently rate limited.

   - Parameter operation: The operation to check
   - Returns: true if the operation is rate limited, false otherwise
   */
  public func isRateLimited(_ operation: String) async -> Bool {
    // Call the actor method directly now that we're in an async context
    return await !actorRateLimiter.tryConsume(count: 1)
  }
}
