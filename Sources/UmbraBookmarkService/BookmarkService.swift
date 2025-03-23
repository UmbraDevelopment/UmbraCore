import Foundation
import UmbraXPC

/// Service for managing security-scoped bookmarks
public final class BookmarkService: NSObject, BookmarkServiceProtocol, NSXPCListenerDelegate,
@unchecked Sendable {
  /// Set of URLs currently being accessed
  @MainActor
  private var activeAccessURLs: Set<URL>=[]

  // Thread-safe storage for connections
  private let connectionLock=NSLock()
  private var connections: [UUID: NSXPCConnection]=[:]

  public override init() {
    super.init()
  }

  // Thread-safe methods for connection management
  private func storeConnection(_ connection: NSXPCConnection, forID id: UUID) {
    connectionLock.lock()
    defer { connectionLock.unlock() }
    connections[id]=connection
  }

  private func getConnection(forID id: UUID) -> NSXPCConnection? {
    connectionLock.lock()
    defer { connectionLock.unlock() }
    return connections[id]
  }

  private func removeConnection(forID id: UUID) {
    connectionLock.lock()
    defer { connectionLock.unlock() }
    connections.removeValue(forKey: id)
  }

  // MARK: - Bookmark Management Methods

  @MainActor
  public func createBookmark(
    for url: URL,
    options: URL.BookmarkCreationOptions=[.withSecurityScope]
  ) async throws -> Data {
    do {
      // Create a security-scoped bookmark
      let bookmarkData=try url.bookmarkData(
        options: options,
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
      return bookmarkData
    } catch {
      throw error
    }
  }

  @MainActor
  public func resolveBookmark(
    _ bookmarkData: Data,
    options: URL.BookmarkResolutionOptions=[.withSecurityScope]
  ) async throws -> (URL, Bool) {
    var isStale=false
    do {
      // Resolve a security-scoped bookmark
      let url=try URL(
        resolvingBookmarkData: bookmarkData,
        options: options,
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )

      // If the bookmark is stale, it should be recreated
      if isStale {
        // This would ideally recreate the bookmark, but for now we'll just throw
        throw NSError(
          domain: NSCocoaErrorDomain,
          code: NSFileReadCorruptFileError,
          userInfo: [NSLocalizedDescriptionKey: "Bookmark is stale and needs to be recreated"]
        )
      }

      return (url, isStale)
    } catch {
      throw error
    }
  }

  @MainActor
  public func startAccessing(_ url: URL) async throws {
    guard url.isFileURL else {
      throw BookmarkError.invalidBookmarkData
    }

    if await isAccessing(url) { return }

    guard url.startAccessingSecurityScopedResource() else {
      throw BookmarkError.startAccessFailed(url: url)
    }

    activeAccessURLs.insert(url)
  }

  @MainActor
  public func stopAccessing(_ url: URL) async {
    guard url.isFileURL else { return }

    if await isAccessing(url) {
      url.stopAccessingSecurityScopedResource()
      activeAccessURLs.remove(url)
    }
  }

  @MainActor
  public func isAccessing(_ url: URL) async -> Bool {
    activeAccessURLs.contains(url)
  }

  // MARK: - NSXPCListenerDelegate

  // This method must be nonisolated due to NSXPCListenerDelegate protocol requirements
  public nonisolated func listener(
    _: NSXPCListener,
    shouldAcceptNewConnection newConnection: NSXPCConnection
  ) -> Bool {
    // Configure the connection immediately
    let exportedInterface=NSXPCInterface(with: BookmarkServiceProtocol.self)
    newConnection.exportedInterface=exportedInterface

    // Generate a UUID to track this connection
    let connectionID=UUID()

    // Set up connection handler for invalidation
    newConnection.invalidationHandler={ [weak self] in
      self?.removeConnection(forID: connectionID)
    }

    // Store the connection safely
    storeConnection(newConnection, forID: connectionID)

    // Schedule final setup on the main queue
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }

      // Now we're on the main thread
      Task { @MainActor [self] in
        if let connection=getConnection(forID: connectionID) {
          // Configure the connection object
          connection.exportedObject=self
          connection.resume()
        }
      }
    }

    return true
  }
}
