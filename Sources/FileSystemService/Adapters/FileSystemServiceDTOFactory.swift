import CoreDTOs
import FileSystemTypes
import Foundation

/// Factory for creating FileSystemServiceDTOAdapter instances
public enum FileSystemServiceDTOFactory {
  /// Create a default FileSystemServiceDTOAdapter
  /// - Returns: A configured FileSystemServiceDTOAdapter
  public static func createDefault() -> FileSystemServiceDTOAdapter {
    FileSystemServiceDTOAdapter()
  }

  /// Create a FileSystemServiceDTOAdapter with a specific FileManager
  /// - Parameter fileManager: FileManager to use
  /// - Returns: A configured FileSystemServiceDTOAdapter
  public static func create(with fileManager: FileManager) -> FileSystemServiceDTOAdapter {
    FileSystemServiceDTOAdapter(fileManager: fileManager)
  }
}
