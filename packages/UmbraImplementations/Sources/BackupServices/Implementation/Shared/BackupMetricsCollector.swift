import Foundation

/**
 * Collects and manages metrics for backup operations.
 *
 * This actor provides thread-safe access to metrics collection and reporting,
 * following the Alpha Dot Five architecture's principles for telemetry.
 */
public actor BackupMetricsCollector {
    /// Operation counts by type
    private var operationCounts: [String: Int] = [:]
    
    /// Successful operation counts by type
    private var successCounts: [String: Int] = [:]
    
    /// Error counts by type
    private var errorCounts: [String: Int] = [:]
    
    /// Operation durations by type
    private var operationDurations: [String: [TimeInterval]] = [:]
    
    /// The start time for the current session
    private let sessionStartTime = Date()
    
    /// The last reset time for metrics
    private var lastResetTime = Date()
    
    /// Initialises a new metrics collector
    public init() {}
    
    /**
     * Records the start of an operation.
     *
     * - Parameter operation: The type of operation being performed
     */
    public func recordOperationStarted(operation: String) {
        operationCounts[operation, default: 0] += 1
    }
    
    /**
     * Records the completion of an operation.
     *
     * - Parameters:
     *   - operation: The type of operation being performed
     *   - duration: How long the operation took
     *   - success: Whether the operation was successful
     */
    public func recordOperationCompleted(operation: String, duration: TimeInterval, success: Bool) {
        if success {
            successCounts[operation, default: 0] += 1
        } else {
            errorCounts[operation, default: 0] += 1
        }
        
        operationDurations[operation, default: []].append(duration)
    }
    
    /**
     * Records metrics for a completed operation.
     *
     * - Parameters:
     *   - type: The type of operation
     *   - startTime: When the operation started
     *   - endTime: When the operation ended
     *   - success: Whether the operation was successful
     */
    public func recordOperationMetrics(
        type: String,
        startTime: Date,
        endTime: Date,
        success: Bool
    ) {
        let duration = endTime.timeIntervalSince(startTime)
        
        // Record general operation metrics
        recordOperationStarted(operation: type)
        recordOperationCompleted(operation: type, duration: duration, success: success)
        
        // Add duration to running average
        operationDurations[type, default: []].append(duration)
    }
    
    /**
     * Records metrics for an operation that resulted in an error.
     *
     * - Parameters:
     *   - type: The type of operation
     *   - error: The error message
     *   - startTime: When the operation started
     *   - endTime: When the operation ended
     */
    public func recordErrorMetrics(
        type: String,
        error: String,
        startTime: Date,
        endTime: Date
    ) {
        let duration = endTime.timeIntervalSince(startTime)
        
        // Record general operation metrics
        recordOperationStarted(operation: type)
        recordOperationCompleted(operation: type, duration: duration, success: false)
        
        // Record error-specific metrics
        errorCounts[type, default: 0] += 1
        
        // Add duration to running average
        operationDurations[type, default: []].append(duration)
    }
    
    /**
     * Gets a summary of all metrics.
     *
     * - Returns: Dictionary with metrics information
     */
    public func getMetricsSummary() -> [String: Any] {
        var summary: [String: Any] = [:]
        
        // Add counts
        summary["totalOperations"] = operationCounts.values.reduce(0, +)
        summary["successfulOperations"] = successCounts.values.reduce(0, +)
        summary["failedOperations"] = errorCounts.values.reduce(0, +)
        
        // Add session information
        summary["sessionDuration"] = Date().timeIntervalSince(sessionStartTime)
        summary["lastResetTime"] = lastResetTime.timeIntervalSince1970
        
        // Add operation-specific metrics
        var operationsMetrics: [String: [String: Any]] = [:]
        
        for (operation, count) in operationCounts {
            var metrics: [String: Any] = [:]
            metrics["count"] = count
            metrics["successCount"] = successCounts[operation, default: 0]
            metrics["errorCount"] = errorCounts[operation, default: 0]
            
            let durations = operationDurations[operation, default: []]
            if !durations.isEmpty {
                // Calculate statistics
                let totalDuration = durations.reduce(0, +)
                let averageDuration = totalDuration / Double(durations.count)
                
                metrics["averageDuration"] = averageDuration
                
                // Calculate P95 if we have enough samples
                if durations.count >= 5 {
                    let sortedDurations = durations.sorted()
                    let p95Index = Int(Double(durations.count) * 0.95)
                    metrics["p95Duration"] = sortedDurations[p95Index]
                }
            }
            
            operationsMetrics[operation] = metrics
        }
        
        summary["operations"] = operationsMetrics
        return summary
    }
    
    /**
     * Gets success rates for different operations.
     *
     * - Returns: Dictionary mapping operation types to success rates (0-1)
     */
    public func getSuccessRates() -> [String: Double] {
        var rates: [String: Double] = [:]
        
        for (operation, count) in operationCounts where count > 0 {
            let successCount = successCounts[operation, default: 0]
            rates[operation] = Double(successCount) / Double(count)
        }
        
        return rates
    }
    
    /**
     * Resets all collected metrics.
     */
    public func resetMetrics() {
        operationCounts = [:]
        successCounts = [:]
        errorCounts = [:]
        operationDurations = [:]
        lastResetTime = Date()
    }
}
