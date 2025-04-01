// BaseDomainLogger.swift
// Part of the Alpha Dot Five architecture for UmbraCore
//
// Copyright 2025 MPY. All rights reserved.

import Foundation
import LoggingTypes
import LoggingInterfaces

/// Protocol defining domain-specific logging capabilities
public protocol DomainLoggerProtocol: Sendable {
    /// The domain name this logger is responsible for
    var domainName: String { get }
    
    /// Log a message with the specified level
    func log(_ level: LogLevel, _ message: String) async
    
    /// Log a message with trace level
    func trace(_ message: String) async
    
    /// Log a message with debug level
    func debug(_ message: String) async
    
    /// Log a message with info level
    func info(_ message: String) async
    
    /// Log a message with warning level
    func warning(_ message: String) async
    
    /// Log a message with error level
    func error(_ message: String) async
    
    /// Log a message with critical level
    func critical(_ message: String) async
    
    /// Log an error with context
    func logError(_ error: Error, context: LogContextDTO, privacyLevel: PrivacyClassification) async
    
    /// Log a message with the specified context
    func logWithContext(_ level: LogLevel, _ message: String, context: LogContextDTO) async
}

/// Base implementation of the domain logger pattern
///
/// This actor provides a reusable implementation of domain-specific logging
/// that follows the Alpha Dot Five architecture principles with proper
/// thread safety through the actor model.
public actor BaseDomainLogger: DomainLoggerProtocol {
    /// The domain name this logger is responsible for
    public let domainName: String
    
    /// The underlying logging service
    private let loggingService: LoggingServiceProtocol
    
    /// Creates a new domain logger
    ///
    /// - Parameters:
    ///   - domainName: The name of the domain this logger is responsible for
    ///   - loggingService: The underlying logging service to use
    public init(domainName: String, loggingService: LoggingServiceProtocol) {
        self.domainName = domainName
        self.loggingService = loggingService
    }
    
    /// Log a message with the specified level
    public func log(_ level: LogLevel, _ message: String) async {
        let formattedMessage = "[\(domainName)] \(message)"
        
        // Use the appropriate level-specific method
        switch level {
        case .trace:
            await loggingService.verbose(formattedMessage, metadata: nil, source: domainName)
        case .debug:
            await loggingService.debug(formattedMessage, metadata: nil, source: domainName)
        case .info:
            await loggingService.info(formattedMessage, metadata: nil, source: domainName)
        case .warning:
            await loggingService.warning(formattedMessage, metadata: nil, source: domainName)
        case .error:
            await loggingService.error(formattedMessage, metadata: nil, source: domainName)
        case .critical:
            await loggingService.critical(formattedMessage, metadata: nil, source: domainName)
        }
    }
    
    /// Log a message with trace level
    public func trace(_ message: String) async {
        await log(.trace, message)
    }
    
    /// Log a message with debug level
    public func debug(_ message: String) async {
        await log(.debug, message)
    }
    
    /// Log a message with info level
    public func info(_ message: String) async {
        await log(.info, message)
    }
    
    /// Log a message with warning level
    public func warning(_ message: String) async {
        await log(.warning, message)
    }
    
    /// Log a message with error level
    public func error(_ message: String) async {
        await log(.error, message)
    }
    
    /// Log a message with critical level
    public func critical(_ message: String) async {
        await log(.critical, message)
    }
    
    /// Log an error with context
    public func logError(_ error: Error, context: LogContextDTO, privacyLevel: PrivacyClassification) async {
        if let loggableError = error as? LoggableErrorProtocol {
            // Use the error's built-in privacy metadata
            let errorMetadata = loggableError.getPrivacyMetadata().toLogMetadata()
            let formattedMessage = "[\(domainName)] \(loggableError.getLogMessage())"
            let source = "\(loggableError.getSource()) via \(domainName)"
            
            await loggingService.error(formattedMessage, metadata: errorMetadata, source: source)
        } else {
            // Handle standard errors with the provided privacy level
            let formattedMessage = "[\(domainName)] \(error.localizedDescription)"
            let metadata = context.asLogMetadata()
            
            await loggingService.error(formattedMessage, metadata: metadata, source: domainName)
        }
    }
    
    /// Log a message with the specified context
    public func logWithContext(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
        let formattedMessage = "[\(domainName)] \(message)"
        let metadata = context.asLogMetadata()
        
        // Choose the appropriate logging method based on level
        switch level {
        case .trace:
            await loggingService.verbose(formattedMessage, metadata: metadata, source: domainName)
        case .debug:
            await loggingService.debug(formattedMessage, metadata: metadata, source: domainName)
        case .info:
            await loggingService.info(formattedMessage, metadata: metadata, source: domainName)
        case .warning:
            await loggingService.warning(formattedMessage, metadata: metadata, source: domainName)
        case .error:
            await loggingService.error(formattedMessage, metadata: metadata, source: domainName)
        case .critical:
            await loggingService.critical(formattedMessage, metadata: metadata, source: domainName)
        }
    }
}
