// Export Foundation types that are needed for FileSystemTypes
@_exported import Foundation

// Explicitly export the types we need from Foundation
// to avoid having to import Foundation in files that use FileSystemTypes
@_exported import struct Foundation.Data
@_exported import struct Foundation.Date
@_exported import struct Foundation.URL

/**
 # File System Types Note
 
 The canonical versions of the following types have been moved to the FileSystemInterfaces module:
 - FileWriteOptions
 - FileMoveOptions
 - FileCopyOptions
 - TemporaryFileOptions
 - FileSystemError
 
 Please import FileSystemInterfaces to use these types directly.
 */

// Export all Swift files in this module
