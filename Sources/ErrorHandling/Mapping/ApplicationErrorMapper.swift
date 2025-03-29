import Foundation
import MappingCommon

// MARK: - Application Error Mapper Implementation

/// Maps application errors from different sources to a consolidated ApplicationError
public class ApplicationErrorMapper: ErrorMapper {
  /// The domain this mapper handles
  public let domain="Application"

  /// Create a new application error mapper
  public init() {}

  /// Maps from the source error type to the target error type
  /// - Parameter error: The source error
  /// - Returns: The mapped target error
  public func mapError(_ error: UmbraErrors.Application.Core) -> ApplicationError {
    mapFromTyped(error)
  }

  /// Attempt to map any error to an ApplicationError
  /// - Parameter error: Any error
  /// - Returns: An ApplicationError or nil if the error is not mappable
  public func mapFromAny(_ error: Error) -> ApplicationError? {
    // Get the error type name as a string
    let errorType=String(describing: type(of: error))

    // Core application errors
    if errorType.contains("UmbraErrors.Application.Core") {
      if let typedError=error as? UmbraErrors.Application.Core {
        return mapFromTyped(typedError)
      }
      return .unknown(reason: "Unable to cast to UmbraErrors.Application.Core")
    }
    // UI errors
    else if errorType.contains("UmbraErrors.Application.UI") {
      if let typedError=error as? UmbraErrors.Application.UI {
        return mapFromUI(typedError)
      }
      return .unknown(reason: "Unable to cast to UmbraErrors.Application.UI")
    }
    // Lifecycle errors
    else if errorType.contains("UmbraErrors.Application.Lifecycle") {
      if let typedError=error as? UmbraErrors.Application.Lifecycle {
        return mapFromLifecycle(typedError)
      }
      return .unknown(reason: "Unable to cast to UmbraErrors.Application.Lifecycle")
    } else {
      // Only map if it seems like an application error
      let errorDescription=String(describing: error).lowercased()
      if errorDescription.contains("init") || errorDescription.contains("application") {
        return .unknown(reason: "Unmapped application error: \(errorDescription)")
      }
    }

    return nil
  }

  /// Maps from UmbraErrors.Application.Core to our consolidated ApplicationError
  /// - Parameter error: The source UmbraErrors.Application.Core error
  /// - Returns: The mapped ApplicationError
  public func mapFromTyped(_ error: UmbraErrors.Application.Core) -> ApplicationError {
    // Simplify the mapping to avoid issues with mismatched enum cases
    let errorDescription=String(describing: error)

    // Basic mapping based on the error description
    if errorDescription.contains("configurationError") {
      return .configurationError(reason: "Configuration error: \(errorDescription)")
    } else if errorDescription.contains("resourceNotFound") {
      return .resourceNotFound(reason: "Resource not found: \(errorDescription)")
    } else if errorDescription.contains("resourceAlreadyExists") {
      return .resourceAlreadyExists(reason: "Resource already exists: \(errorDescription)")
    } else if errorDescription.contains("operationTimeout") {
      return .operationTimeout(reason: "Operation timed out: \(errorDescription)")
    } else if errorDescription.contains("operationCancelled") {
      return .operationCancelled(reason: "Operation cancelled: \(errorDescription)")
    } else {
      // Default fallback
      return .unknown(reason: "Application error: \(errorDescription)")
    }
  }

  /// Maps from UmbraErrors.Application.UI to ApplicationError for UI-specific issues
  /// - Parameter error: The source UmbraErrors.Application.UI error
  /// - Returns: The mapped ApplicationError
  private func mapFromUI(_ error: UmbraErrors.Application.UI) -> ApplicationError {
    // Use string descriptions to avoid pattern matching problems
    let errorDescription=String(describing: error)

    if errorDescription.contains("viewNotFound") {
      return .viewError(reason: "View not found error: \(errorDescription)")
    } else if errorDescription.contains("renderingError") {
      return .renderingError(reason: "Rendering error: \(errorDescription)")
    } else if errorDescription.contains("animationError") {
      return .renderingError(reason: "Animation error: \(errorDescription)")
    } else {
      // Default fallback for other UI errors
      return .viewError(reason: "UI error: \(errorDescription)")
    }
  }

  /// Maps from UmbraErrors.Application.Lifecycle to ApplicationError
  /// - Parameter error: The source UmbraErrors.Application.Lifecycle error
  /// - Returns: The mapped ApplicationError
  private func mapFromLifecycle(_ error: UmbraErrors.Application.Lifecycle) -> ApplicationError {
    // Use string description to avoid pattern matching problems with enum cases
    let errorDescription=String(describing: error)

    if errorDescription.contains("launchError") {
      return .lifecycleError(reason: "Launch error: \(errorDescription)")
    } else if errorDescription.contains("backgroundTransition") {
      return .lifecycleError(reason: "Background transition error: \(errorDescription)")
    } else if errorDescription.contains("foregroundTransition") {
      return .lifecycleError(reason: "Foreground transition error: \(errorDescription)")
    } else if errorDescription.contains("termination") {
      return .lifecycleError(reason: "Termination error: \(errorDescription)")
    } else if errorDescription.contains("stateRestoration") {
      return .stateError(reason: "State restoration error: \(errorDescription)")
    } else if errorDescription.contains("statePreservation") {
      return .stateError(reason: "State preservation error: \(errorDescription)")
    } else if errorDescription.contains("memoryWarning") {
      return .lifecycleError(reason: "Memory warning error: \(errorDescription)")
    } else {
      return .lifecycleError(reason: "Lifecycle error: \(errorDescription)")
    }
  }

  /// Maps from UmbraErrors.Application.Core to our consolidated ApplicationError for
  /// settings-related issues
  /// - Parameter error: The source UmbraErrors.Application.Core error
  /// - Returns: The mapped ApplicationError
  private func mapFromSettings(_ error: UmbraErrors.Application.Core) -> ApplicationError {
    // Use string descriptions to categorize settings-related errors
    let errorDescription=String(describing: error)

    if errorDescription.contains("configurationMissing") {
      return .settingsError(reason: "Settings not found: \(errorDescription)")
    } else if errorDescription.contains("configurationInvalid") {
      return .settingsError(reason: "Invalid settings: \(errorDescription)")
    } else if errorDescription.contains("persistenceFailed") {
      return .settingsError(reason: "Settings persistence error: \(errorDescription)")
    } else {
      return .unknown(reason: "Unhandled settings error: \(errorDescription)")
    }
  }
}
