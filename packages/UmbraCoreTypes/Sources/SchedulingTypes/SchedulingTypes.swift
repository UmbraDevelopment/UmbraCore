import Foundation

/// Main module exports
/// This module contains the core types needed for scheduling functionality
/// without introducing circular dependencies.
@_exported import Foundation

// Specific Foundation exports needed for scheduling
@_exported import struct Foundation.Calendar
@_exported import struct Foundation.Date
@_exported import struct Foundation.DateComponents
@_exported import struct Foundation.TimeZone
@_exported import struct Foundation.UUID
