import Foundation
import LoggingInterfaces
import LoggingTypes
import SynchronisationInterfaces

/**
 Command for listing synchronization operations.

 This command encapsulates the logic for retrieving a list of synchronization operations
 with optional filtering, following the command pattern architecture.
 */
public class ListSynchronizationOperationsCommand: BaseSynchronisationCommand,
SynchronisationCommand {
  /// The result type for this command
  public typealias ResultType=[SynchronisationOperationInfo]

  /// Optional filter for specific operation types or statuses
  private let filter: SynchronisationFilter?

  /// Maximum number of operations to return
  private let limit: Int

  /// Number of operations to skip from the start
  private let offset: Int

  /**
   Initializes a new list operations command.

   - Parameters:
      - filter: Optional filter for specific operation types or statuses
      - limit: Maximum number of operations to return
      - offset: Number of operations to skip from the start
      - logger: Logger instance for synchronization operations
   */
  public init(
    filter: SynchronisationFilter?=nil,
    limit: Int=50,
    offset: Int=0,
    logger: PrivacyAwareLoggingProtocol
  ) {
    self.filter=filter
    self.limit=limit
    self.offset=offset

    super.init(logger: logger)
  }

  /**
   Executes the list operations command.

   - Parameters:
      - context: The logging context for the operation
   - Returns: A list of synchronization operations matching the criteria
   - Throws: SynchronisationError if the operation fails
   */
  public func execute(context _: LogContextDTO) async throws -> [SynchronisationOperationInfo] {
    // Create a log context for this specific operation
    let operationContext=createLogContext(
      operation: "listOperations",
      operationID: UUID().uuidString,
      additionalMetadata: [
        "limit": (value: String(limit), privacyLevel: .public),
        "offset": (value: String(offset), privacyLevel: .public),
        "hasFilter": (value: String(filter != nil), privacyLevel: .public)
      ]
    )

    // Log operation start
    await logger.log(.debug, "Listing synchronization operations", context: operationContext)

    // Get all operations from the store
    let allOperations=Array(Self.activeOperations.values)

    // Apply filter if provided
    let filteredOperations=filter != nil ? applyFilter(allOperations, filter: filter!) :
      allOperations

    // Sort operations by creation date (newest first)
    let sortedOperations=filteredOperations.sorted { $0.createdAt > $1.createdAt }

    // Apply pagination
    let startIndex=min(offset, sortedOperations.count)
    let endIndex=min(startIndex + limit, sortedOperations.count)
    let paginatedOperations=Array(sortedOperations[startIndex..<endIndex])

    // Log success
    await logger.log(
      .debug,
      "Retrieved \(paginatedOperations.count) operations (filtered from \(allOperations.count) total)",
      context: operationContext
    )

    return paginatedOperations
  }

  /**
   Applies the filter to the list of operations.

   - Parameters:
      - operations: The list of operations to filter
      - filter: The filter to apply
   - Returns: The filtered list of operations
   */
  private func applyFilter(
    _ operations: [SynchronisationOperationInfo],
    filter: SynchronisationFilter
  ) -> [SynchronisationOperationInfo] {
    operations.filter { operation in
      // Filter by status if provided
      if let status=filter.status, operation.status != status {
        return false
      }

      // Filter by source type if provided
      if let sourceType=filter.sourceType, operation.source.type != sourceType {
        return false
      }

      // Filter by destination type if provided
      if let destinationType=filter.destinationType, operation.destination.type != destinationType {
        return false
      }

      // Filter by date range (start) if provided
      if let startDate=filter.startDate, operation.createdAt < startDate {
        return false
      }

      // Filter by date range (end) if provided
      if let endDate=filter.endDate, operation.createdAt > endDate {
        return false
      }

      // All filters passed
      return true
    }
  }
}
