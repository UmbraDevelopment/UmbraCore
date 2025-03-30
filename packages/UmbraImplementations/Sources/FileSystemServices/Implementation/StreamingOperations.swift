import FileSystemInterfaces
import FileSystemTypes
import Foundation
import LoggingTypes

/**
 # Streaming Operations Extension

 This extension provides streaming operations for reading and writing large files
 in chunks, which is more memory-efficient for large file operations.
 */
extension FileSystemServiceImpl {
  /**
   Reads a file in chunks, calling a handler for each chunk.

   This method is more memory-efficient for large files, as it does not
   require loading the entire file into memory at once.

   - Parameters:
      - path: The path to read from
      - chunkSize: The size of each chunk in bytes
      - handler: A function that processes each chunk of data
   - Throws: `FileSystemError.invalidPath` if the path is invalid
             `FileSystemError.pathNotFound` if the file does not exist
             `FileSystemError.readError` if the file cannot be read
   */
  public func readDataInChunks(
    at path: FilePath,
    chunkSize: Int,
    handler: @Sendable ([UInt8]) async throws -> Void
  ) async throws {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    guard chunkSize > 0 else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Chunk size must be positive"
      )
    }

    // Check if file exists
    let url=URL(fileURLWithPath: path.path)
    if !fileManager.fileExists(atPath: path.path) {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    do {
      let fileHandle=try FileHandle(forReadingFrom: url)
      defer {
        try? fileHandle.close()
      }

      // Track progress for logging
      var bytesRead=0

      while true {
        // Read a chunk
        guard let chunkData=try fileHandle.read(upToCount: chunkSize) else {
          // End of file reached
          break
        }

        if chunkData.isEmpty {
          // End of file reached
          break
        }

        bytesRead += chunkData.count

        // Call the handler for this chunk
        try await handler([UInt8](chunkData))
      }

      await logger.debug("Read \(bytesRead) bytes in chunks from \(path.path)", metadata: nil, source: "StreamingOperations")
    } catch let fsError as FileSystemInterfaces.FileSystemError {
      // Rethrow FileSystemError directly
      throw fsError
    } catch {
      await logger.error(
        "Failed to read file in chunks at \(path.path): \(error.localizedDescription)",
        metadata: nil,
        source: "StreamingOperations"
      )
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path.path,
        reason: error.localizedDescription
      )
    }
  }

  /**
   Reads the bytes of a file in chunks.

   This version reads the entire file as bytes, but does so in a streaming manner
   where each chunk is appended to a growing array.

   - Parameters:
      - path: The path to read from
      - chunkSize: The size of each chunk in bytes (default: 1MB)
   - Returns: The complete file contents as an array of bytes
   - Throws: `FileSystemError.invalidPath` if the path is invalid
             `FileSystemError.pathNotFound` if the file does not exist
             `FileSystemError.readError` if the file cannot be read
   */
  public func readFileInChunks(
    at path: FilePath,
    chunkSize: Int=1024 * 1024 // Default 1MB
  ) async throws -> [UInt8] {
    // Use an actor to safely collect bytes in a concurrent context
    actor ByteCollector {
      private var bytes: [UInt8]=[]

      func append(_ newBytes: [UInt8]) {
        bytes.append(contentsOf: newBytes)
      }

      func getBytes() -> [UInt8] {
        bytes
      }
    }

    let collector=ByteCollector()

    try await readDataInChunks(at: path, chunkSize: chunkSize) { bytes in
      // Safely append each chunk's bytes to our result
      await collector.append(bytes)
    }

    return await collector.getBytes()
  }

  /**
   Writes data to a file in chunks.

   This method is more memory-efficient for large files, as the data provider
   can generate or process data incrementally.

   - Parameters:
      - path: The path to write to
      - overwrite: Whether to overwrite an existing file
      - chunkProvider: A function that provides chunks of data (return nil to signal end)
   - Throws: `FileSystemError.invalidPath` if the path is invalid
             `FileSystemError.pathAlreadyExists` if the file exists and overwrite is false
             `FileSystemError.writeError` if the file cannot be written
   */
  public func writeDataInChunks(
    to path: FilePath,
    overwrite: Bool,
    chunkProvider: @Sendable () async throws -> [UInt8]?
  ) async throws {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    let url=URL(fileURLWithPath: path.path)

    // Check if file exists
    if !overwrite && fileManager.fileExists(atPath: path.path) {
      throw FileSystemInterfaces.FileSystemError.pathAlreadyExists(path: path.path)
    }

    // Create parent directory if needed
    let directory=url.deletingLastPathComponent()
    do {
      try fileManager.createDirectory(
        at: directory,
        withIntermediateDirectories: true,
        attributes: nil
      )
    } catch {
      await logger.error(
        "Failed to create parent directories for \(path.path): \(error.localizedDescription)",
        metadata: nil,
        source: "StreamingOperations"
      )
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: directory.path,
        reason: "Failed to create parent directories: \(error.localizedDescription)"
      )
    }

    do {
      // Create or overwrite the file
      fileManager.createFile(atPath: path.path, contents: nil, attributes: nil)

      let fileHandle=try FileHandle(forWritingTo: url)
      defer {
        try? fileHandle.close()
      }

      // Track progress for logging
      var bytesWritten=0

      // Get chunks from the provider and write them
      while let chunk=try await chunkProvider() {
        let data=Data(chunk)
        try fileHandle.write(contentsOf: data)
        bytesWritten += chunk.count
      }

      await logger.debug("Wrote \(bytesWritten) bytes in chunks to \(path.path)", metadata: nil, source: "StreamingOperations")
    } catch let fsError as FileSystemInterfaces.FileSystemError {
      // Rethrow FileSystemError directly
      throw fsError
    } catch {
      await logger.error(
        "Failed to write file in chunks at \(path.path): \(error.localizedDescription)",
        metadata: nil,
        source: "StreamingOperations"
      )
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: path.path,
        reason: error.localizedDescription
      )
    }
  }

  /**
   Writes bytes to a file in chunks.

   This version takes all data up front but writes it to disk in manageable chunks.

   - Parameters:
      - bytes: The complete bytes to write
      - path: The path to write to
      - overwrite: Whether to overwrite an existing file
      - chunkSize: The size of each chunk in bytes (default: 1MB)
   - Throws: `FileSystemError.invalidPath` if the path is invalid
             `FileSystemError.pathAlreadyExists` if the file exists and overwrite is false
             `FileSystemError.writeError` if the file cannot be written
   */
  public func writeFileInChunks(
    bytes: [UInt8],
    to path: FilePath,
    overwrite: Bool=true,
    chunkSize: Int=1024 * 1024 // Default 1MB
  ) async throws {
    // Use a concurrent-safe approach to chunk the data
    let chunkSizeValue=chunkSize

    // We'll use an actor to manage the offset state safely
    actor ChunkGenerator {
      private var currentOffset=0
      private let data: [UInt8]
      private let chunkSize: Int

      init(data: [UInt8], chunkSize: Int) {
        self.data=data
        self.chunkSize=chunkSize
      }

      func nextChunk() -> [UInt8]? {
        if currentOffset >= data.count {
          return nil // No more data
        }

        let end=min(currentOffset + chunkSize, data.count)
        let chunk=Array(data[currentOffset..<end])
        currentOffset=end

        return chunk
      }
    }

    let generator=ChunkGenerator(data: bytes, chunkSize: chunkSizeValue)

    try await writeDataInChunks(to: path, overwrite: overwrite) {
      await generator.nextChunk()
    }
  }
}
