import Foundation

// This file serves as the main entry point for the CoreTypesInterfaces module
// The actual type implementations have been moved to dedicated files

/// Module initialisation function
/// Call this to ensure all components are properly registered
public func initialiseModule() {
  // Module registration is now handled by the specific module extension
  CoreTypesInterfacesExtensions.registerModule()
}
