import CoreSecurityTypes
import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces

/// BenchmarkRunner
///
/// A command-line utility for running performance benchmarks across
/// different cryptographic service implementations.
///
/// This tool allows developers to compare the performance characteristics
/// of different cryptographic implementations to determine which is most
/// suitable for specific use cases.
public struct BenchmarkRunner {
  /// Available cryptographic service types for benchmarking
  public enum ServiceType: String, CaseIterable {
    case standard="Standard"
    case appleCryptoKit="Apple CryptoKit"
    case ring="Ring FFI"
    case all="All"
  }

  /// Configuration options for the benchmark runner
  public struct Configuration {
    /// The service types to benchmark
    public let serviceTypes: [ServiceType]

    /// Number of iterations for each benchmark operation
    public let iterations: Int

    /// Whether to save benchmark results to a file
    public let saveToFile: Bool

    /// Directory where benchmark results will be saved
    public let outputDirectory: String?

    /// Initialises a new benchmark configuration.
    ///
    /// - Parameters:
    ///   - serviceTypes: The service types to benchmark
    ///   - iterations: Number of iterations for each benchmark
    ///   - saveToFile: Whether to save results to a file
    ///   - outputDirectory: Directory for saving results
    public init(
      serviceTypes: [ServiceType]=[.all],
      iterations: Int=100,
      saveToFile: Bool=false,
      outputDirectory: String?=nil
    ) {
      self.serviceTypes=serviceTypes
      self.iterations=iterations
      self.saveToFile=saveToFile
      self.outputDirectory=outputDirectory
    }
  }

  /// The benchmark configuration
  private let configuration: Configuration

  /// Logger for recording benchmark operations
  private let logger: LoggingProtocol?

  /// Initialises a new benchmark runner.
  ///
  /// - Parameters:
  ///   - configuration: Benchmark configuration options
  ///   - logger: Optional logger for recording operations
  public init(configuration: Configuration, logger: LoggingProtocol?=nil) {
    self.configuration=configuration
    self.logger=logger
  }

  /// Runs benchmarks according to the configuration.
  ///
  /// This method creates and benchmarks the requested service types,
  /// then outputs the results according to the configuration.
  ///
  /// - Returns: A dictionary mapping service types to benchmark reports
  public func runBenchmarks() async -> [String: BenchmarkReport] {
    var results: [String: BenchmarkReport]=[:]

    // Determine which service types to benchmark
    let servicesToBenchmark: [ServiceType]=if configuration.serviceTypes.contains(.all) {
      ServiceType.allCases.filter { $0 != .all }
    } else {
      configuration.serviceTypes
    }

    // Log benchmark start
    await logger?.info(
      "Starting cryptographic service benchmarks",
      context: createLogContext(operation: "runBenchmarks")
    )

    // Run benchmarks for each service type
    for serviceType in servicesToBenchmark {
      guard let service=await createService(type: serviceType) else {
        await logger?.error(
          "Failed to create service for benchmarking: \(serviceType.rawValue)",
          context: createLogContext(operation: "runBenchmarks")
        )
        continue
      }

      // Create a benchmark for this service
      let benchmark=CryptoBenchmark(
        cryptoService: service,
        logger: logger,
        iterations: configuration.iterations,
        serviceDescription: serviceType.rawValue
      )

      // Run all benchmark tests
      let report=await benchmark.runAllBenchmarks()
      results[serviceType.rawValue]=report

      // Output the results to console
      print("\n" + report.asString())

      // Save results to file if requested
      if configuration.saveToFile, let outputDirectory=configuration.outputDirectory {
        saveReport(report, serviceType: serviceType, directory: outputDirectory)
      }
    }

    // Log benchmark completion
    await logger?.info(
      "Completed cryptographic service benchmarks",
      context: createLogContext(operation: "runBenchmarks")
    )

    return results
  }

  /// Creates a cryptographic service of the specified type.
  ///
  /// - Parameter type: The type of service to create
  /// - Returns: A configured cryptographic service, or nil if creation failed
  private func createService(type: ServiceType) async -> CryptoServiceProtocol? {
    // Create a mock secure storage for testing
    let secureStorage=createMockSecureStorage()

    // Map ServiceType to SecurityProviderType
    let providerType: SecurityProviderType
    switch type {
      case .standard:
        providerType = .basic
      case .appleCryptoKit:
        providerType = .appleCryptoKit
      case .ring:
        providerType = .ring
      case .all:
        // This should never happen due to earlier filtering
        return nil
    }

    // Create service using the CryptoServiceRegistry
    return await CryptoServiceRegistry.createService(
      type: providerType,
      secureStorage: secureStorage,
      logger: logger,
      environment: createTestEnvironment()
    )
  }

  /// Creates a mock secure storage implementation for testing.
  ///
  /// - Returns: A mock secure storage implementation
  private func createMockSecureStorage() -> SecureStorageProtocol {
    // Use the MockSecureStorage from the standard testing utilities
    MockSecureStorage(
      behaviour: MockSecureStorage.MockBehaviour(
        shouldSucceed: true,
        logOperations: false
      )
    )
  }

  /// Creates a test environment configuration.
  ///
  /// - Returns: A crypto environment configured for benchmarking
  private func createTestEnvironment() -> CryptoServicesCore.CryptoEnvironment {
    CryptoServicesCore.CryptoEnvironment(
      type: .test,
      hasHardwareSecurity: true,
      isLoggingEnhanced: false,
      platformIdentifier: "benchmark",
      parameters: [
        "benchmark": "true",
        "optimisationLevel": "high"
      ]
    )
  }

  /// Saves a benchmark report to a file.
  ///
  /// - Parameters:
  ///   - report: The benchmark report to save
  ///   - serviceType: The service type that was benchmarked
  ///   - directory: Directory where the file should be saved
  private func saveReport(
    _ report: BenchmarkReport,
    serviceType: ServiceType,
    directory: String
  ) {
    guard let jsonData=report.asJSON() else {
      print("Failed to serialise benchmark report for \(serviceType.rawValue)")
      return
    }

    let dateFormatter=DateFormatter()
    dateFormatter.dateFormat="yyyyMMdd-HHmmss"
    let timestamp=dateFormatter.string(from: Date())

    let filename="crypto_benchmark_\(serviceType.rawValue.lowercased().replacingOccurrences(of: " ", with: "_"))_\(timestamp).json"
    let fileURL=URL(fileURLWithPath: directory).appendingPathComponent(filename)

    do {
      try jsonData.write(to: fileURL, atomically: true, encoding: .utf8)
      print("Benchmark results saved to: \(fileURL.path)")
    } catch {
      print("Failed to save benchmark results: \(error.localizedDescription)")
    }
  }

  /// Creates a log context for benchmark operations.
  ///
  /// - Parameter operation: The name of the benchmark operation
  /// - Returns: A configured log context
  private func createLogContext(operation: String) -> LogContextDTO {
    BaseLogContextDTO(
      domainName: "BenchmarkRunner",
      operation: operation,
      category: "Performance",
      source: "BenchmarkRunner",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "iterations", value: String(configuration.iterations))
        .withPublic(
          key: "serviceTypes",
          value: configuration.serviceTypes.map(\.rawValue).joined(separator: ", ")
        )
    )
  }
}
