import CoreDTOs
import Foundation

/// Factory for creating DateTimeDTOAdapter instances
public enum DateTimeDTOFactory {
  /// Create a default DateTimeDTOAdapter
  /// - Returns: A configured DateTimeDTOAdapter
  public static func createDefault() -> DateTimeDTOAdapter {
    DateTimeDTOAdapter()
  }
}
