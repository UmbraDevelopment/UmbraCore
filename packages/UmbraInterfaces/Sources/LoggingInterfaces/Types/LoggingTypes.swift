import Foundation

// Re-export LoggingTypes module to ensure all consumers of LoggingInterfaces
// have access to the core types without having to import LoggingTypes directly
@_exported import LoggingTypes

// No need to define LogLevel here as it's now imported from LoggingTypes
