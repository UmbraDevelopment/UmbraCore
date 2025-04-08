import Foundation
import APIServices

/**
 Adapter for the new actor-based RateLimiter to be compatible with the
 EnhancedSecureCryptoServiceImpl's expected RateLimiter interface.
 
 This adapter bridges the gap between the old class-based RateLimiter interface
 and the new actor-based RateLimiter implementation from the APIServices module.
 */
public class RateLimiterAdapter: RateLimiter {
    /// The wrapped actor-based rate limiter
    private let actorRateLimiter: APIServices.RateLimiter
    
    /// The domain for rate limiting operations
    private let domain: String
    
    /**
     Initialises a new rate limiter adapter.
     
     - Parameters:
       - rateLimiter: The actor-based rate limiter to wrap
       - domain: The domain for rate limiting operations
     */
    public init(rateLimiter: APIServices.RateLimiter, domain: String) {
        self.actorRateLimiter = rateLimiter
        self.domain = domain
        super.init()
    }
    
    /**
     Check if an operation is currently rate limited.
     
     - Parameter operation: The operation to check
     - Returns: true if the operation is rate limited, false otherwise
     */
    override open func isRateLimited(_ operation: Operation) -> Bool {
        // Create a task to call the actor method and wait for the result
        let task = Task {
            return await !actorRateLimiter.tryConsume(count: 1)
        }
        
        // Get the result, defaulting to rate limited (true) if there's an error
        return (try? task.result.get()) ?? true
    }
}
