import Foundation
import SecurityCoreTypes
import os.log

/**
 # Performance Benchmarking for Security Operations
 
 This module provides utilities for measuring the performance of security operations,
 allowing for optimisation, monitoring, and detection of potential performance issues
 that could impact security or user experience.
 
 ## Security Relevance
 
 Performance benchmarking is critical for security operations for several reasons:
 
 1. **Denial of Service Prevention**: Identifying operations that could be
    exploited for DoS attacks due to excessive resource consumption.
    
 2. **Side-Channel Protection**: Detecting timing variations that might leak
    information about sensitive operations or data.
    
 3. **User Experience**: Ensuring that security doesn't compromise usability by
    introducing unacceptable delays.
    
 4. **Resource Optimisation**: Identifying inefficient operations that consume
    excessive CPU, memory, or other resources.
 
 ## Implementation Approach
 
 This benchmarking framework:
 
 - Provides high-precision timing for synchronous and asynchronous operations
 - Enables statistical analysis of performance data
 - Supports categorisation and metadata for proper analysis
 - Integrates with the logging system for continuous monitoring
 
 ## Usage Guidelines
 
 - Use benchmarking in development and testing environments to establish baselines
 - Include limited benchmarking in production for critical operations
 - Be mindful that benchmarking itself adds overhead
 - Protect benchmark results as they may reveal information about the system
 */

/// A utility for measuring the performance of security operations with
/// high precision and detailed metadata collection
public struct PerformanceBenchmark {
    /// The name of the operation being benchmarked
    private let operationName: String
    
    /// The category of the operation
    private let category: String
    
    /// Additional metadata for the benchmark
    private let metadata: [String: String]
    
    /// The start time of the benchmark
    private var startTime: DispatchTime?
    
    /// The end time of the benchmark
    private var endTime: DispatchTime?
    
    /// The logger to use for recording benchmark results
    private let logger: Logger
    
    /**
     Initialises a new performance benchmark with descriptive information.
     
     A benchmark should represent a specific operation or task that you want
     to measure. The operation name, category, and metadata help identify
     and analyse the benchmark results.
     
     ## Example
     
     ```swift
     let benchmark = PerformanceBenchmark(
         operationName: "AES-256-GCM Encryption",
         category: "DataEncryption",
         metadata: ["dataSize": "1024", "keyType": "ephemeral"]
     )
     ```
     
     - Parameters:
        - operationName: A descriptive name for the operation being benchmarked
        - category: A category for grouping related operations
        - metadata: Additional key-value pairs providing context for the benchmark
     */
    public init(
        operationName: String,
        category: String,
        metadata: [String: String] = [:]
    ) {
        self.operationName = operationName
        self.category = category
        self.metadata = metadata
        self.logger = Logger(subsystem: "com.umbra.security", category: "Performance")
    }
    
    /**
     Starts the benchmark timer.
     
     Call this method immediately before the operation you want to measure.
     For more convenient timing, consider using the static `measure` methods
     which handle starting and stopping automatically.
     
     ## Example
     
     ```swift
     var benchmark = PerformanceBenchmark(operationName: "KeyGeneration", category: "KeyManagement")
     benchmark = benchmark.start()
     
     // Operation to measure
     let key = generateCryptographicKey()
     
     let duration = benchmark.stop()
     ```
     
     - Returns: The benchmark instance with the timer started (for method chaining)
     */
    public func start() -> Self {
        var benchmark = self
        benchmark.startTime = DispatchTime.now()
        return benchmark
    }
    
    /**
     Stops the benchmark timer and records the results.
     
     Call this method immediately after the operation you want to measure has completed.
     The method will calculate the duration, log the result, and return the duration
     in milliseconds.
     
     - Returns: The duration of the benchmarked operation in milliseconds
     */
    @discardableResult
    public func stop() -> Double {
        guard let startTime = startTime else {
            logger.error("Benchmark for \(operationName) stopped without being started")
            return 0
        }
        
        let endTime = DispatchTime.now()
        let duration = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000 // Convert to milliseconds
        
        // Log the benchmark result
        logger.debug("Benchmark: \(operationName) [\(category)] completed in \(duration, privacy: .public) ms")
        
        // Log additional metadata if present
        if !metadata.isEmpty {
            let metadataString = metadata.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            logger.debug("Benchmark metadata: \(metadataString, privacy: .public)")
        }
        
        return duration
    }
}

