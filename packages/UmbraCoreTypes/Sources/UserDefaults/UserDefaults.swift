/**
 # UserDefaults Module

 This module provides data transfer objects and utilities for working with user preferences.
 It's designed to be platform-independent and easy to use across different UmbraCore services.

 ## Overview
 The UserDefaults module includes:
 - UserDefaultsValueDTO: A cross-platform representation of preference values
 - Type-safe utilities for working with preference data
 - Foundation-independent data structures
 
 ## Usage
 Import this module to work with user preference data in a type-safe, platform-independent way.
 */

import Foundation

// Export Foundation types needed for UserDefaults
@_exported import Foundation

// Explicitly export key types from Foundation
@_exported import struct Foundation.Data
@_exported import struct Foundation.Date
@_exported import struct Foundation.URL

// Export UmbraErrors for error handling
@_exported import UmbraErrors
