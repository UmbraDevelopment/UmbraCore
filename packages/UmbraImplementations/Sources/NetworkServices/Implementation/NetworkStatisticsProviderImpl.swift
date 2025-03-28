import Foundation
import NetworkInterfaces

/// Implementation of NetworkStatisticsProvider for collecting network metrics
public actor NetworkStatisticsProviderImpl: NetworkStatisticsProvider {
    /// Current statistics
    private var statistics: NetworkStatistics
    
    /// Initialise a new NetworkStatisticsProviderImpl
    /// - Parameter initialStatistics: Initial statistics (defaults to empty)
    public init(initialStatistics: NetworkStatistics = .empty) {
        self.statistics = initialStatistics
    }
    
    /// Get the current network statistics
    public func getStatistics() async -> NetworkStatistics {
        statistics
    }
    
    /// Reset the network statistics to initial values
    public func resetStatistics() async {
        statistics = .empty
    }
    
    /// Add a completed request to the statistics
    public func recordRequest(
        response: NetworkResponseDTO,
        requestSizeBytes: Int64,
        responseSizeBytes: Int64,
        durationMs: Double
    ) async {
        // Update total requests
        let totalRequests = statistics.totalRequests + 1
        
        // Update successful/failed requests
        let successfulRequests = statistics.successfulRequests + (response.isSuccess ? 1 : 0)
        let failedRequests = statistics.failedRequests + (response.isSuccess ? 0 : 1)
        
        // Update bytes sent/received
        let bytesSent = statistics.bytesSent + requestSizeBytes
        let bytesReceived = statistics.bytesReceived + responseSizeBytes
        
        // Update average response time
        let totalResponseTime = statistics.averageResponseTimeMs * Double(statistics.totalRequests)
        let newAverageResponseTime = (totalResponseTime + durationMs) / Double(totalRequests)
        
        // Update status code distribution
        var statusCodeDistribution = statistics.statusCodeDistribution
        let statusCode = response.statusCode
        statusCodeDistribution[statusCode] = (statusCodeDistribution[statusCode] ?? 0) + 1
        
        // Update error type distribution
        var errorTypeDistribution = statistics.errorTypeDistribution
        if let error = response.error {
            let errorType = String(describing: type(of: error))
            errorTypeDistribution[errorType] = (errorTypeDistribution[errorType] ?? 0) + 1
        }
        
        // Create updated statistics
        statistics = NetworkStatistics(
            totalRequests: totalRequests,
            successfulRequests: successfulRequests,
            failedRequests: failedRequests,
            bytesSent: bytesSent,
            bytesReceived: bytesReceived,
            averageResponseTimeMs: newAverageResponseTime,
            statusCodeDistribution: statusCodeDistribution,
            errorTypeDistribution: errorTypeDistribution,
            collectionTimestamp: currentTimestampMs()
        )
    }
    
    /// Get the current time in milliseconds since UNIX epoch
    private func currentTimestampMs() -> Int64 {
        let timeInSeconds = Date().timeIntervalSince1970
        return Int64(timeInSeconds * 1000)
    }
}
