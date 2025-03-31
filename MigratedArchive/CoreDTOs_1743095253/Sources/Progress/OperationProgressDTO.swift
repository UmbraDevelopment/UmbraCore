import UmbraCoreTypes

/// FoundationIndependent representation of operation progress.
/// This data transfer object encapsulates progress information for operations
/// without using any Foundation types.
public struct OperationProgressDTO: Sendable, Equatable {
  // MARK: - Types

  /// Represents the type of operation in progress
  public enum OperationType: Sendable, Equatable {
    /// Backup operation
    case backup
    /// Restore operation
    case restore
    /// Repository check operation
    case check
    /// Repository prune operation
    case prune
    /// Security operation
    case security
    /// Cryptographic operation
    case crypto
    /// Generic operation with custom description
    case other(String)

    /// Convert to string representation
    public var description: String {
      switch self {
        case .backup:
          "Backup"
        case .restore:
          "Restore"
        case .check:
          "Check"
        case .prune:
          "Prune"
        case .security:
          "Security"
        case .crypto:
          "Crypto"
        case let .other(description):
          description
      }
    }
  }

  // MARK: - Properties

  /// The type of operation in progress
  public let operationType: OperationType

  /// Progress as a value between 0.0 and 1.0
  public let progress: Double

  /// The number of bytes processed so far
  public let bytesProcessed: UInt64?

  /// The total number of bytes to process
  public let totalBytes: UInt64?

  /// The number of items processed so far
  public let itemsProcessed: Int?

  /// The total number of items to process
  public let totalItems: Int?

  /// The current file or item being processed
  public let currentItem: String?

  /// Whether the progress is indeterminate
  public let isIndeterminate: Bool

  /// When the operation started (Unix timestamp - seconds since epoch)
  public let startTimestamp: UInt64

  /// Estimated time remaining in seconds
  public let estimatedTimeRemaining: UInt64?

  /// Optional status message
  public let statusMessage: String?

  // MARK: - Initializers

  /// Full initializer with all progress information
  /// - Parameters:
  ///   - operationType: The type of operation in progress
  ///   - progress: Progress as a value between 0.0 and 1.0
  ///   - bytesProcessed: The number of bytes processed so far
  ///   - totalBytes: The total number of bytes to process
  ///   - itemsProcessed: The number of items processed so far
  ///   - totalItems: The total number of items to process
  ///   - currentItem: The current file or item being processed
  ///   - isIndeterminate: Whether the progress is indeterminate
  ///   - startTimestamp: When the operation started (Unix timestamp)
  ///   - estimatedTimeRemaining: Estimated time remaining in seconds
  ///   - statusMessage: Optional status message
  public init(
    operationType: OperationType,
    progress: Double,
    bytesProcessed: UInt64?=nil,
    totalBytes: UInt64?=nil,
    itemsProcessed: Int?=nil,
    totalItems: Int?=nil,
    currentItem: String?=nil,
    isIndeterminate: Bool=false,
    startTimestamp: UInt64,
    estimatedTimeRemaining: UInt64?=nil,
    statusMessage: String?=nil
  ) {
    self.operationType=operationType
    // Clamp progress between 0.0 and 1.0
    self.progress=min(1.0, max(0.0, progress))
    self.bytesProcessed=bytesProcessed
    self.totalBytes=totalBytes
    self.itemsProcessed=itemsProcessed
    self.totalItems=totalItems
    self.currentItem=currentItem
    self.isIndeterminate=isIndeterminate
    self.startTimestamp=startTimestamp
    self.estimatedTimeRemaining=estimatedTimeRemaining
    self.statusMessage=statusMessage
  }

  // MARK: - Factory Methods

