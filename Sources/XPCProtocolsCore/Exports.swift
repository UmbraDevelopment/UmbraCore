@_exported import struct Foundation.Data
@_exported import class Foundation.JSONDecoder
@_exported import class Foundation.JSONEncoder
@_exported import struct Foundation.URL
@_exported import struct Foundation.URLComponents
@_exported import struct Foundation.URLQueryItem

// Export UmbraErrors for error handling
@_exported import UmbraErrors
@_exported import UmbraErrorsCore

// Export Modern module components directly
// The Modern components are now part of the main XPCProtocolsCore module
// and don't need to be imported through a submodule path

// Sources are now included directly in the main module
// rather than through a submodule import
