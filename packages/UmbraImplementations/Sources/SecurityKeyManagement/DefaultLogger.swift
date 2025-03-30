import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Basic logger implementation for when no logger is provided.
 This is used as a fallback to ensure logging is always available.
 */
struct DefaultLogger: LoggingProtocol {
  public init() {}

  public func debug(
    _: String,
    metadata _: LoggingTypes.LogMetadata?=nil,
    source _: String?=nil
  ) async {}
  public func info(
    _: String,
    metadata _: LoggingTypes.LogMetadata?=nil,
    source _: String?=nil
  ) async {}
  public func warning(
    _: String,
    metadata _: LoggingTypes.LogMetadata?=nil,
    source _: String?=nil
  ) async {}
  public func error(
    _: String,
    metadata _: LoggingTypes.LogMetadata?=nil,
    source _: String?=nil
  ) async {}
}