  /// Create an indeterminate progress
  /// - Parameters:
  ///   - operationType: The type of operation in progress
  ///   - currentItem: The current file or item being processed
  ///   - startTimestamp: When the operation started (Unix timestamp)
  ///   - statusMessage: Optional status message
  /// - Returns: An OperationProgressDTO with indeterminate progress
  public static func indeterminate(
    operationType: OperationType,
    currentItem: String?=nil,
    startTimestamp: UInt64,
    statusMessage: String?=nil
  ) -> OperationProgressDTO {
    OperationProgressDTO(
      operationType: operationType,
      progress: 0.0,
      currentItem: currentItem,
      isIndeterminate: true,
      startTimestamp: startTimestamp,
      statusMessage: statusMessage
    )
  }

  /// Create a security operation progress
  /// - Parameters:
  ///   - progress: Progress as a value between 0.0 and 1.0
  ///   - operation: Description of the security operation
  ///   - startTimestamp: When the operation started (Unix timestamp)
  /// - Returns: An OperationProgressDTO for a security operation
  public static func securityOperation(
    progress: Double,
    operation: String,
    startTimestamp: UInt64
  ) -> OperationProgressDTO {
    OperationProgressDTO(
      operationType: .security,
      progress: progress,
      currentItem: operation,
      isIndeterminate: false,
      startTimestamp: startTimestamp,
      statusMessage: "Performing security operation: \(operation)"
    )
  }

  /// Create a cryptographic operation progress
  /// - Parameters:
  ///   - progress: Progress as a value between 0.0 and 1.0
  ///   - algorithm: Description of the cryptographic algorithm
  ///   - startTimestamp: When the operation started (Unix timestamp)
  /// - Returns: An OperationProgressDTO for a cryptographic operation
  public static func cryptoOperation(
    progress: Double,
    algorithm: String,
    startTimestamp: UInt64
  ) -> OperationProgressDTO {
    OperationProgressDTO(
      operationType: .crypto,
      progress: progress,
      currentItem: algorithm,
      isIndeterminate: false,
      startTimestamp: startTimestamp,
      statusMessage: "Performing cryptographic operation: \(algorithm)"
    )
  }

  // MARK: - Computed Properties

  /// Whether the operation is complete
  public var isComplete: Bool {
    progress >= 1.0
  }

  /// Elapsed time in seconds
  public func elapsedTime(currentTimestamp: UInt64) -> UInt64 {
    if currentTimestamp <= startTimestamp { return 0 }
    return currentTimestamp - startTimestamp
  }

  /// Percentage complete (0-100)
  public var percentComplete: Int {
    Int(progress * 100.0)
  }

  // MARK: - Utility Methods

  /// Create a copy of this progress with updated progress value
  /// - Parameter newProgress: The new progress value (0.0-1.0)
  /// - Returns: A new OperationProgressDTO with updated progress
  public func withProgress(_ newProgress: Double) -> OperationProgressDTO {
    OperationProgressDTO(
      operationType: operationType,
      progress: newProgress,
      bytesProcessed: bytesProcessed,
      totalBytes: totalBytes,
      itemsProcessed: itemsProcessed,
      totalItems: totalItems,
      currentItem: currentItem,
      isIndeterminate: isIndeterminate,
      startTimestamp: startTimestamp,
      estimatedTimeRemaining: estimatedTimeRemaining,
      statusMessage: statusMessage
    )
  }

  /// Create a copy of this progress with updated bytes processed
  /// - Parameters:
  ///   - processed: The new bytes processed value
  ///   - total: The new total bytes value (optional)
  /// - Returns: A new OperationProgressDTO with updated bytes
  public func withBytes(processed: UInt64, total: UInt64?=nil) -> OperationProgressDTO {
    let totalToUse=total ?? totalBytes

    // Calculate new progress if we have total bytes
    var newProgress=progress
    if let totalToUse, totalToUse > 0 {
      newProgress=min(1.0, Double(processed) / Double(totalToUse))
    }

    return OperationProgressDTO(
      operationType: operationType,
      progress: newProgress,
      bytesProcessed: processed,
      totalBytes: totalToUse,
      itemsProcessed: itemsProcessed,
      totalItems: totalItems,
      currentItem: currentItem,
      isIndeterminate: isIndeterminate,
      startTimestamp: startTimestamp,
      estimatedTimeRemaining: estimatedTimeRemaining,
      statusMessage: statusMessage
    )
  }

