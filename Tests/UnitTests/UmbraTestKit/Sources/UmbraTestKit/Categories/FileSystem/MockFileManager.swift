import Foundation

/// A mock implementation of FileManager for testing
@MainActor
public final class MockFileManager: Resettable, @unchecked Sendable {
  /// Enum representing file access permissions
  public enum FileAccess {
    case none
    case readOnly
    case writeOnly
    case readWrite
  }

  /// File system structure representation
  private struct FileSystemItem {
    var isDirectory: Bool
    var content: Data?
    var access: FileAccess
    var children: [String: FileSystemItem]?

    init(isDirectory: Bool, content: Data?=nil, access: FileAccess = .readWrite) {
      self.isDirectory=isDirectory
      self.content=content
      self.access=access
      children=isDirectory ? [:] : nil
    }
  }

  /// Root of the simulated file system
  private var fileSystem: [String: FileSystemItem]=["/": FileSystemItem(isDirectory: true)]

  /// Initializer
  public init() {
    // We'll register with the MockManager in an async context when needed
  }

  /// Register with the MockManager
  public func register() async {
    // Register with the MockManager
    MockManager.shared.register(self)
  }

  /// Reset the mock to its initial state
  public func reset() async {
    fileSystem=["/": FileSystemItem(isDirectory: true)]

    createDirectoryCallCount=0
    removeItemCallCount=0
    fileExistsCallCount=0
    contentsOfDirectoryCallCount=0
    contentsCallCount=0
    contentsAsyncCallCount=0
    isReadableCallCount=0
    isWritableCallCount=0
    attributesCallCount=0
    setAttributesCallCount=0
    startAccessingSecurityScopedResourceCallCount=0
    stopAccessingSecurityScopedResourceCallCount=0
  }

  // MARK: - Call Counters

  public private(set) var createDirectoryCallCount=0
  public private(set) var removeItemCallCount=0
  public private(set) var fileExistsCallCount=0
  public private(set) var contentsOfDirectoryCallCount=0
  public private(set) var contentsCallCount=0
  public private(set) var contentsAsyncCallCount=0
  public private(set) var isReadableCallCount=0
  public private(set) var isWritableCallCount=0
  public private(set) var attributesCallCount=0
  public private(set) var setAttributesCallCount=0
  public private(set) var startAccessingSecurityScopedResourceCallCount=0
  public private(set) var stopAccessingSecurityScopedResourceCallCount=0

  // MARK: - Security-Scoped Resources

  /// Tracks security-scoped resources that are currently being accessed
  private var securityScopedResourcesBeingAccessed: Set<URL>=[]

  /// Simulate starting access to a security-scoped resource
  public func simulateStartAccessingSecurityScopedResource(at url: URL) -> Bool {
    startAccessingSecurityScopedResourceCallCount += 1

    // Check if the file exists
    if !simulateFileExists(atPath: url.path) {
      return false
    }

    // Add to the set of resources being accessed
    securityScopedResourcesBeingAccessed.insert(url)

    // Update the file access to make it readable
    let path=url.path
    let components=path.split(separator: "/").map(String.init)

    guard !components.isEmpty else { return false }

    var currentDict=fileSystem
    let lastComponent=components.last!

    // Navigate to parent directory
    for component in components.dropLast() {
      if component.isEmpty { continue }

      guard let item=currentDict[component], item.isDirectory, let children=item.children else {
        return false
      }

      currentDict=children
    }

    // Update the file access
    if var item=currentDict[lastComponent] {
      if item.access == .none {
        item.access = .readOnly
      } else if item.access == .writeOnly {
        item.access = .readWrite
      }
      currentDict[lastComponent]=item
      return true
    }

    return false
  }

