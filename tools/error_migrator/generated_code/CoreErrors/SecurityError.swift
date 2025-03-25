
import Foundation
import UmbraErrors
import UmbraErrorsCore

/// SecurityError error type
public enum SecurityError: Error {
  case bookmarkError
  case accessError
  case cryptoError
  case bookmarkCreationFailed
  case bookmarkResolutionFailed
}
