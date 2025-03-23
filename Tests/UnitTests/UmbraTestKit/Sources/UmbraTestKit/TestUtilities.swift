import Foundation

public enum TestUtilities {
  public static func createSampleDirectoryStructure(
    in basePath: String,
    fileCount: Int
  ) throws -> String {
    let fileManager = FileManager.default

    // Create base directory if it doesn't exist
    try fileManager.createDirectory(
      atPath: basePath,
      withIntermediateDirectories: true
    )

    // Create a sample directory structure
    let mediaDirPath = (basePath as NSString).appendingPathComponent("media")
    let imagesDirPath = (mediaDirPath as NSString).appendingPathComponent("images")
    let videosDirPath = (mediaDirPath as NSString).appendingPathComponent("videos")

    try fileManager.createDirectory(atPath: mediaDirPath, withIntermediateDirectories: true)
    try fileManager.createDirectory(atPath: imagesDirPath, withIntermediateDirectories: true)
    try fileManager.createDirectory(atPath: videosDirPath, withIntermediateDirectories: true)

    // Create sample files
    let sampleContent = "This is a sample file created for testing purposes. It contains some test data.\n"

    // Create a sample file in each directory
    try sampleContent.write(
      toFile: (basePath as NSString).appendingPathComponent("sample.txt"),
      atomically: true,
      encoding: .utf8
    )
    try sampleContent.write(
      toFile: (mediaDirPath as NSString).appendingPathComponent("sample.txt"),
      atomically: true,
      encoding: .utf8
    )
    try sampleContent.write(
      toFile: (imagesDirPath as NSString).appendingPathComponent("sample.txt"),
      atomically: true,
      encoding: .utf8
    )
    try sampleContent.write(
      toFile: (videosDirPath as NSString).appendingPathComponent("sample.txt"),
      atomically: true,
      encoding: .utf8
    )

    // Create additional numbered files in each directory
    for fileIndex in 1...fileCount {
      let content = "This is test file number \(fileIndex) with some random content.\n"
      try content.write(
        toFile: (imagesDirPath as NSString).appendingPathComponent("file_\(fileIndex).txt"),
        atomically: true,
        encoding: .utf8
      )
      try content.write(
        toFile: (videosDirPath as NSString).appendingPathComponent("file_\(fileIndex).txt"),
        atomically: true,
        encoding: .utf8
      )
    }

    return basePath
  }
}