  /// Simulate stopping access to a security-scoped resource
  public func simulateStopAccessingSecurityScopedResource(at url: URL) {
    stopAccessingSecurityScopedResourceCallCount += 1

    // Remove from the set of resources being accessed
    securityScopedResourcesBeingAccessed.remove(url)

    // If the file was previously made accessible, revert to original access
    let path=url.path
    let components=path.split(separator: "/").map(String.init)

    if components.isEmpty { return }

    var currentDict=fileSystem
    let lastComponent=components.last!

    // Navigate to parent directory
    for component in components.dropLast() {
      if component.isEmpty { continue }

      guard let item=currentDict[component], item.isDirectory, let children=item.children else {
        return
      }

      currentDict=children
    }

    // Update the file access
    if var item=currentDict[lastComponent] {
      if item.access == .readOnly || item.access == .readWrite {
        item.access = .none
      }
      currentDict[lastComponent]=item
    }
  }

  // MARK: - Simulation Methods

  /// Simulate creating a directory
  public func simulateCreateDirectory(
    at url: URL,
    withIntermediateDirectories createIntermediates: Bool=false
  ) throws {
    createDirectoryCallCount += 1

    try checkForSimulatedError(path: url.path)

    let path=url.path
    let components=path.split(separator: "/").map(String.init)

    // Check if parent directories exist
    if !createIntermediates {
      let parentPath=components.dropLast().joined(separator: "/")
      if !parentPath.isEmpty, !simulateFileExists(atPath: "/" + parentPath, isDirectory: nil) {
        throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
      }
    }

    // Create directory path
    var currentPath=""
    var currentDict=fileSystem

    for component in components {
      if component.isEmpty { continue }

      currentPath += "/" + component

      if let item=currentDict[component] {
        if !item.isDirectory {
          throw NSError(domain: NSCocoaErrorDomain, code: NSFileWriteFileExistsError, userInfo: nil)
        }
        if let children=item.children {
          currentDict=children
        }
      } else {
        let newDir=FileSystemItem(isDirectory: true)
        currentDict[component]=newDir
        if let children=newDir.children {
          currentDict=children
        }
      }
    }
  }

  /// Simulate removing an item
  public func simulateRemoveItem(at url: URL) throws {
    removeItemCallCount += 1

    try checkForSimulatedError(path: url.path)

    let path=url.path
    let components=path.split(separator: "/").map(String.init)

    guard !components.isEmpty else {
      throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
    }

    var currentDict=fileSystem
    let lastComponent=components.last!

    // Navigate to parent directory
    for component in components.dropLast() {
      if component.isEmpty { continue }

      guard let item=currentDict[component], item.isDirectory, let children=item.children else {
        throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
      }

      currentDict=children
    }

    // Remove the item
    if currentDict[lastComponent] == nil {
      throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
    }

    currentDict.removeValue(forKey: lastComponent)
  }

  /// Simulate checking if a file exists
  public func simulateFileExists(
    atPath path: String,
    isDirectory: UnsafeMutablePointer<ObjCBool>?=nil
  ) -> Bool {
    fileExistsCallCount += 1

    do {
      try checkForSimulatedError(path: path)
    } catch {
      return false
    }

    let components=path.split(separator: "/").map(String.init)
    var currentDict=fileSystem

    for component in components {
      if component.isEmpty { continue }

      guard let item=currentDict[component] else {
        return false
      }

      if component == components.last {
        isDirectory?.pointee=ObjCBool(item.isDirectory)
        return true
      }

      if !item.isDirectory || item.children == nil {
        return false
      }

      currentDict=item.children!
    }

    return true
  }

  /// Simulate getting contents of a directory
  public func simulateContentsOfDirectory(at url: URL) throws -> [URL] {
    contentsOfDirectoryCallCount += 1

    let path=url.path
    let components=path.split(separator: "/").map(String.init)
    var currentDict=fileSystem

    // Navigate to directory
    for component in components {
      if component.isEmpty { continue }

      guard let item=currentDict[component], item.isDirectory, let children=item.children else {
        throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
      }

      currentDict=children
    }

    // Return URLs for all items in the directory
    return currentDict.keys.map { url.appendingPathComponent($0) }
  }

