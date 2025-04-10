import Foundation
import CryptoInterfaces

/**
 A basic implementation of a rate limiter for security operations.
 
 This class provides a simplified rate limiting mechanism for cryptographic operations,
 supporting configuration of maximum operations per minute and cooldown periods.
 It serves as a factory for creating RateLimiterAdapter instances with appropriate
 TokenBucketRateLimiter configurations.
 */
public final class BasicRateLimiter {
    /// The maximum number of operations allowed per minute
    private let maxOperationsPerMinute: Int
    
    /// The cooldown period in seconds after reaching the rate limit
    private let cooldownPeriod: TimeInterval
    
    /// The domain for rate limiting operations
    private let domain: String
    
    /**
     Initialises a new basic rate limiter with default settings.
     
     - Parameters:
       - maxOperationsPerMinute: The maximum number of operations allowed per minute (default: 30)
       - cooldownPeriod: The cooldown period in seconds after reaching the rate limit (default: 30)
       - domain: The domain for rate limiting operations (default: "CryptoOperations")
     */
    public init(
        maxOperationsPerMinute: Int = 30,
        cooldownPeriod: TimeInterval = 30,
        domain: String = "CryptoOperations"
    ) {
        self.maxOperationsPerMinute = maxOperationsPerMinute
        self.cooldownPeriod = cooldownPeriod
        self.domain = domain
    }
    
    /**
     Creates a RateLimiterAdapter configured with a TokenBucketRateLimiter based on this limiter's settings.
     
     - Returns: A configured RateLimiterAdapter instance
     */
    public func createAdapter() -> RateLimiterAdapter {
        // Convert operations per minute to tokens per second
        let tokensPerSecond = Double(maxOperationsPerMinute) / 60.0
        
        // Create configuration
        let config = TokenBucketRateLimiter.Configuration(
            tokensPerSecond: tokensPerSecond,
            burstSize: maxOperationsPerMinute,
            initialTokens: maxOperationsPerMinute / 2
        )
        
        // Create the token bucket limiter
        let tokenBucketLimiter = TokenBucketRateLimiter(configuration: config)
        
        // Create and return the adapter
        return RateLimiterAdapter(
            rateLimiter: tokenBucketLimiter,
            domain: domain,
            maxOperationsPerMinute: maxOperationsPerMinute,
            cooldownPeriod: cooldownPeriod
        )
    }
}
