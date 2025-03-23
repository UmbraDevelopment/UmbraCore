import Foundation

/// Error context protocol
public protocol ErrorContextProvider {
  /// Domain of the error
  var domain: String { get }
  /// Code of the error
  var code: Int { get }
  /// Description of the error
  var description: String { get }
}

/// Error handler protocol
public protocol ErrorHandler {
  /// Handle an error
  /// - Parameter error: The error to handle
  /// - Returns: Whether the error was handled
  func handle(error: Error) -> Bool
}
