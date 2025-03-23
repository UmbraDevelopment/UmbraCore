import Foundation
import ResticCLIHelperTypes
import ResticTypes

/// Protocol for process execution that can be mocked in tests
public protocol ProcessExecutorProtocol {
  /// Execute a command with the given arguments and environment
  /// - Parameters:
  ///   - executablePath: Path to the executable
  ///   - arguments: Command line arguments
  ///   - environment: Environment variables
  /// - Returns: The output of the command
  /// - Throws: Error if execution fails
  func execute(
    executablePath: String,
    arguments: [String],
    environment: [String: String]
  ) throws -> String
}

/// Default implementation of process executor that uses real Process class
public class DefaultProcessExecutor: ProcessExecutorProtocol {
  public init() {}

  public func execute(
    executablePath: String,
    arguments: [String],
    environment: [String: String]
  ) throws -> String {
    let process=Process()
    process.executableURL=URL(fileURLWithPath: executablePath)
    process.arguments=arguments
    process.environment=environment

    let outputPipe=Pipe()
    let errorPipe=Pipe()
    process.standardOutput=outputPipe
    process.standardError=errorPipe

    try process.run()
    process.waitUntilExit()

    let outputData=try outputPipe.fileHandleForReading.readToEnd() ?? Data()
    let errorData=try errorPipe.fileHandleForReading.readToEnd() ?? Data()

    let output=String(data: outputData, encoding: .utf8) ?? ""
    let stderr=String(data: errorData, encoding: .utf8) ?? ""

    if process.terminationStatus != 0 {
      if !stderr.isEmpty {
        throw ResticTypes.ResticError.executionFailed(stderr)
      }
      throw ResticTypes.ResticError
        .executionFailed("Unknown error occurred while executing command")
    }

    return output
  }
}

/// Mock implementation of process executor for testing
public class MockProcessExecutor: ProcessExecutorProtocol {
  public var executionResults: [String: Result<String, Error>]=[:]
  public var executionHistory: [(
    executablePath: String,
    arguments: [String],
    environment: [String: String]
  )]=[]
  public var bypassFileValidation: Bool=true

  public init() {}

  /// Configure the mock to return predefined results for specific commands
  /// - Parameters:
  ///   - commandKey: A key to identify the command (e.g. "backup", "restore")
  ///   - result: The result to return (either success with output or failure with error)
  public func configureResult(for commandKey: String, result: Result<String, Error>) {
    executionResults[commandKey]=result
  }

  /// Clear all configured results and execution history
  public func reset() {
    executionResults=[:]
    executionHistory=[]
  }

  /// Execute a command, returning a pre-configured result or a default success
  /// - Parameters:
  ///   - executablePath: Path to the executable
  ///   - arguments: Command line arguments
  ///   - environment: Environment variables
  /// - Returns: The configured output or an empty string
  /// - Throws: The configured error if failure was configured
  public func execute(
    executablePath: String,
    arguments: [String],
    environment: [String: String]
  ) throws -> String {
    // Record this execution
    executionHistory.append((executablePath, arguments, environment))

    // Determine the command key
    let commandKey=arguments.first { $0 != "restic" } ?? "unknown"

    // Return the configured result or a default success
    if let result=executionResults[commandKey] {
      switch result {
        case let .success(output):
          return output
        case let .failure(error):
          throw error
      }
    }

    // Default to success with empty output if no specific configuration exists
    return ""
  }
}
