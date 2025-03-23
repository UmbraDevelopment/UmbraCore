/// Extension namespace for CoreTypesInterfaces module
/// Provides a centralized place for extension methods and properties
public enum CoreTypesExtensions {
  /// Version of the CoreTypesInterfaces module
  public static let version="1.0.0"

  /// Used to register module initialisation requirements
  public static func registerModule() {
    // This is a hook for future initialisation requirements
    // Currently empty as no initialisation is needed
  }
}

/// Shorthand namespace for CoreTypesInterfaces extensions
public typealias CT=CoreTypesExtensions
