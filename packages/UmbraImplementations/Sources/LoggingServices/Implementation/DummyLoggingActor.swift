import Foundation
import LoggingInterfaces
import LoggingTypes

/// Implementation of a logging actor for bootstrap purposes
/// Provides a minimal implementation to satisfy protocol requirements
public actor DummyPrivacyAwareLoggingActor: PrivacyAwareLoggingProtocol {
    /// Log a message with the given level
    public func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
        // No-op implementation for bootstrap purposes
    }
    
    /// Log a message with privacy annotations
    public func log(_ level: LogLevel, _ message: PrivacyString, context: LogContextDTO) async {
        // No-op implementation for bootstrap purposes
    }
    
    /// Log sensitive information with appropriate privacy controls
    public func logSensitive(_ level: LogLevel, _ message: String, sensitiveValues: LoggingTypes.LogMetadata, context: LogContextDTO) async {
        // No-op implementation for bootstrap purposes
    }
    
    /// Log an error with privacy controls
    public func logError(_ error: Error, privacyLevel: LogPrivacyLevel, context: LogContextDTO) async {
        // No-op implementation for bootstrap purposes
    }
}
