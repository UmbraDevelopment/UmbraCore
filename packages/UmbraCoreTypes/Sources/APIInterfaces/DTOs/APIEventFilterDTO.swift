/// APIEventFilterDTO
///
/// Provides filtering criteria for API service events.
/// This DTO is used when subscribing to events to limit
/// which events are delivered to the subscriber.
///
/// All properties are immutable to ensure thread safety when
/// passing instances between actors or across module boundaries.
public struct APIEventFilterDTO: Sendable, Equatable {
  /// Optional event types to include
  public let eventTypes: [APIEventType]?

  /// Optional operation names to include
  public let operations: [String]?

  /// Optional minimum status level to include
  public let minimumStatus: APIOperationStatus?

  /// Optional filter that matches the event context with the provided string
  public let contextFilter: String?

  /// Determines if the filter should match any criteria (OR) or all criteria (AND)
  public let matchAny: Bool

  /// Creates a new APIEventFilterDTO instance
  /// - Parameters:
  ///   - eventTypes: Optional event types to include
  ///   - operations: Optional operation names to include
  ///   - minimumStatus: Optional minimum status level to include
  ///   - contextFilter: Optional filter that matches the context
  ///   - matchAny: Whether to match any criteria (true) or all criteria (false)
  public init(
    eventTypes: [APIEventType]?=nil,
    operations: [String]?=nil,
    minimumStatus: APIOperationStatus?=nil,
    contextFilter: String?=nil,
    matchAny: Bool=false
  ) {
    self.eventTypes=eventTypes
    self.operations=operations
    self.minimumStatus=minimumStatus
    self.contextFilter=contextFilter
    self.matchAny=matchAny
  }

  /// Predefined filter that includes only error events
  public static var errorsOnly: APIEventFilterDTO {
    APIEventFilterDTO(eventTypes: [.error])
  }

  /// Predefined filter that includes only initialisation events
  public static var initialisationOnly: APIEventFilterDTO {
    APIEventFilterDTO(eventTypes: [.initialisation])
  }

  /// Predefined filter that includes only completed operations
  public static var completedOperationsOnly: APIEventFilterDTO {
    APIEventFilterDTO(minimumStatus: .completed)
  }
}
