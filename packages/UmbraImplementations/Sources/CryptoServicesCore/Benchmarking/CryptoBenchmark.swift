import CoreSecurityTypes
import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces

/// CryptoBenchmark
///
/// A benchmarking utility for measuring the performance of different cryptographic
/// service implementations. This utility provides standardised methods for comparing
/// performance characteristics across different implementations and platforms.
///
/// The benchmarks measure execution time, CPU usage, and memory consumption for
/// common cryptographic operations.
public actor CryptoBenchmark {
  /// The service to benchmark
  private let cryptoService: CryptoServiceProtocol

  /// Logger for recording benchmark results
  private let logger: LoggingProtocol?

  /// Number of iterations for each benchmark operation
  private let iterations: Int

  /// The description of the service being benchmarked
  private let serviceDescription: String

  /// Initialises a new benchmark for a cryptographic service.
  ///
  /// - Parameters:
  ///   - cryptoService: The cryptographic service to benchmark
  ///   - logger: Optional logger for recording results
  ///   - iterations: Number of iterations for each benchmark (default: 100)
  ///   - serviceDescription: Description of the service for reporting
  public init(
    cryptoService: CryptoServiceProtocol,
    logger: LoggingProtocol?,
    iterations: Int=100,
    serviceDescription: String
  ) {
    self.cryptoService=cryptoService
    self.logger=logger
    self.iterations=iterations
    self.serviceDescription=serviceDescription
  }

  /// Runs all benchmarks for the cryptographic service.
  ///
  /// This method executes all available benchmark suites and returns
  /// a comprehensive benchmark report with performance metrics for
  /// each operation type.
  ///
  /// - Returns: A benchmark report with all results
  public func runAllBenchmarks() async -> BenchmarkReport {
    var report=BenchmarkReport(
      serviceDescription: serviceDescription,
      date: Date(),
      benchmarks: []
    )

    // Log start of benchmarking
    await logger?.debug(
      "Starting cryptographic service benchmark for \(serviceDescription)",
      context: createLogContext(operation: "runAllBenchmarks")
    )

    // Run encryption benchmark
    let encryptionResult=await benchmarkEncryption()
    report.benchmarks.append(encryptionResult)

    // Run hashing benchmark
    let hashingResult=await benchmarkHashing()
    report.benchmarks.append(hashingResult)

    // Run key generation benchmark
    let keyGenResult=await benchmarkKeyGeneration()
    report.benchmarks.append(keyGenResult)

    // Run data storage benchmark
    let storageResult=await benchmarkStorage()
    report.benchmarks.append(storageResult)

    // Log completion of benchmarking
    await logger?.debug(
      "Completed cryptographic service benchmark for \(serviceDescription)",
      context: createLogContext(operation: "runAllBenchmarks")
    )

    return report
  }

  /// Benchmarks encryption operations.
  ///
  /// Tests the performance of encrypting data of various sizes using
  /// the cryptographic service implementation.
  ///
  /// - Returns: Benchmark results for encryption operations
  private func benchmarkEncryption() async -> BenchmarkResult {
    let startTime=CFAbsoluteTimeGetCurrent()
    var success=0
    var failure=0
    var totalBytes=0

    // Test data sizes from 1KB to 1MB
    let testSizes=[1024, 10240, 102_400, 1_048_576]

    for size in testSizes {
      await logger?.debug(
        "Benchmarking encryption with \(size) bytes",
        context: createLogContext(operation: "benchmarkEncryption")
      )

      // Generate random test data
      let testData=generateRandomData(size: size)
      let testDataID="test-data-\(UUID().uuidString)"
      // Remove unused variable warning
      _="test-key-\(UUID().uuidString)"

      // Store the test data
      let importResult=await cryptoService.importData(testData, customIdentifier: testDataID)
      guard case .success=importResult else {
        await logger?.error(
          "Failed to import test data for encryption benchmark",
          context: createLogContext(operation: "benchmarkEncryption")
        )
        continue
      }

      // Generate a key for encryption
      let keyResult=await cryptoService.generateKey(length: 32, options: nil)
      guard case let .success(actualKeyID)=keyResult else {
        await logger?.error(
          "Failed to generate key for encryption benchmark",
          context: createLogContext(operation: "benchmarkEncryption")
        )
        continue
      }

      // Perform encryption benchmark
      for _ in 0..<iterations {
        let result=await cryptoService.encrypt(
          dataIdentifier: testDataID,
          keyIdentifier: actualKeyID,
          options: nil
        )

        switch result {
          case .success:
            success += 1
            totalBytes += size
          case .failure:
            failure += 1
        }
      }
    }

    let endTime=CFAbsoluteTimeGetCurrent()
    let totalTime=endTime - startTime
    let operationsPerSecond=Double(success) / totalTime
    let bytesPerSecond=Double(totalBytes) / totalTime

    return BenchmarkResult(
      operationType: "Encryption",
      totalOperations: success + failure,
      successfulOperations: success,
      failedOperations: failure,
      totalTimeSeconds: totalTime,
      operationsPerSecond: operationsPerSecond,
      throughputBytesPerSecond: bytesPerSecond
    )
  }

  /// Benchmarks hashing operations.
  ///
  /// Tests the performance of hashing data of various sizes using
  /// the cryptographic service implementation.
  ///
  /// - Returns: Benchmark results for hashing operations
  private func benchmarkHashing() async -> BenchmarkResult {
    let startTime=CFAbsoluteTimeGetCurrent()
    var success=0
    var failure=0
    var totalBytes=0

    // Test data sizes from 1KB to 1MB
    let testSizes=[1024, 10240, 102_400, 1_048_576]

    for size in testSizes {
      await logger?.debug(
        "Benchmarking hashing with \(size) bytes",
        context: createLogContext(operation: "benchmarkHashing")
      )

      // Generate random test data
      let testData=generateRandomData(size: size)
      let testDataID="test-hash-data-\(UUID().uuidString)"

      // Store the test data
      let importResult=await cryptoService.importData(testData, customIdentifier: testDataID)
      guard case .success=importResult else {
        await logger?.error(
          "Failed to import test data for hashing benchmark",
          context: createLogContext(operation: "benchmarkHashing")
        )
        continue
      }

      // Perform hashing benchmark
      for _ in 0..<iterations {
        let result=await cryptoService.hash(
          dataIdentifier: testDataID,
          options: nil
        )

        switch result {
          case .success:
            success += 1
            totalBytes += size
          case .failure:
            failure += 1
        }
      }
    }

    let endTime=CFAbsoluteTimeGetCurrent()
    let totalTime=endTime - startTime
    let operationsPerSecond=Double(success) / totalTime
    let bytesPerSecond=Double(totalBytes) / totalTime

    return BenchmarkResult(
      operationType: "Hashing",
      totalOperations: success + failure,
      successfulOperations: success,
      failedOperations: failure,
      totalTimeSeconds: totalTime,
      operationsPerSecond: operationsPerSecond,
      throughputBytesPerSecond: bytesPerSecond
    )
  }

  /// Benchmarks key generation operations.
  ///
  /// Tests the performance of generating cryptographic keys of various lengths
  /// using the cryptographic service implementation.
  ///
  /// - Returns: Benchmark results for key generation operations
  private func benchmarkKeyGeneration() async -> BenchmarkResult {
    let startTime=CFAbsoluteTimeGetCurrent()
    var success=0
    var failure=0

    // Test key sizes (in bytes)
    let keySizes=[16, 24, 32, 64]

    for size in keySizes {
      await logger?.debug(
        "Benchmarking key generation with \(size * 8) bits",
        context: createLogContext(operation: "benchmarkKeyGeneration")
      )

      // Perform key generation benchmark
      for _ in 0..<iterations {
        let result=await cryptoService.generateKey(
          length: size,
          options: nil
        )

        switch result {
          case .success:
            success += 1
          case .failure:
            failure += 1
        }
      }
    }

    let endTime=CFAbsoluteTimeGetCurrent()
    let totalTime=endTime - startTime
    let operationsPerSecond=Double(success) / totalTime

    return BenchmarkResult(
      operationType: "Key Generation",
      totalOperations: success + failure,
      successfulOperations: success,
      failedOperations: failure,
      totalTimeSeconds: totalTime,
      operationsPerSecond: operationsPerSecond,
      throughputBytesPerSecond: nil // Not applicable for key generation
    )
  }

  /// Benchmarks storage operations (import/export/store/retrieve).
  ///
  /// Tests the performance of storing and retrieving data of various sizes
  /// using the cryptographic service implementation.
  ///
  /// - Returns: Benchmark results for storage operations
  private func benchmarkStorage() async -> BenchmarkResult {
    let startTime=CFAbsoluteTimeGetCurrent()
    var success=0
    var failure=0
    var totalBytes=0

    // Test data sizes from 1KB to 1MB
    let testSizes=[1024, 10240, 102_400, 1_048_576]

    for size in testSizes {
      await logger?.debug(
        "Benchmarking storage with \(size) bytes",
        context: createLogContext(operation: "benchmarkStorage")
      )

      // Generate random test data
      let testData=generateRandomData(size: size)

      // Perform storage benchmark
      for i in 0..<iterations {
        let dataID="test-storage-data-\(UUID().uuidString)-\(i)"

        // Test import operation
        let importResult=await cryptoService.importData(testData, customIdentifier: dataID)
        guard case .success=importResult else {
          failure += 1
          continue
        }

        // Test export operation
        let exportResult=await cryptoService.exportData(identifier: dataID)
        guard case .success=exportResult else {
          failure += 1
          continue
        }

        success += 1
        totalBytes += size
      }
    }

    let endTime=CFAbsoluteTimeGetCurrent()
    let totalTime=endTime - startTime
    let operationsPerSecond=Double(success) / totalTime
    let bytesPerSecond=Double(totalBytes) / totalTime

    return BenchmarkResult(
      operationType: "Storage (Import/Export)",
      totalOperations: success + failure,
      successfulOperations: success,
      failedOperations: failure,
      totalTimeSeconds: totalTime,
      operationsPerSecond: operationsPerSecond,
      throughputBytesPerSecond: bytesPerSecond
    )
  }

  /// Generates random data of the specified size.
  ///
  /// - Parameter size: Size of the data to generate in bytes
  /// - Returns: Array of random bytes
  private func generateRandomData(size: Int) -> [UInt8] {
    var data=[UInt8](repeating: 0, count: size)

    // Fill with random data
    for i in 0..<size {
      data[i]=UInt8.random(in: 0...255)
    }

    return data
  }

  /// Creates a log context for benchmark operations.
  ///
  /// - Parameter operation: The name of the benchmark operation
  /// - Returns: A configured log context
  private func createLogContext(operation: String) -> LogContextDTO {
    BaseLogContextDTO(
      domainName: "CryptoBenchmark",
      operation: operation,
      category: "Performance",
      source: "CryptoBenchmark",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "service", value: serviceDescription)
        .withPublic(key: "iterations", value: String(iterations))
    )
  }
}

