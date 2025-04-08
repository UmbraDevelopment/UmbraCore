import DateTimeInterfaces
import Foundation

/// Factory for creating DateTimeDTOAdapter instances
///
/// This factory provides the standard way to create DateTimeDTOAdapter instances,
/// ensuring consistent configuration across the application.
///
/// As an actor, this factory provides thread safety for adapter creation
/// and maintains a cache of created adapters for improved performance.
public actor DateTimeDTOFactory {
  /// Shared singleton instance
  public static let shared=DateTimeDTOFactory()

  /// Cache of created adapters by configuration key
  private var adapterCache: [String: DateTimeDTOAdapter]=[:]

  /// Initialiser
  public init() {}

  /// Create a default DateTimeDTOAdapter
  /// - Parameter useCache: Whether to cache and reuse the created adapter
  /// - Returns: A configured DateTimeDTOAdapter
  public func createDefault(useCache: Bool=true) async -> DateTimeDTOAdapter {
    let cacheKey="default"

    if useCache, let cachedAdapter=adapterCache[cacheKey] {
      return cachedAdapter
    }

    let adapter=DateTimeDTOAdapter()

    if useCache {
      adapterCache[cacheKey]=adapter
    }

    return adapter
  }

  /// Clears the adapter cache
  ///
  /// This can be useful when testing or when adapters need to be recreated
  /// with fresh configurations.
  public func clearCache() {
    adapterCache.removeAll()
  }

  /// Removes a specific adapter from the cache
  ///
  /// - Parameter cacheKey: The cache key for the adapter to remove
  /// - Returns: True if an adapter was removed, false if no adapter was found
  public func removeFromCache(cacheKey: String) -> Bool {
    if adapterCache[cacheKey] != nil {
      adapterCache[cacheKey]=nil
      return true
    }
    return false
  }
}
