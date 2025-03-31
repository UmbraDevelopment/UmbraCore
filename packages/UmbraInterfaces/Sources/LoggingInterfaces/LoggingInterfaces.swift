/// LoggingInterfaces Module
///
/// Provides protocol definitions for the logging system, following the Alpha Dot Five
/// architecture principle of separation between types, interfaces, and implementations.
///
/// This module contains:
/// - LoggingProtocol: Core logging interface with essential logging methods
/// - LoggingServiceProtocol: Enhanced logging service with comprehensive features
/// - LogFormatterProtocol: Interface for formatting log entries
/// - LoggingError: Domain-specific error types for logging operations
///
/// Following Alpha Dot Five principles, this module:
/// - Contains only interface definitions
/// - Depends only on core types
/// - Avoids implementation details
/// - Defines behaviours through protocols
/// - Uses proper British spelling in documentation
/// - Avoids unnecessary type aliases

@_exported import LoggingTypes
