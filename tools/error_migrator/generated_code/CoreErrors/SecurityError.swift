
import UmbraErrors
import UmbraErrorsCore
import Foundation

/// SecurityError error type
public enum SecurityError: Error {
  case bookmarkError
  case accessError
  case cryptoError
  case bookmarkCreationFailed
  case bookmarkResolutionFailed
}
