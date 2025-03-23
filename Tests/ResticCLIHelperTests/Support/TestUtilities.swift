import Foundation
import XCTest

/// Utilities for creating test data and managing test files
enum TestUtilities {
  /// Creates a sample directory structure with various file types and sizes
  /// - Parameters:
  ///   - baseDirectory: Base directory to create the structure in
  ///   - fileCount: Number of files to create (default: 10)
  ///   - fileContent: Content to write to text files (default: nil, uses default content)
  /// - Returns: Array of created file paths
  static func createSampleDirectoryStructure(
    in baseDirectory: String,
    fileCount: Int=10,
    fileContent: String?=nil
  ) throws -> [String] {
    let fileManager=FileManager.default
    var createdFiles: [String]=[]

    // Create nested directory structure
    let directories=[
      "docs",
      "docs/reports",
      "docs/presentations",
      "media",
      "media/images",
      "media/videos",
      "config",
      "data"
    ]

    // Create directories
    try directories.forEach { directory in
      let path=(baseDirectory as NSString).appendingPathComponent(directory)
      try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
    }

    // Create sample text files
    let textContent=fileContent ?? [
      "This is a sample text file for testing ",
      "Restic backup and restore functionality.\n"
    ].joined()
    try directories.forEach { directory in
      let path=(baseDirectory as NSString).appendingPathComponent(directory)
      let filePath=(path as NSString).appendingPathComponent("sample.txt")
      try textContent.write(toFile: filePath, atomically: true, encoding: .utf8)
      createdFiles.append(filePath)
    }

    // Create binary files of different sizes
    let sizes=[1024, 2048, 4096, 8192] // Different file sizes in bytes
    try sizes.forEach { size in
      let data=generateTestData(size: size)
      let path=(baseDirectory as NSString).appendingPathComponent("data")
      let filePath=(path as NSString).appendingPathComponent("binary_\(size).dat")
      try data.write(to: URL(fileURLWithPath: filePath))
      createdFiles.append(filePath)
    }

    // Create additional random text files
    for fileIndex in 0..<fileCount {
      let randomDirectory=directories.randomElement()!
      let path=(baseDirectory as NSString).appendingPathComponent(randomDirectory)
      let filePath=(path as NSString).appendingPathComponent("file_\(fileIndex).txt")
      try textContent.write(toFile: filePath, atomically: true, encoding: .utf8)
      createdFiles.append(filePath)
    }

    return createdFiles
  }

  /// Generate test data with specified size
  /// - Parameter size: Size in bytes
  /// - Returns: Data with random content
  static func generateTestData(size: Int) -> Data {
    var data=Data(count: size)
    for byteIndex in 0..<size {
      data[byteIndex]=UInt8.random(in: 0...255)
    }
    return data
  }

  /// Verifies that two directories have identical content
  /// - Parameters:
  ///   - source: Source directory path
  ///   - destination: Destination directory path
  ///   - ignoreModificationTimes: Whether to ignore file modification times (default: true)
  /// - Returns: true if directories are identical, false otherwise
  static func verifyDirectoryContent(
    source: String,
    destination: String,
    ignoreModificationTimes _: Bool=true
  ) throws -> Bool {
    let fileManager=FileManager.default
    print("Verifying directory content:")
    print("Source: \(source)")
    print("Destination: \(destination)")

    // Get contents of both directories
    let sourceContents=try fileManager.subpathsOfDirectory(atPath: source)
      .filter { !$0.hasPrefix(".") } // Ignore hidden files
      .sorted()
    print("Source contents: \(sourceContents)")

    // Get contents of destination directory
    let destContents=try fileManager.subpathsOfDirectory(atPath: destination)
      .filter { !$0.hasPrefix(".") } // Ignore hidden files
      .sorted()
    print("Destination contents: \(destContents)")

    // Check if file counts match
    if sourceContents.count != destContents.count {
      print("File count mismatch: source=\(sourceContents.count), dest=\(destContents.count)")
      print("Source files: \(sourceContents)")
      print("Dest files: \(destContents)")
      return false
    }

    // Compare each file
    for relativePath in sourceContents {
      let sourcePath=(source as NSString).appendingPathComponent(relativePath)
      let destPath=(destination as NSString).appendingPathComponent(relativePath)

      var isDirectory: ObjCBool=false
      guard fileManager.fileExists(atPath: sourcePath, isDirectory: &isDirectory) else {
        print("Source file missing: \(sourcePath)")
        return false
      }

      // Skip directories, we only compare files
      if isDirectory.boolValue {
        continue
      }

      guard fileManager.fileExists(atPath: destPath, isDirectory: &isDirectory) else {
        print("Destination file missing: \(destPath)")
        return false
      }

      // Compare file contents
      guard
        let sourceData=try? Data(contentsOf: URL(fileURLWithPath: sourcePath)),
        let destData=try? Data(contentsOf: URL(fileURLWithPath: destPath))
      else {
        print("Failed to read file data: \(relativePath)")
        return false
      }

      if sourceData != destData {
        print("File content mismatch: \(relativePath)")
        return false
      }
    }

    return true
  }

  /// Prints the directory structure of a given path
  /// - Parameter path: Path to print structure of
  static func printDirectoryStructure(_ path: String) throws {
    let fileManager=FileManager.default
    let contents=try fileManager.contentsOfDirectory(atPath: path)
    print("\nDirectory structure of \(path):")
    try printDirectoryContents(path, contents: contents, indent: "")
  }

  /// Helper function to print directory contents recursively
  /// - Parameters:
  ///   - path: Base path
  ///   - contents: Contents to print
  ///   - indent: Current indentation level
  private static func printDirectoryContents(
    _ path: String,
    contents: [String],
    indent: String
  ) throws {
    for item in contents.sorted() {
      let itemPath=(path as NSString).appendingPathComponent(item)
      var isDirectory: ObjCBool=false
      guard FileManager.default.fileExists(atPath: itemPath, isDirectory: &isDirectory) else {
        continue
      }

      if isDirectory.boolValue {
        print("\(indent)📁 \(item)/")
        let subContents=try FileManager.default.contentsOfDirectory(atPath: itemPath)
        try printDirectoryContents(itemPath, contents: subContents, indent: indent + "  ")
      } else {
        let attributes=try FileManager.default.attributesOfItem(atPath: itemPath)
        let size=attributes[.size] as? Int64 ?? 0
        print(
          "\(indent)📄 \(item) (\(ByteCountFormatter.string(fromByteCount: size, countStyle: .file)))"
        )
      }
    }
  }

  /// Cleans up a test directory
  /// - Parameter path: Directory path to clean up
  static func cleanupTestDirectory(_ path: String) {
    try? FileManager.default.removeItem(atPath: path)
  }
}
