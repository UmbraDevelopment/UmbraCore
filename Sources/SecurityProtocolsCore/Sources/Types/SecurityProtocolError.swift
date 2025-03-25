import UmbraCoreTypes
import UmbraErrors
import Errors

/// Re-export of the canonical SecurityProtocolError from the Errors module
/// This ensures backward compatibility with existing code that imports SecurityProtocolsCore
public typealias SecurityProtocolError = Errors.SecurityProtocolError