  /// Create a copy of this progress with updated items processed
  /// - Parameters:
  ///   - processed: The new items processed value
  ///   - total: The new total items value (optional)
  /// - Returns: A new OperationProgressDTO with updated items
  public func withItems(processed: Int, total: Int?=nil) -> OperationProgressDTO {
    let totalToUse=total ?? totalItems

    // Calculate new progress if we have total items
    var newProgress=progress
    if let totalToUse, totalToUse > 0 {
      newProgress=min(1.0, Double(processed) / Double(totalToUse))
    }

    return OperationProgressDTO(
      operationType: operationType,
      progress: newProgress,
      bytesProcessed: bytesProcessed,
      totalBytes: totalBytes,
      itemsProcessed: processed,
      totalItems: totalToUse,
      currentItem: currentItem,
      isIndeterminate: isIndeterminate,
      startTimestamp: startTimestamp,
      estimatedTimeRemaining: estimatedTimeRemaining,
      statusMessage: statusMessage
    )
  }

  /// Create a copy of this progress with updated current item
  /// - Parameter item: The new current item
  /// - Returns: A new OperationProgressDTO with updated current item
  public func withCurrentItem(_ item: String) -> OperationProgressDTO {
    OperationProgressDTO(
      operationType: operationType,
      progress: progress,
      bytesProcessed: bytesProcessed,
      totalBytes: totalBytes,
      itemsProcessed: itemsProcessed,
      totalItems: totalItems,
      currentItem: item,
      isIndeterminate: isIndeterminate,
      startTimestamp: startTimestamp,
      estimatedTimeRemaining: estimatedTimeRemaining,
      statusMessage: statusMessage
    )
  }

  /// Create a copy of this progress with updated time remaining
  /// - Parameter timeRemaining: The new estimated time remaining in seconds
  /// - Returns: A new OperationProgressDTO with updated time remaining
  public func withEstimatedTimeRemaining(_ timeRemaining: UInt64) -> OperationProgressDTO {
    OperationProgressDTO(
      operationType: operationType,
      progress: progress,
      bytesProcessed: bytesProcessed,
      totalBytes: totalBytes,
      itemsProcessed: itemsProcessed,
      totalItems: totalItems,
      currentItem: currentItem,
      isIndeterminate: isIndeterminate,
      startTimestamp: startTimestamp,
      estimatedTimeRemaining: timeRemaining,
      statusMessage: statusMessage
    )
  }

  /// Create a copy of this progress with updated status message
  /// - Parameter message: The new status message
  /// - Returns: A new OperationProgressDTO with updated status message
  public func withStatusMessage(_ message: String) -> OperationProgressDTO {
    OperationProgressDTO(
      operationType: operationType,
      progress: progress,
      bytesProcessed: bytesProcessed,
      totalBytes: totalBytes,
      itemsProcessed: itemsProcessed,
      totalItems: totalItems,
      currentItem: currentItem,
      isIndeterminate: isIndeterminate,
      startTimestamp: startTimestamp,
      estimatedTimeRemaining: estimatedTimeRemaining,
      statusMessage: message
    )
  }

  /// Create a copy of this progress with complete status (100%)
  /// - Parameter message: Optional completion message
  /// - Returns: A new OperationProgressDTO marked as complete
  public func completed(message: String?=nil) -> OperationProgressDTO {
    let completionMessage=message ?? "Operation completed successfully"

    return OperationProgressDTO(
      operationType: operationType,
      progress: 1.0,
      bytesProcessed: bytesProcessed,
      totalBytes: totalBytes,
      itemsProcessed: itemsProcessed,
      totalItems: totalItems,
      currentItem: currentItem,
      isIndeterminate: false,
      startTimestamp: startTimestamp,
      estimatedTimeRemaining: 0,
      statusMessage: completionMessage
    )
  }
}
