/**
 # CoreDTOs Module

 This module provides data transfer objects used throughout the UmbraCore system.
 It serves as an umbrella module that encapsulates data structures for passing
 information between different components of the system.

 All types in this module are fully qualified, in line with the UmbraCore type policy
 which emphasises clarity over indirection.
 */

// CoreDTOs module
// This module contains all the data transfer objects used across the UmbraCore system

// Export Foundation types that are needed for CoreDTOs
@_exported import Foundation

// Explicitly export the types we need from Foundation
// to avoid having to import Foundation in files that use CoreDTOs
@_exported import struct Foundation.Data
@_exported import struct Foundation.Date
@_exported import struct Foundation.URL
@_exported import struct Foundation.Locale
@_exported import struct Foundation.TimeZone
@_exported import struct Foundation.Calendar
@_exported import struct Foundation.DateComponents
@_exported import struct Foundation.IndexPath

// Re-export modules needed for CoreDTOs functionality
// These will be uncommented during migration completion
@_exported import FileSystemTypes
@_exported import SecurityTypes
@_exported import Notification
@_exported import Scheduling
@_exported import UmbraErrors
@_exported import UserDefaults
@_exported import SecurityInterfaces
