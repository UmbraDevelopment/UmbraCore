import Foundation

/**
 * Protocol defining a rate limiter for controlling access to sensitive operations.
 *
 * This interface allows for rate limiting operations based on configurable
 * parameters such as tokens per second and burst size.
 */
public protocol RateLimiterProtocol: Sendable {
  /**
   * Attempts to consume tokens from the rate limiter.
   *
   * - Parameter count: Number of tokens to consume
   * - Returns: True if tokens were consumed successfully, false if rate limited
   */
  func tryConsume(count: Int) async -> Bool

  /**
   * Waits until tokens can be consumed or timeout is reached.
   *
   * - Parameters:
   *   - count: Number of tokens to consume
   *   - timeout: Maximum time to wait in seconds
   * - Returns: True if tokens were consumed successfully, false if timed out
   */
  func waitForConsume(count: Int, timeout: TimeInterval) async -> Bool
}

/**
 * Actor implementation of a rate limiter using the token bucket algorithm.
 *
 * This implementation provides thread-safe rate limiting capabilities
 * with configurable rates and burst sizes.
 */
public actor TokenBucketRateLimiter: RateLimiterProtocol {
  /// Configuration for the rate limiter
  public struct Configuration: Sendable, Equatable {
    /// Tokens added per second
    public let tokensPerSecond: Double

    /// Maximum number of tokens that can be stored
    public let burstSize: Int

    /// Initial number of tokens available
    public let initialTokens: Int

    /**
     * Creates a new rate limiter configuration.
     *
     * - Parameters:
     *   - tokensPerSecond: Rate at which tokens are added
     *   - burstSize: Maximum number of tokens that can be stored
     *   - initialTokens: Initial number of tokens available
     */
    public init(
      tokensPerSecond: Double,
      burstSize: Int,
      initialTokens: Int?=nil
    ) {
      self.tokensPerSecond=tokensPerSecond
      self.burstSize=burstSize
      self.initialTokens=initialTokens ?? burstSize
    }

    /// Standard configuration for normal operations
    public static let standard=Configuration(
      tokensPerSecond: 10.0,
      burstSize: 20
    )

    /// Configuration for high-security operations
    public static let highSecurity=Configuration(
      tokensPerSecond: 3.0,
      burstSize: 5,
      initialTokens: 3
    )

    /// Configuration for very limited operations
    public static let restricted=Configuration(
      tokensPerSecond: 1.0,
      burstSize: 3,
      initialTokens: 1
    )
  }

  /// Current number of tokens available
  private var availableTokens: Double

  /// Configuration for this rate limiter
  private let configuration: Configuration

  /// Last time tokens were added
  private var lastRefillTime: Date

  /**
   * Creates a new rate limiter with the specified configuration.
   *
   * - Parameter configuration: Configuration for the rate limiter
   */
  public init(configuration: Configuration = .standard) {
    self.configuration=configuration
    availableTokens=Double(configuration.initialTokens)
    lastRefillTime=Date()
  }

  /**
   * Refills tokens based on elapsed time since last refill.
   */
  private func refill() {
    let now=Date()
    let timeElapsed=now.timeIntervalSince(lastRefillTime)

    if timeElapsed > 0 {
      let tokensToAdd=timeElapsed * configuration.tokensPerSecond
      availableTokens=min(
        Double(configuration.burstSize),
        availableTokens + tokensToAdd
      )
      lastRefillTime=now
    }
  }

  /**
   * Attempts to consume tokens from the rate limiter.
   *
   * - Parameter count: Number of tokens to consume
   * - Returns: True if tokens were consumed successfully, false if rate limited
   */
  public func tryConsume(count: Int) async -> Bool {
    refill()

    if availableTokens >= Double(count) {
      availableTokens -= Double(count)
      return true
    }

    return false
  }

  /**
   * Waits until tokens can be consumed or timeout is reached.
   *
   * - Parameters:
   *   - count: Number of tokens to consume
   *   - timeout: Maximum time to wait in seconds
   * - Returns: True if tokens were consumed successfully, false if timed out
   */
  public func waitForConsume(count: Int, timeout: TimeInterval) async -> Bool {
    // First try to consume immediately
    if await tryConsume(count: count) {
      return true
    }

    // Calculate how long we need to wait for enough tokens
    refill()
    let tokensNeeded=Double(count) - availableTokens
    let waitTime=tokensNeeded / configuration.tokensPerSecond

    // If wait time exceeds timeout, return false
    if waitTime > timeout {
      return false
    }

    // Wait for the calculated time
    try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))

    // Try again after waiting
    return await tryConsume(count: count)
  }
}