  /// Simulate getting file contents
  public func simulateContents(atPath path: String) throws -> Data {
    contentsCallCount += 1

    try checkForSimulatedError(path: path)

    let components=path.split(separator: "/").map(String.init)
    var currentDict=fileSystem

    for component in components {
      if component.isEmpty { continue }

      guard let item=currentDict[component] else {
        throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
      }

      if component == components.last {
        if item.isDirectory {
          throw NSError(
            domain: NSCocoaErrorDomain,
            code: NSFileReadInvalidFileNameError,
            userInfo: nil
          )
        }

        if item.access == .none || item.access == .writeOnly {
          throw NSError(
            domain: NSCocoaErrorDomain,
            code: NSFileReadNoPermissionError,
            userInfo: nil
          )
        }

        guard let content=item.content else {
          return Data()
        }

        return content
      }

      if !item.isDirectory || item.children == nil {
        throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
      }

      currentDict=item.children!
    }

    throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
  }

  /// Simulate getting file contents asynchronously
  public func simulateContentsAsync(atPath path: String) async throws -> Data {
    contentsAsyncCallCount += 1

    try checkForSimulatedError(path: path)

    // Simulate some async work
    return try simulateContents(atPath: path)
  }

  /// Simulate setting file content
  public func simulateSetFileContent(_ content: String, at url: URL) -> Bool {
    let data=content.data(using: .utf8) ?? Data()
    return simulateSetFileContent(data, at: url)
  }

  /// Simulate setting file content with Data
  public func simulateSetFileContent(_ data: Data, at url: URL) -> Bool {
    let path=url.path
    let components=path.split(separator: "/").map(String.init)

    guard !components.isEmpty else { return false }

    var currentDict=fileSystem
    let lastComponent=components.last!

    // Create parent directories if needed
    for component in components.dropLast() {
      if component.isEmpty { continue }

      if let item=currentDict[component], item.isDirectory, let children=item.children {
        currentDict=children
      } else {
        let newDir=FileSystemItem(isDirectory: true)
        currentDict[component]=newDir
        if let children=newDir.children {
          currentDict=children
        } else {
          return false
        }
      }
    }

    // Create or update the file
    if let item=currentDict[lastComponent] {
      if item.isDirectory {
        return false
      }

      if item.access == .none || item.access == .readOnly {
        return false
      }

      var updatedItem=item
      updatedItem.content=data
      currentDict[lastComponent]=updatedItem
    } else {
      currentDict[lastComponent]=FileSystemItem(isDirectory: false, content: data)
    }

    return true
  }

  /// Simulate checking if a file is readable
  public func simulateIsReadableFile(atPath path: String) -> Bool {
    isReadableCallCount += 1

    let components=path.split(separator: "/").map(String.init)
    var currentDict=fileSystem

    for component in components {
      if component.isEmpty { continue }

      guard let item=currentDict[component] else {
        return false
      }

      if component == components.last {
        return !item.isDirectory && (item.access == .readOnly || item.access == .readWrite)
      }

      if !item.isDirectory || item.children == nil {
        return false
      }

      currentDict=item.children!
    }

    return false
  }

  /// Simulate checking if a file is writable
  public func simulateIsWritableFile(atPath path: String) -> Bool {
    isWritableCallCount += 1

    let components=path.split(separator: "/").map(String.init)
    var currentDict=fileSystem

    for component in components {
      if component.isEmpty { continue }

      guard let item=currentDict[component] else {
        return false
      }

      if component == components.last {
        return !item.isDirectory && (item.access == .writeOnly || item.access == .readWrite)
      }

      if !item.isDirectory || item.children == nil {
        return false
      }

      currentDict=item.children!
    }

    return false
  }

  /// Simulate setting access permissions for a file
  public func simulateSetAccess(_ access: FileAccess, for url: URL) -> Bool {
    let path=url.path
    let components=path.split(separator: "/").map(String.init)

    guard !components.isEmpty else { return false }

    var currentDict=fileSystem
    let lastComponent=components.last!

    // Navigate to parent directory
    for component in components.dropLast() {
      if component.isEmpty { continue }

      guard let item=currentDict[component], item.isDirectory, let children=item.children else {
        return false
      }

      currentDict=children
    }

    // Update the file access
    if var item=currentDict[lastComponent] {
      item.access=access
      currentDict[lastComponent]=item
      return true
    }

    return false
  }

