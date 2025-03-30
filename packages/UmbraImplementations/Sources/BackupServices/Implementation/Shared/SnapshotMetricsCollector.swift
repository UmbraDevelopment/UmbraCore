import Foundation
import BackupInterfaces

/**
 * Collects performance and operational metrics for snapshot operations.
 * 
 * This actor-based implementation ensures thread-safe collection of metrics
 * while maintaining privacy by only recording aggregate statistics without
 * persisting individual operation details or user data.
 */
public actor SnapshotMetricsCollector {
    /// Performance metrics: operation type -> list of durations
    private var operationDurations: [String: [TimeInterval]] = [:]
    
    /// Operation count metrics: operation type -> count
    private var operationCounts: [String: Int] = [:]
    
    /// Error metrics: operation.errorType -> count
    private var errorCounts: [String: Int] = [:]
    
    /// Performance thresholds for alerting: operation type -> threshold in seconds
    private var performanceThresholds: [String: TimeInterval] = [
        "list": 5.0,
        "get": 3.0,
        "compare": 10.0,
        "delete": 5.0,
        "restore": 30.0
    ]
    
    /// Creates a new metrics collector with default thresholds
    public init() {}
    
    /**
     * Records the duration of a completed operation.
     *
     * - Parameters:
     *   - type: The type of operation (e.g., "list", "get")
     *   - duration: How long the operation took in seconds
     */
    public func recordOperation(type: String, duration: TimeInterval) {
        if operationDurations[type] == nil {
            operationDurations[type] = []
        }
        
        operationDurations[type]?.append(duration)
        operationCounts[type, default: 0] += 1
        
        // Check if this operation exceeded performance thresholds
        if let threshold = performanceThresholds[type], duration > threshold {
            // In a real implementation, we might want to log a warning
            // or trigger an alert, but we'll keep it simple here
        }
    }
    
    /**
     * Records an operation error.
     *
     * - Parameters:
     *   - operation: The operation that failed
     *   - errorType: The type of error that occurred
     */
    public func recordError(operation: String, errorType: String) {
        let key = "\(operation).\(errorType)"
        errorCounts[key, default: 0] += 1
    }
    
    /**
     * Gets a summary of collected metrics.
     *
     * - Returns: A dictionary with metrics summaries
     */
    public func getMetricsSummary() -> [String: Any] {
        var summary: [String: Any] = [:]
        
        // Calculate average durations
        var avgDurations: [String: TimeInterval] = [:]
        for (op, durations) in operationDurations {
            avgDurations[op] = durations.reduce(0, +) / TimeInterval(durations.count)
        }
        
        // Calculate p95 durations
        var p95Durations: [String: TimeInterval] = [:]
        for (op, durations) in operationDurations {
            let sortedDurations = durations.sorted()
            if sortedDurations.count > 0 {
                let index = Int(Double(sortedDurations.count) * 0.95)
                p95Durations[op] = sortedDurations[min(index, sortedDurations.count - 1)]
            }
        }
        
        summary["averageDurations"] = avgDurations
        summary["p95Durations"] = p95Durations
        summary["operationCounts"] = operationCounts
        summary["errorCounts"] = errorCounts
        summary["totalOperationCount"] = operationCounts.values.reduce(0, +)
        summary["totalErrorCount"] = errorCounts.values.reduce(0, +)
        
        return summary
    }
    
    /**
     * Gets the success rate for operations.
     *
     * - Returns: A dictionary mapping operation types to success rates (0-1)
     */
    public func getSuccessRates() -> [String: Double] {
        var successRates: [String: Double] = [:]
        
        for (op, count) in operationCounts {
            // Count errors for this operation type
            let opErrors = errorCounts.filter { key, _ in
                key.starts(with: "\(op).")
            }.values.reduce(0, +)
            
            // Calculate success rate
            let successRate = count > 0 ? Double(count - opErrors) / Double(count) : 1.0
            successRates[op] = successRate
        }
        
        return successRates
    }
    
    /**
     * Resets all collected metrics.
     */
    public func resetMetrics() {
        operationDurations.removeAll()
        operationCounts.removeAll()
        errorCounts.removeAll()
    }
}
