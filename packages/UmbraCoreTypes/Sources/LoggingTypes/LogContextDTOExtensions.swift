/// Extensions to the LogContextDTO protocol to provide common functionality
extension LogContextDTO {
  /// Get the source information, providing a default if not available
  /// - Returns: The source information or a default value
  public func getSource() -> String {
    source ?? "\(domainName).Logger"
  }

  /// Convert the context's metadata to legacy PrivacyMetadata format
  /// - Returns: A PrivacyMetadata instance with equivalent entries
  public func toPrivacyMetadata() -> PrivacyMetadata {
    metadata.toPrivacyMetadata()
  }

  /// Create a new context with updated metadata
  /// - Parameter metadataCollection: The metadata to merge with existing metadata
  /// - Returns: A new context with the updated metadata
  public func withUpdatedMetadata(_ metadataCollection: LogMetadataDTOCollection)
  -> BaseLogContextDTO {
    BaseLogContextDTO(
      domainName: domainName,
      operation: operation,
      category: category,
      source: source,
      metadata: metadata.merging(with: metadataCollection),
      correlationID: correlationID
    )
  }
}