/// BenchmarkReport
///
/// A comprehensive report of cryptographic performance benchmark results.
///
/// This structure contains performance metrics for various cryptographic
/// operations performed by a specific service implementation.
public struct BenchmarkReport: Codable, Equatable, Sendable {
  /// Description of the service that was benchmarked
  public let serviceDescription: String

  /// Date when the benchmark was performed
  public let date: Date

  /// Collection of benchmark results for different operation types
  public var benchmarks: [BenchmarkResult]

  /// Formats the report as a pretty-printed JSON string
  ///
  /// - Returns: JSON representation of the report, or nil if serialisation fails
  public func asJSON() -> String? {
    let encoder=JSONEncoder()
    encoder.outputFormatting=[.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601

    guard let data=try? encoder.encode(self) else {
      return nil
    }

    return String(data: data, encoding: .utf8)
  }

  /// Formats the report as a human-readable string
  ///
  /// - Returns: A formatted string representation of the benchmark report
  public func asString() -> String {
    let dateFormatter=DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .medium

    var output="""
      Cryptographic Service Benchmark Report
      Service: \(serviceDescription)
      Date: \(dateFormatter.string(from: date))

      """

    for result in benchmarks {
      output += """

        Operation: \(result.operationType)
        - Total operations: \(result.totalOperations)
        - Successful: \(result.successfulOperations)
        - Failed: \(result.failedOperations)
        - Total time: \(String(format: "%.3f", result.totalTimeSeconds)) seconds
        - Operations/second: \(String(format: "%.2f", result.operationsPerSecond))

        """

      if let throughput=result.throughputBytesPerSecond {
        let mbPerSecond=throughput / 1_048_576.0
        output += "- Throughput: \(String(format: "%.2f", mbPerSecond)) MB/s\n"
      }
    }

    return output
  }
}

/// BenchmarkResult
///
/// Performance metrics for a specific type of cryptographic operation.
///
/// This structure contains detailed statistics about the performance of
/// a particular cryptographic operation type, including execution times
/// and throughput measurements.
public struct BenchmarkResult: Codable, Equatable, Sendable {
  /// The type of operation that was benchmarked
  public let operationType: String

  /// Total number of operations attempted
  public let totalOperations: Int

  /// Number of operations that completed successfully
  public let successfulOperations: Int

  /// Number of operations that failed
  public let failedOperations: Int

  /// Total time spent on all operations in seconds
  public let totalTimeSeconds: Double

  /// Number of operations executed per second
  public let operationsPerSecond: Double

  /// Data throughput in bytes per second (optional)
  public let throughputBytesPerSecond: Double?
}
