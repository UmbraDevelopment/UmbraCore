import Foundation
import LoggingTypes

/// Protocol for logging providers that handle the actual writing of log entries
public protocol LoggingProviderProtocol: Sendable {
  /// Write a log entry to a destination
  /// - Parameters:
  ///   - entry: The log entry to write
  ///   - destination: The destination to write to
  /// - Returns: Whether the write was successful
  /// - Throws: Any errors encountered during the write
  func writeLogEntry(_ entry: LogEntryDTO, to destination: LogDestinationDTO) async throws -> Bool

  /// Write a log entry to a destination
  /// - Parameters:
  ///   - entry: The log entry to write
  ///   - destination: The destination to write to
  /// - Returns: Whether the write was successful
  /// - Throws: Any errors encountered during the write
  func writeLog(_ entry: LogEntryDTO, to destination: LogDestinationDTO) async throws -> Bool

  /// Flush any pending log entries for a destination
  /// - Parameter destination: The destination to flush logs for
  /// - Returns: Whether the flush was successful
  /// - Throws: Any errors encountered during the flush operation
  func flushLogs(for destination: LogDestinationDTO) async throws -> Bool

  /// Validate a destination configuration
  /// - Parameter destination: The destination configuration to validate
  /// - Returns: The validation result
  func validateDestination(_ destination: LogDestinationDTO) async
    -> LogDestinationValidationResultDTO
}

/// Default implementation extension
extension LoggingProviderProtocol {
  /// Create a default implementation that does nothing except log to console
  public static func createDefault() -> LoggingProviderProtocol {
    DefaultLoggingProvider()
  }

  /// Default implementation for validate destination that just returns success
  public func validateDestination(_: LogDestinationDTO) async -> LogDestinationValidationResultDTO {
    LogDestinationValidationResultDTO(isValid: true)
  }

  /// Default implementation of writeLogEntry that maps to writeLog
  public func writeLogEntry(
    _ entry: LogEntryDTO,
    to destination: LogDestinationDTO
  ) async throws -> Bool {
    try await writeLog(entry, to: destination)
  }

  /// Default implementation of writeLog that maps to writeLogEntry
  public func writeLog(
    _ entry: LogEntryDTO,
    to destination: LogDestinationDTO
  ) async throws -> Bool {
    try await writeLogEntry(entry, to: destination)
  }
}

/// A simple default implementation that just prints to console
private final class DefaultLoggingProvider: LoggingProviderProtocol {
  func writeLogEntry(_ entry: LogEntryDTO, to _: LogDestinationDTO) async throws -> Bool {
    print("[\(entry.level)] \(entry.message)")
    return true
  }

  func writeLog(_ entry: LogEntryDTO, to destination: LogDestinationDTO) async throws -> Bool {
    try await writeLogEntry(entry, to: destination)
  }

  func flushLogs(for _: LogDestinationDTO) async throws -> Bool {
    // No buffering in the default implementation, so just return success
    true
  }

  func validateDestination(_: LogDestinationDTO) async -> LogDestinationValidationResultDTO {
    LogDestinationValidationResultDTO(isValid: true)
  }
}
