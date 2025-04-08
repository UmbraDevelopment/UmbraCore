import Foundation

/**
 # Rate Limiter
 
 Provides rate limiting capabilities for API operations to prevent abuse and ensure
 fair resource usage. This implementation supports token bucket algorithm for
 flexible rate limiting with burst capabilities.
 
 ## Thread Safety
 
 This implementation uses Swift's actor model to ensure thread safety when
 accessing rate limiting state from multiple concurrent contexts.
 */
public actor RateLimiter {
  /// The maximum number of tokens the bucket can hold
  private let capacity: Int
  
  /// The rate at which tokens are added to the bucket (tokens per second)
  private let refillRate: Double
  
  /// The current number of tokens in the bucket
  private var tokens: Double
  
  /// The last time the bucket was refilled
  private var lastRefillTimestamp: Date
  
  /**
   Initialises a new rate limiter with the token bucket algorithm.
   
   - Parameters:
     - capacity: The maximum number of tokens the bucket can hold
     - refillRate: The rate at which tokens are added to the bucket (tokens per second)
   */
  public init(capacity: Int, refillRate: Double) {
    self.capacity = capacity
    self.refillRate = refillRate
    self.tokens = Double(capacity)
    self.lastRefillTimestamp = Date()
  }
  
  /**
   Attempts to consume tokens from the bucket.
   
   - Parameter count: The number of tokens to consume
   - Returns: true if tokens were consumed, false if not enough tokens are available
   */
  public func tryConsume(count: Int = 1) -> Bool {
    refillTokens()
    
    if tokens >= Double(count) {
      tokens -= Double(count)
      return true
    } else {
      return false
    }
  }
  
  /**
   Consumes tokens from the bucket, waiting if necessary.
   
   - Parameters:
     - count: The number of tokens to consume
     - timeout: The maximum time to wait for tokens to become available
   - Returns: true if tokens were consumed, false if timed out
   */
  public func consume(count: Int = 1, timeout: TimeInterval? = nil) async -> Bool {
    // Try to consume immediately
    if tryConsume(count: count) {
      return true
    }
    
    // If there's no timeout, we can't wait
    guard let timeout = timeout else {
      return false
    }
    
    // Calculate how long we need to wait for enough tokens
    let tokensNeeded = Double(count) - tokens
    let waitTime = tokensNeeded / refillRate
    
    // If the wait time exceeds the timeout, return false
    if waitTime > timeout {
      return false
    }
    
    // Wait for the required time
    try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
    
    // Try again after waiting
    return tryConsume(count: count)
  }
  
  /**
   Refills the token bucket based on elapsed time.
   */
  private func refillTokens() {
    let now = Date()
    let timeElapsed = now.timeIntervalSince(lastRefillTimestamp)
    
    if timeElapsed > 0 {
      let newTokens = timeElapsed * refillRate
      tokens = min(Double(capacity), tokens + newTokens)
      lastRefillTimestamp = now
    }
  }
  
  /**
   Resets the token bucket to its initial state.
   */
  public func reset() {
    tokens = Double(capacity)
    lastRefillTimestamp = Date()
  }
}

/**
 # Rate Limiter Factory
 
 Creates and manages rate limiters for different operations and domains.
 This factory provides a centralised way to create properly configured
 rate limiters with appropriate limits.
 */
public actor RateLimiterFactory {
  /// Shared instance for singleton access
  public static let shared = RateLimiterFactory()
  
  /// Cache of created rate limiters
  private var limiters: [String: RateLimiter] = [:]
  
  /**
   Initialises a new rate limiter factory.
   */
  public init() {}
  
  /**
   Gets or creates a rate limiter for a specific operation.
   
   - Parameters:
     - domain: The domain of the operation
     - operation: The operation name
     - capacity: The maximum capacity of the rate limiter
     - refillRate: The refill rate of the rate limiter
   - Returns: A rate limiter for the specified operation
   */
  public func getRateLimiter(
    domain: String,
    operation: String,
    capacity: Int = 10,
    refillRate: Double = 1.0
  ) async -> RateLimiter {
    let key = "\(domain).\(operation)"
    
    if let limiter = limiters[key] {
      return limiter
    }
    
    let limiter = RateLimiter(capacity: capacity, refillRate: refillRate)
    limiters[key] = limiter
    return limiter
  }
  
  /**
   Gets or creates a rate limiter for a high-security operation.
   
   - Parameters:
     - domain: The domain of the operation
     - operation: The operation name
   - Returns: A rate limiter configured for high-security operations
   */
  public func getHighSecurityRateLimiter(
    domain: String,
    operation: String
  ) async -> RateLimiter {
    // High-security operations have stricter rate limits
    return await getRateLimiter(
      domain: domain,
      operation: operation,
      capacity: 5,
      refillRate: 0.2  // 1 token every 5 seconds
    )
  }
  
  /**
   Resets all rate limiters.
   */
  public func resetAll() async {
    for (_, limiter) in limiters {
      await limiter.reset()
    }
  }
  
  /**
   Resets a specific rate limiter.
   
   - Parameters:
     - domain: The domain of the operation
     - operation: The operation name
   */
  public func reset(domain: String, operation: String) async {
    let key = "\(domain).\(operation)"
    
    if let limiter = limiters[key] {
      await limiter.reset()
    }
  }
}