/// Convenience extension providing static methods for one-shot benchmarking
public extension PerformanceBenchmark {
    /**
     Measures the execution time of a synchronous operation.
     
     This static method provides a convenient way to benchmark a synchronous
     closure without manually creating and managing a benchmark instance.
     
     ## Example
     
     ```swift
     let (encryptedData, duration) = PerformanceBenchmark.measure(
         operationName: "FileEncryption",
         category: "StorageSecurity",
         metadata: ["fileSize": "\(fileData.count)"]
     ) {
         return encryptFile(fileData, key: encryptionKey)
     }
     
     print("Encryption took \(duration) ms")
     ```
     
     - Parameters:
        - operationName: A descriptive name for the operation
        - category: A category for grouping related operations
        - metadata: Additional context for the benchmark
        - operation: The closure to measure
     
     - Returns: A tuple containing the result of the operation and the duration in milliseconds
     - Throws: Rethrows any errors from the provided operation closure
     */
    static func measure<T>(
        operationName: String,
        category: String,
        metadata: [String: String] = [:],
        operation: () throws -> T
    ) rethrows -> (result: T, durationMs: Double) {
        let benchmark = PerformanceBenchmark(
            operationName: operationName,
            category: category,
            metadata: metadata
        ).start()
        
        let result = try operation()
        let duration = benchmark.stop()
        
        return (result, duration)
    }
    
    /**
     Measures the execution time of an asynchronous operation.
     
     This static method provides a convenient way to benchmark an asynchronous
     closure without manually creating and managing a benchmark instance.
     It properly handles async/await timing to ensure accurate measurements.
     
     ## Example
     
     ```swift
     let (keyPair, duration) = await PerformanceBenchmark.measure(
         operationName: "KeyPairGeneration",
         category: "AsymmetricCrypto"
     ) {
         return await generateAsymmetricKeyPair()
     }
     
     print("Key pair generation took \(duration) ms")
     ```
     
     - Parameters:
        - operationName: A descriptive name for the operation
        - category: A category for grouping related operations
        - metadata: Additional context for the benchmark
        - operation: The async closure to measure
     
     - Returns: A tuple containing the result of the operation and the duration in milliseconds
     - Throws: Rethrows any errors from the provided operation closure
     */
    static func measure<T>(
        operationName: String,
        category: String,
        metadata: [String: String] = [:],
        operation: () async throws -> T
    ) async rethrows -> (result: T, durationMs: Double) {
        let benchmark = PerformanceBenchmark(
            operationName: operationName,
            category: category,
            metadata: metadata
        ).start()
        
        let result = try await operation()
        let duration = benchmark.stop()
        
        return (result, duration)
    }
}

/**
 Protocol that enables performance benchmarking capabilities for any security service.
 
 By implementing this protocol, a security service can easily integrate benchmarking
 into its operations while maintaining a clean separation of concerns.
 */
public protocol PerformanceBenchmarkable {
    /**
     The category name used for grouping benchmark results from this service.
     
     This property allows benchmarks to be categorised by service type, enabling
     more organised analysis and reporting.
     */
    var benchmarkCategory: String { get }
    
    /**
     Generates benchmark metadata specific to this service.
     
     Implement this method to provide relevant context information for benchmarks
     from this service, such as configuration settings, operational modes, or
     other factors that might affect performance.
     
     - Parameter operationName: The name of the operation being benchmarked
     - Returns: A dictionary of metadata key-value pairs
     */
    func benchmarkMetadata(for operationName: String) -> [String: String]
}

/// Default implementation of benchmarking capabilities for conforming services
public extension PerformanceBenchmarkable {
    /**
     Default benchmark category based on the type name.
     
     This implementation extracts the service type name for use as the category,
     which is sufficient for most services. Override this property if you need
     a more specific category name.
     */
    var benchmarkCategory: String {
        String(describing: type(of: self))
    }
    
