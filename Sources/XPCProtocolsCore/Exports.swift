// This file re-exports all public symbols from the Sources subpackage
// to maintain backward compatibility and module structure

@_exported import struct Foundation.Data
@_exported import struct Foundation.URL
@_exported import struct Foundation.URLComponents
@_exported import struct Foundation.URLQueryItem
@_exported import class Foundation.JSONEncoder
@_exported import class Foundation.JSONDecoder

// Export all symbols from the Sources subpackage
@_exported import XPCProtocolsCoreSources