  /// Simulate getting file attributes
  public func simulateAttributes(ofItemAtPath path: String) throws -> [FileAttributeKey: Any] {
    attributesCallCount += 1

    let components=path.split(separator: "/").map(String.init)
    var currentDict=fileSystem

    for component in components {
      if component.isEmpty { continue }

      guard let item=currentDict[component] else {
        throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
      }

      if component == components.last {
        var attributes: [FileAttributeKey: Any]=[:]

        attributes[.type]=item.isDirectory ? FileAttributeType.typeDirectory : FileAttributeType
          .typeRegular

        if !item.isDirectory, let content=item.content {
          attributes[.size]=content.count
        }

        // Add more attributes as needed

        return attributes
      }

      if !item.isDirectory || item.children == nil {
        throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
      }

      currentDict=item.children!
    }

    throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
  }

  /// Simulate setting file attributes
  public func simulateSetAttributes(_: [FileAttributeKey: Any], ofItemAtPath path: String) throws {
    setAttributesCallCount += 1

    let components=path.split(separator: "/").map(String.init)
    var currentDict=fileSystem

    for component in components {
      if component.isEmpty { continue }

      guard let item=currentDict[component] else {
        throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
      }

      if component == components.last {
        // In a real implementation, we would update the item's attributes here
        // For now, we just verify the file exists
        return
      }

      if !item.isDirectory || item.children == nil {
        throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
      }

      currentDict=item.children!
    }

    throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
  }

  // MARK: - File Operations

  /// Simulate copying a file
  public func simulateCopyItem(at srcURL: URL, to dstURL: URL) throws {
    try checkForSimulatedError(path: srcURL.path)
    try checkForSimulatedError(path: dstURL.path)

    // Check if source exists
    if !simulateFileExists(atPath: srcURL.path) {
      throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
    }

    // Check if destination parent directory exists
    let dstParentPath=dstURL.deletingLastPathComponent().path
    if !simulateFileExists(atPath: dstParentPath, isDirectory: nil) {
      throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
    }

    // Get source content
    let srcComponents=srcURL.path.split(separator: "/").map(String.init)
    var srcDict=fileSystem
    var srcItem: FileSystemItem?

    for component in srcComponents {
      if component.isEmpty { continue }

      if let item=srcDict[component] {
        srcItem=item
        if let children=item.children {
          srcDict=children
        } else {
          break
        }
      } else {
        throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
      }
    }

    guard let sourceItem=srcItem else {
      throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
    }

    // Create destination
    let dstComponents=dstURL.path.split(separator: "/").map(String.init)
    var dstDict=fileSystem
    let dstLastComponent=dstComponents.last!

    for component in dstComponents.dropLast() {
      if component.isEmpty { continue }

      if let item=dstDict[component], item.isDirectory, let children=item.children {
        dstDict=children
      } else {
        throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
      }
    }

    // Create a copy of the source item
    dstDict[dstLastComponent]=sourceItem
  }

  /// Simulate moving a file
  public func simulateMoveItem(at srcURL: URL, to dstURL: URL) throws {
    try checkForSimulatedError(path: srcURL.path)
    try checkForSimulatedError(path: dstURL.path)

    // First copy the item
    try simulateCopyItem(at: srcURL, to: dstURL)

    // Then remove the original
    try simulateRemoveItem(at: srcURL)
  }

  /// Simulate creating a symbolic link
  public func simulateCreateSymbolicLink(at url: URL, withDestinationURL destURL: URL) throws {
    try checkForSimulatedError(path: url.path)
    try checkForSimulatedError(path: destURL.path)

    // In our mock, we'll just create a special file that represents a symlink
    // In a real implementation, we would need to track the link target as well

    let path=url.path
    let components=path.split(separator: "/").map(String.init)

    guard !components.isEmpty else {
      throw NSError(domain: NSCocoaErrorDomain, code: NSFileWriteUnknownError, userInfo: nil)
    }

    var currentDict=fileSystem
    let lastComponent=components.last!

    // Navigate to parent directory
    for component in components.dropLast() {
      if component.isEmpty { continue }

      if let item=currentDict[component], item.isDirectory, let children=item.children {
        currentDict=children
      } else {
        throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
      }
    }

    // Create a special file item that represents a symlink
    // We'll use a Data object containing the destination path
    let linkData=destURL.path.data(using: .utf8)!
    let linkItem=FileSystemItem(isDirectory: false, content: linkData, access: .readWrite)

    // Store in the file system
    currentDict[lastComponent]=linkItem
  }

