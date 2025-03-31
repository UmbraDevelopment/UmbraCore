import DateTimeInterfaces
import Foundation

/// Factory for creating DateTimeDTOAdapter instances
///
/// This factory provides the standard way to create DateTimeDTOAdapter instances,
/// ensuring consistent configuration across the application.
public enum DateTimeDTOFactory {
  /// Create a default DateTimeDTOAdapter
  /// - Returns: A configured DateTimeDTOAdapter
  public static func createDefault() -> DateTimeDTOAdapter {
    DateTimeDTOAdapter()
  }
}
