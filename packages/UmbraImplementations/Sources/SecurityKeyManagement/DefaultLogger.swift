import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Basic logger implementation for when no logger is provided.
 This is used as a fallback to ensure logging is always available.
 */
internal struct DefaultLogger: LoggingProtocol {
    public init() {}
    
    public func debug(_ message: String, metadata: LoggingTypes.LogMetadata?) async {}
    public func info(_ message: String, metadata: LoggingTypes.LogMetadata?) async {}
    public func warning(_ message: String, metadata: LoggingTypes.LogMetadata?) async {}
    public func error(_ message: String, metadata: LoggingTypes.LogMetadata?) async {}
}
