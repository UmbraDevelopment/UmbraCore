// ErrorLogContext.swift
// Part of the Alpha Dot Five architecture for UmbraCore
//
// Copyright 2025 MPY. All rights reserved.

import Foundation

/// A specialised log context for error-related operations
///
/// This structure provides contextual information specific to error handling
/// with enhanced privacy controls for sensitive error information.
public struct ErrorLogContext: LogContextDTO, Sendable {
    /// The name of the domain this context belongs to
    public let domainName: String
    
    /// Correlation identifier for tracing related logs
    public let correlationId: String?
    
    /// Source information for the log (e.g., file, function, line)
    public let source: String?
    
    /// Privacy-aware metadata for this log context
    public let metadata: LogMetadataDTOCollection
    
    /// The error that occurred
    public let error: Error
    
    /// Creates a new error log context
    ///
    /// - Parameters:
    ///   - error: The error that occurred
    ///   - domain: The domain for this error context
    ///   - correlationId: Optional correlation identifier for tracing related logs
    ///   - source: Optional source information (e.g., file, function, line)
    ///   - additionalContext: Optional additional context with privacy annotations
    public init(
        error: Error,
        domain: String = "ErrorHandling",
        correlationId: String? = nil,
        source: String? = nil,
        additionalContext: LogMetadataDTOCollection = LogMetadataDTOCollection()
    ) {
        self.error = error
        self.domainName = domain
        self.correlationId = correlationId
        self.source = source
        
        // Start with the additional context
        var contextMetadata = additionalContext
        
        // Add error information as metadata - we don't need to check for existence
        // since we're explicitly building the metadata here
        contextMetadata = contextMetadata
            .withPublic(key: "errorType", value: String(describing: type(of: error)))
            .withPrivate(key: "errorMessage", value: error.localizedDescription)
        
        // Add domain information for NSErrors
        if let domainError = error as? CustomNSError {
            contextMetadata = contextMetadata
                .withPrivate(key: "errorDomain", value: String(describing: type(of: domainError).errorDomain))
                .withPrivate(key: "errorCode", value: "\(domainError.errorCode)")
        }
        
        self.metadata = contextMetadata
    }
    
    /// Creates a new instance of this context with updated metadata
    ///
    /// - Parameter metadata: The metadata to add to the context
    /// - Returns: A new log context with the updated metadata
    public func withUpdatedMetadata(_ metadata: LogMetadataDTOCollection) -> ErrorLogContext {
        ErrorLogContext(
            error: self.error,
            domain: self.domainName,
            correlationId: self.correlationId,
            source: self.source,
            additionalContext: self.metadata.merging(with: metadata)
        )
    }
    
    /// Creates a new instance of this context with a correlation ID
    ///
    /// - Parameter correlationId: The correlation ID to add
    /// - Returns: A new log context with the specified correlation ID
    public func withCorrelationId(_ correlationId: String) -> ErrorLogContext {
        ErrorLogContext(
            error: self.error,
            domain: self.domainName,
            correlationId: correlationId,
            source: self.source,
            additionalContext: self.metadata
        )
    }
    
    /// Creates a new instance of this context with source information
    ///
    /// - Parameter source: The source information to add
    /// - Returns: A new log context with the specified source
    public func withSource(_ source: String) -> ErrorLogContext {
        ErrorLogContext(
            error: self.error,
            domain: self.domainName,
            correlationId: self.correlationId,
            source: source,
            additionalContext: self.metadata
        )
    }
}