    /**
     Default implementation that provides no additional metadata.
     
     Override this method in your service implementation to provide
     service-specific context information for benchmarks.
     
     - Parameter operationName: The name of the operation
     - Returns: An empty dictionary by default
     */
    func benchmarkMetadata(for operationName: String) -> [String: String] {
        [:]
    }
    
    /**
     Benchmarks a synchronous operation within this service.
     
     This method handles the details of creating a properly configured benchmark
     for the service and executing the provided operation.
     
     ## Example
     
     ```swift
     class EncryptionService: PerformanceBenchmarkable {
         func encryptData(_ data: Data, key: SymmetricKey) -> EncryptedData {
             return benchmark("DataEncryption") {
                 // Actual encryption implementation
                 return performEncryption(data, key)
             }
         }
     }
     ```
     
     - Parameters:
        - operationName: The name of the operation to benchmark
        - operation: The closure containing the operation to measure
     
     - Returns: The result of the operation
     - Throws: Rethrows any errors from the provided operation
     */
    func benchmark<T>(
        _ operationName: String,
        operation: () throws -> T
    ) rethrows -> T {
        let metadata = benchmarkMetadata(for: operationName)
        let (result, _) = try PerformanceBenchmark.measure(
            operationName: operationName,
            category: benchmarkCategory,
            metadata: metadata,
            operation: operation
        )
        return result
    }
    
    /**
     Benchmarks an asynchronous operation within this service.
     
     This method handles the details of creating a properly configured benchmark
     for the service and executing the provided asynchronous operation.
     
     ## Example
     
     ```swift
     class KeyGenerationService: PerformanceBenchmarkable {
         func generateKeyPair() async throws -> KeyPair {
             return try await benchmark("KeyPairGeneration") {
                 // Actual key generation implementation
                 return try await performKeyGeneration()
             }
         }
     }
     ```
     
     - Parameters:
        - operationName: The name of the operation to benchmark
        - operation: The async closure containing the operation to measure
     
     - Returns: The result of the operation
     - Throws: Rethrows any errors from the provided operation
     */
    func benchmark<T>(
        _ operationName: String,
        operation: () async throws -> T
    ) async rethrows -> T {
        let metadata = benchmarkMetadata(for: operationName)
        let (result, _) = try await PerformanceBenchmark.measure(
            operationName: operationName,
            category: benchmarkCategory,
            metadata: metadata,
            operation: operation
        )
        return result
    }
}

/**
 A collection of performance statistics for security operations.
 
 This struct collects and analyses performance measurements for security
 operations, enabling monitoring, optimisation, and anomaly detection.
 */
public struct PerformanceStatistics: Sendable {
    /**
     Represents a single performance measurement with timestamp and metadata.
     
     Individual measurements provide detailed information about specific
     operation executions, including contextual information in the metadata.
     */
    public struct Measurement: Sendable {
        /// The duration of the operation in milliseconds
        public let durationMs: Double
        
        /// The timestamp when the measurement was recorded
        public let timestamp: Date
        
        /// Additional metadata for the measurement
        public let metadata: [String: String]
        
        /**
         Initialises a new performance measurement.
         
         - Parameters:
            - durationMs: The duration of the operation in milliseconds
            - timestamp: When the measurement was recorded (defaults to current time)
            - metadata: Additional context information for this measurement
         */
        public init(durationMs: Double, timestamp: Date = Date(), metadata: [String: String] = [:]) {
            self.durationMs = durationMs
            self.timestamp = timestamp
            self.metadata = metadata
        }
    }
    
    /// Statistics for each operation type, indexed by operation name
    private var operationStats: [String: [Measurement]] = [:]
    
    /**
     Adds a measurement for an operation to the statistics collection.
     
     Call this method each time you want to record a performance measurement.
     The measurements are stored by operation name to enable statistical analysis.
     
     ## Example
     
     ```swift
     var stats = PerformanceStatistics()
     
     // After performing an operation
     stats.addMeasurement(
         duration: 42.5,
         for: "RSA-2048-KeyGeneration",
         metadata: ["hardware": "M1", "implementation": "CryptoKit"]
     )
     ```
     
     - Parameters:
        - duration: The duration of the operation in milliseconds
        - operationName: The name of the operation
        - metadata: Additional context information for this measurement
     */
    public mutating func addMeasurement(
        duration: Double,
        for operationName: String,
        metadata: [String: String] = [:]
    ) {
        let measurement = Measurement(
            durationMs: duration,
            metadata: metadata
        )
        
        if operationStats[operationName] == nil {
            operationStats[operationName] = []
        }
        
        operationStats[operationName]?.append(measurement)
    }
    
