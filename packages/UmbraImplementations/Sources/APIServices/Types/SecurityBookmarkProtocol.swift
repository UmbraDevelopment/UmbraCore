import Foundation

/**
 * Protocol for managing security-scoped bookmarks.
 * 
 * Security-scoped bookmarks allow an application to maintain access
 * to user-selected files or directories across application restarts.
 */
public protocol SecurityBookmarkProtocol {
    /**
     * Creates a security-scoped bookmark for a URL.
     *
     * @param url The URL to create a bookmark for
     * @param identifier An optional identifier for the bookmark
     * @return The identifier of the created bookmark
     * @throws If bookmark creation fails
     */
    func createBookmark(for url: String, withIdentifier identifier: String?) async throws -> String
    
    /**
     * Resolves a security-scoped bookmark to a URL string.
     *
     * @param identifier The identifier of the bookmark to resolve
     * @return The URL string for the resolved bookmark
     * @throws If bookmark resolution fails
     */
    func resolveBookmark(withIdentifier identifier: String) async throws -> String
    
    /**
     * Deletes a security-scoped bookmark.
     *
     * @param identifier The identifier of the bookmark to delete
     * @throws If bookmark deletion fails
     */
    func deleteBookmark(withIdentifier identifier: String) async throws
}
