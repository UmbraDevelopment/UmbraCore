// UmbraErrors module
// This module provides error types and handling utilities used throughout UmbraCore

// Export Foundation and OSLog types that are needed for UmbraErrors
@_exported import Foundation
@_exported import OSLog

// Explicitly export the types we need from Foundation
@_exported import struct Foundation.Date
@_exported import struct Foundation.UUID

// The UmbraErrors module directly imports all components from Core, DTOs, Domains, and Mapping
// This allows consumers to just import UmbraErrors without needing to know about the submodules
