/// Errors that can occur when working with ResourceLocator
@frozen
public enum ResourceLocatorError: Error, Sendable, Equatable, Hashable {
  /// The path provided is invalid or empty
  case invalidPath

  /// The resource could not be found at the specified location
  case resourceNotFound

  /// Access to the resource was denied
  case accessDenied

  /// The specified scheme is not supported
  case unsupportedScheme

  /// A general error occurred while processing the resource
  case generalError(String)

  // MARK: - Error Description

  /// Get a human-readable description of the error
  public var errorDescription: String {
    switch self {
      case .invalidPath:
        "The resource path is invalid or empty"
      case .resourceNotFound:
        "The specified resource could not be found"
      case .accessDenied:
        "Access to the specified resource was denied"
      case .unsupportedScheme:
        "The specified resource scheme is not supported"
      case let .generalError(message):
        "Resource locator error: \(message)"
    }
  }

  // MARK: - NSError Conversion

  /// The error domain for ResourceLocatorError
  public static let errorDomain="com.umbra.umbracore.resourcelocator"

  /// Get the error code for this error
  public var errorCode: Int {
    switch self {
      case .invalidPath:
        1001
      case .resourceNotFound:
        1002
      case .accessDenied:
        1003
      case .unsupportedScheme:
        1004
      case .generalError:
        1099
    }
  }

  /// Get the user info dictionary for this error when converted to NSError
  public var userInfo: [String: Any] {
    var info: [String: Any]=[
      "NSLocalizedDescription": errorDescription
    ]

    if case let .generalError(message)=self {
      info["ErrorMessage"]=message
    }

    return info
  }
}
