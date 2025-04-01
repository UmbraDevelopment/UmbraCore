/// CoreEventFilterDTO
///
/// Provides filtering criteria for core framework events.
/// This DTO is used when subscribing to events to limit
/// which events are delivered to the subscriber.
///
/// All properties are immutable to ensure thread safety when
/// passing instances between actors or across module boundaries.
public struct CoreEventFilterDTO: Sendable, Equatable {
  /// Optional event types to include
  public let eventTypes: [CoreEventType]?

  /// Optional component names to include
  public let components: [String]?

  /// Optional minimum status level to include
  public let minimumStatus: CoreEventStatus?

  /// Optional filter that matches the event context with the provided string
  public let contextFilter: String?

  /// Determines if the filter should match any criteria (OR) or all criteria (AND)
  public let matchAny: Bool

  /// Creates a new CoreEventFilterDTO instance
  /// - Parameters:
  ///   - eventTypes: Optional event types to include
  ///   - components: Optional component names to include
  ///   - minimumStatus: Optional minimum status level to include
  ///   - contextFilter: Optional filter that matches the context
  ///   - matchAny: Whether to match any criteria (true) or all criteria (false)
  public init(
    eventTypes: [CoreEventType]?=nil,
    components: [String]?=nil,
    minimumStatus: CoreEventStatus?=nil,
    contextFilter: String?=nil,
    matchAny: Bool=false
  ) {
    self.eventTypes=eventTypes
    self.components=components
    self.minimumStatus=minimumStatus
    self.contextFilter=contextFilter
    self.matchAny=matchAny
  }

  /// Predefined filter that includes only error events
  public static var errorsOnly: CoreEventFilterDTO {
    CoreEventFilterDTO(eventTypes: [.error])
  }

  /// Predefined filter that includes only initialisation events
  public static var initialisationOnly: CoreEventFilterDTO {
    CoreEventFilterDTO(eventTypes: [.initialisation])
  }

  /// Predefined filter that includes only service events
  public static var serviceEventsOnly: CoreEventFilterDTO {
    CoreEventFilterDTO(eventTypes: [.service])
  }

  /// Predefined filter that includes only shutdown events
  public static var shutdownEventsOnly: CoreEventFilterDTO {
    CoreEventFilterDTO(eventTypes: [.shutdown])
  }
}
