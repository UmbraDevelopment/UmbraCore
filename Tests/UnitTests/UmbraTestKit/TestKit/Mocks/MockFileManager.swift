import Foundation
import SecurityTypes

/// Represents file access permissions for the mock file system
public enum FilePermission {
  case none
  case readOnly
  case readWrite

  public var canRead: Bool {
    self != .none
  }

  public var canWrite: Bool {
    self == .readWrite
  }
}

/// A mock implementation of FileManager for testing
@objc
public final class MockFileManager: FileManager {
  // Nonisolated storage
  private let storage=Storage()

  private final class Storage: @unchecked Sendable {
    var fileContents: [String: Data]=[:]
    var fileAccess: [String: FilePermission]=[:]
    var directories: Set<String>=[]
    var securityScopedAccess: Set<String>=[] // Track URLs with security-scoped access
    var symlinks: [String: String]=[:]
  }

  // MARK: - Mock Handlers

  private let handlerStorage=HandlerStorage()

  private final class HandlerStorage: @unchecked Sendable {
    var startAccessingHandler: ((URL) -> Bool)?
    var stopAccessingHandler: ((URL) -> Void)?
  }

  public var startAccessingHandler: ((URL) -> Bool)? {
    get { handlerStorage.startAccessingHandler }
    set { handlerStorage.startAccessingHandler=newValue }
  }

  public var stopAccessingHandler: ((URL) -> Void)? {
    get { handlerStorage.stopAccessingHandler }
    set { handlerStorage.stopAccessingHandler=newValue }
  }

  // MARK: - File Operations

  public func simulateContents(atPath path: String) -> Data? {
    guard let access=storage.fileAccess[path], access != .none else {
      return nil
    }
    return storage.fileContents[path]
  }

  @discardableResult
  public func simulateCreateFile(
    atPath path: String,
    contents data: Data?,
    attributes attr: [FileAttributeKey: Any]?
  ) -> Bool {
    setDefaultAccess(forPath: path, withPermissions: attr?[.posixPermissions] as? Int)

    if let data {
      storage.fileContents[path]=data
    } else {
      storage.fileContents[path]=Data()
    }
    return true
  }

  private func setDefaultAccess(forPath path: String, withPermissions permissions: Int?=nil) {
    if let permissions {
      switch permissions {
        case 0o444: // Read-only
          storage.fileAccess[path]=FilePermission.readOnly
        case 0o666, 0o777: // Read-write
          storage.fileAccess[path]=FilePermission.readWrite
        default:
          storage.fileAccess[path]=FilePermission.none
      }
    } else {
      // Default to read-write if no permissions specified
      storage.fileAccess[path]=FilePermission.readWrite
    }
  }

  public func simulateRemoveFile(atPath path: String) {
    storage.fileContents.removeValue(forKey: path)
    storage.fileAccess.removeValue(forKey: path)
    storage.directories.remove(path)
  }

  // MARK: - URL-based File Operations

  public func simulateSetFileContent(_ content: String, at url: URL) {
    let path=url.path
    simulateCreateFile(atPath: path, contents: content.data(using: .utf8), attributes: nil)
  }

  @discardableResult
  public func simulateSetAccess(_ access: FilePermission, for url: URL) -> Bool {
    storage.fileAccess[url.path]=access
    return true
  }

  public func simulateGetAccess(for url: URL) -> FilePermission {
    // Check each component of the path to ensure we have access to all parent directories
    var currentPath=""
    for component in url.pathComponents {
      if component == "/" {
        currentPath="/"
      } else {
        currentPath=(currentPath as NSString).appendingPathComponent(component)
        let access=storage.fileAccess[currentPath] ?? FilePermission.none
        if !access.canRead, !hasSecurityScopedAccess(for: URL(fileURLWithPath: currentPath)) {
          return FilePermission.none
        }
      }
    }

    // Return the actual file's permissions if we have access to all parent directories
    let baseAccess=storage.fileAccess[url.path] ?? FilePermission.none
    return hasSecurityScopedAccess(for: url) ? .readWrite : baseAccess
  }

  // MARK: - Security-Scoped Access

  private func hasSecurityScopedAccess(for url: URL) -> Bool {
    storage.securityScopedAccess.contains(url.path)
  }

  public func simulateStartAccessingSecurityScopedResource(_ url: URL) -> Bool {
    if let handler=startAccessingHandler {
      let result=handler(url)
      if result {
        storage.securityScopedAccess.insert(url.path)
      }
      return result
    }

    // Default implementation: always grant access
    storage.securityScopedAccess.insert(url.path)
    return true
  }

  public func simulateStopAccessingSecurityScopedResource(_ url: URL) {
    storage.securityScopedAccess.remove(url.path)
    stopAccessingHandler?(url)
  }

  // MARK: - File Existence

  public func simulateFileExists(atPath path: String) -> Bool {
    storage.fileAccess[path] != nil || storage.directories.contains(path)
  }

  public func simulateFileExists(atPath path: String, isDirectory: inout Bool) -> Bool {
    isDirectory=storage.directories.contains(path)
    return storage.fileAccess[path] != nil || storage.directories.contains(path)
  }

  public func simulateIsReadableFile(atPath path: String) -> Bool {
    guard let access=storage.fileAccess[path] else {
      return false
    }
    return access == .readOnly || access == .readWrite
  }

  public func simulateIsWritableFile(atPath path: String) -> Bool {
    if let access=storage.fileAccess[path] {
      return access == .readWrite
    }
    return false
  }

  public func createDirectory(
    at url: URL,
    withIntermediateDirectories createIntermediates: Bool,
    attributes _: [FileAttributeKey: Any]?
  ) throws -> Bool {
    if createIntermediates {
      var currentPath=""
      for component in url.pathComponents {
        if component == "/" {
          currentPath="/"
        } else {
          currentPath=(currentPath as NSString).appendingPathComponent(component)
          setDefaultAccess(forPath: currentPath)
          storage.directories.insert(currentPath)
        }
      }
    } else {
      guard !simulateFileExists(atPath: url.path) else {
        throw NSError(domain: NSCocoaErrorDomain, code: NSFileWriteFileExistsError)
      }
      setDefaultAccess(forPath: url.path)
      storage.directories.insert(url.path)
    }
    return true
  }

  public func createDirectory(
    atPath path: String,
    withIntermediateDirectories createIntermediates: Bool,
    attributes _: [FileAttributeKey: Any]?
  ) throws -> Bool {
    if createIntermediates {
      var currentPath=""
      // Split the path manually instead of using pathComponents
      let components=path.split(separator: "/").map(String.init)
      if path.hasPrefix("/") {
        currentPath="/"
      }

      for component in components {
        if !component.isEmpty {
          currentPath=(currentPath as NSString).appendingPathComponent(component)
          setDefaultAccess(forPath: currentPath)
          storage.directories.insert(currentPath)
        }
      }
    } else {
      guard !simulateFileExists(atPath: path) else {
        throw NSError(domain: NSCocoaErrorDomain, code: NSFileWriteFileExistsError)
      }
      setDefaultAccess(forPath: path)
      storage.directories.insert(path)
    }
    return true
  }

  public func createSymbolicLink(
    at url: URL,
    withDestinationURL destinationURL: URL
  ) throws -> Bool {
    guard storage.fileContents[url.path] != nil else {
      throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError)
    }

    storage.symlinks[url.path]=destinationURL.path
    return true
  }

  // MARK: - Async File Operations

  public func simulateContentsAsync(atPath path: String) async throws -> Data? {
    simulateContents(atPath: path)
  }
}