  /// Simulate getting URLs for directory
  public func simulateURLsForDirectory(
    at url: URL,
    includingPropertiesForKeys _: [URLResourceKey]?=nil,
    options: FileManager.DirectoryEnumerationOptions=[]
  ) throws -> [URL] {
    try checkForSimulatedError(path: url.path)

    let path=url.path

    // Check if directory exists
    var isDir: ObjCBool=false
    if !simulateFileExists(atPath: path, isDirectory: &isDir) || !isDir.boolValue {
      throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
    }

    // Get directory contents
    let components=path.split(separator: "/").map(String.init)
    var currentDict=fileSystem

    for component in components {
      if component.isEmpty { continue }

      if let item=currentDict[component], item.isDirectory, let children=item.children {
        currentDict=children
      } else {
        throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
      }
    }

    // Create URLs for all children
    var urls: [URL]=[]

    for (name, item) in currentDict {
      // Skip hidden files if requested
      if options.contains(.skipsHiddenFiles), name.hasPrefix(".") {
        continue
      }

      // Skip subdirectories if requested
      if options.contains(.skipsSubdirectoryDescendants), item.isDirectory {
        continue
      }

      // Skip package contents if requested
      if options.contains(.skipsPackageDescendants), name.hasSuffix(".app") {
        continue
      }

      let childURL=url.appendingPathComponent(name)
      urls.append(childURL)
    }

    return urls
  }

  // MARK: - File Coordination

  /// Simulate coordinated reading
  public func simulateCoordinatedReading<T>(
    from url: URL,
    options _: NSFileCoordinator.ReadingOptions=[],
    byAccessor: (URL) throws -> T
  ) throws -> T {
    // For the mock, we'll just call the accessor directly
    // In a real implementation, this would handle file coordination
    try byAccessor(url)
  }

  /// Simulate coordinated writing
  public func simulateCoordinatedWriting<T>(
    to url: URL,
    options _: NSFileCoordinator.WritingOptions=[],
    byAccessor: (URL) throws -> T
  ) throws -> T {
    // For the mock, we'll just call the accessor directly
    // In a real implementation, this would handle file coordination
    try byAccessor(url)
  }

  // MARK: - Helper Methods

  /// Create a test file with specified content
  public func createTestFile(at url: URL, withContent content: String) throws -> URL {
    let data=content.data(using: .utf8)!
    let success=simulateSetFileContent(data, at: url)

    if !success {
      throw NSError(domain: NSCocoaErrorDomain, code: NSFileWriteUnknownError, userInfo: nil)
    }

    return url
  }

  /// Create a test directory with optional files
  public func createTestDirectory(at url: URL, withFiles fileNames: [String]=[]) throws -> URL {
    try simulateCreateDirectory(at: url, withIntermediateDirectories: true)

    for fileName in fileNames {
      let fileURL=url.appendingPathComponent(fileName)
      let content="Test content for \(fileName)"
      _=try createTestFile(at: fileURL, withContent: content)
    }

    return url
  }

  /// Simulate file system errors for specific paths
  private var pathsToSimulateErrors: [String: Error]=[:]

  /// Set an error to be thrown when accessing a specific path
  public func simulateError(_ error: Error, forPath path: String) {
    pathsToSimulateErrors[path]=error
  }

  /// Clear simulated errors
  public func clearSimulatedErrors() {
    pathsToSimulateErrors=[:]
  }

  /// Check if there's a simulated error for a path
  private func checkForSimulatedError(path: String) throws {
    if let error=pathsToSimulateErrors[path] {
      throw error
    }
  }
}