    /**
     Calculates statistical metrics for a specific operation.
     
     This method analyses all measurements for the specified operation
     and returns key statistical values including mean, median, min, max,
     and count.
     
     ## Example
     
     ```swift
     let stats = performanceStats.statisticsFor("AES-256-Encryption")
     print("Average encryption time: \(stats["mean"] ?? 0) ms")
     print("Maximum encryption time: \(stats["max"] ?? 0) ms")
     ```
     
     - Parameter operationName: The name of the operation to analyse
     - Returns: A dictionary of statistics including mean, median, min, max, and count
     */
    public func statisticsFor(_ operationName: String) -> [String: Double] {
        guard let measurements = operationStats[operationName], !measurements.isEmpty else {
            return [:]
        }
        
        let durations = measurements.map { $0.durationMs }
        let count = Double(durations.count)
        let sum = durations.reduce(0, +)
        let mean = sum / count
        
        let sortedDurations = durations.sorted()
        let median: Double
        if durations.count % 2 == 0 {
            let midIndex = durations.count / 2
            median = (sortedDurations[midIndex - 1] + sortedDurations[midIndex]) / 2.0
        } else {
            median = sortedDurations[durations.count / 2]
        }
        
        let min = sortedDurations.first ?? 0
        let max = sortedDurations.last ?? 0
        
        return [
            "mean": mean,
            "median": median,
            "min": min,
            "max": max,
            "count": count
        ]
    }
    
    /**
     Retrieves all measurements for a specific operation.
     
     This method returns the raw measurements for detailed analysis or
     custom statistical processing beyond what is provided by the
     `statisticsFor` method.
     
     - Parameter operationName: The name of the operation
     - Returns: An array of measurements for the operation
     */
    public func measurementsFor(_ operationName: String) -> [Measurement] {
        return operationStats[operationName] ?? []
    }
    
    /**
     Gets a list of all operation names that have measurements.
     
     Use this method to discover which operations have been measured,
     particularly when analysing performance across an entire system.
     
     - Returns: An array of operation names with measurements
     */
    public func allOperationNames() -> [String] {
        return Array(operationStats.keys)
    }
    
    /**
     Generates a formatted report of all statistics.
     
     This method creates a markdown-formatted report of the performance
     statistics for all measured operations, suitable for inclusion in
     documentation, logs, or reporting tools.
     
     ## Example Output
     
     ```
     # Performance Statistics Report
     
     ## AES-256-Encryption
     
     - Mean: 1.25 ms
     - Median: 1.20 ms
     - Min: 0.98 ms
     - Max: 1.75 ms
     - Count: 100 measurements
     
     ## RSA-KeyGeneration
     
     - Mean: 342.50 ms
     - Median: 338.20 ms
     - Min: 310.15 ms
     - Max: 412.30 ms
     - Count: 25 measurements
     ```
     
     - Returns: A string containing the formatted report
     */
    public func generateReport() -> String {
        var report = "# Performance Statistics Report\n\n"
        
        for operationName in allOperationNames().sorted() {
            let stats = statisticsFor(operationName)
            guard !stats.isEmpty else { continue }
            
            report += "## \(operationName)\n\n"
            report += "- Mean: \(String(format: "%.2f", stats["mean"] ?? 0)) ms\n"
            report += "- Median: \(String(format: "%.2f", stats["median"] ?? 0)) ms\n"
            report += "- Min: \(String(format: "%.2f", stats["min"] ?? 0)) ms\n"
            report += "- Max: \(String(format: "%.2f", stats["max"] ?? 0)) ms\n"
            report += "- Count: \(Int(stats["count"] ?? 0)) measurements\n\n"
        }
        
        return report
    }
}
