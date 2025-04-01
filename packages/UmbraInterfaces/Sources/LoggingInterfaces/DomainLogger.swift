// DomainLogger.swift
// Part of the Alpha Dot Five architecture for UmbraCore
//
// Copyright © 2025 MPY. All rights reserved.

import LoggingTypes

/// Protocol defining the requirements for domain-specific loggers
///
/// Domain loggers provide specialised logging functionality for specific
/// domains within the application, with enhanced privacy controls and
/// contextual information.
public protocol DomainLogger: PrivacyAwareLoggingProtocol {
    /// The domain name this logger is responsible for
    var domainName: String { get }
    
    /// Log a domain-specific event with context
    /// 
    /// - Parameters:
    ///   - level: The severity level of the log
    ///   - message: The message to log
    ///   - context: Domain-specific context for the log
    func logWithContext(
        _ level: LogLevel,
        _ message: String,
        context: LogContextDTO
    ) async
    
    /// Log a domain-specific event with privacy-annotated message and context
    /// 
    /// - Parameters:
    ///   - level: The severity level of the log
    ///   - message: The privacy-annotated message to log
    ///   - context: Domain-specific context for the log
    func logWithContext(
        _ level: LogLevel,
        _ message: PrivacyAnnotatedString,
        context: LogContextDTO
    ) async
    
    /// Log an error with domain-specific context
    /// 
    /// - Parameters:
    ///   - error: The error to log
    ///   - context: Domain-specific context for the log
    ///   - privacyLevel: The privacy level to apply to the error details
    func logError(
        _ error: Error,
        context: LogContextDTO,
        privacyLevel: PrivacyClassification
    ) async
}

/// Default implementations for DomainLogger to reduce boilerplate
extension DomainLogger {
    /// Log a domain-specific event with info level
    /// 
    /// - Parameters:
    ///   - message: The message to log
    ///   - context: Domain-specific context for the log
    public func info(_ message: String, context: LogContextDTO) async {
        await logWithContext(.info, message, context: context)
    }
    
    /// Log a domain-specific event with debug level
    /// 
    /// - Parameters:
    ///   - message: The message to log
    ///   - context: Domain-specific context for the log
    public func debug(_ message: String, context: LogContextDTO) async {
        await logWithContext(.debug, message, context: context)
    }
    
    /// Log a domain-specific event with warning level
    /// 
    /// - Parameters:
    ///   - message: The message to log
    ///   - context: Domain-specific context for the log
    public func warning(_ message: String, context: LogContextDTO) async {
        await logWithContext(.warning, message, context: context)
    }
    
    /// Log a domain-specific event with error level
    /// 
    /// - Parameters:
    ///   - message: The message to log
    ///   - context: Domain-specific context for the log
    public func error(_ message: String, context: LogContextDTO) async {
        await logWithContext(.error, message, context: context)
    }
    
    /// Log an error with domain-specific context and default privacy level
    /// 
    /// - Parameters:
    ///   - error: The error to log
    ///   - context: Domain-specific context for the log
    public func logError(_ error: Error, context: LogContextDTO) async {
        await logError(error, context: context, privacyLevel: .private)
    }
}
