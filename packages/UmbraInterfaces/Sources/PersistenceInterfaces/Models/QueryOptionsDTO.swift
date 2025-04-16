import Foundation

/**
 Enum defining query sorting directions.
 */
public enum SortDirection: String, Codable, Sendable {
  /// Sort in ascending order
  case ascending

  /// Sort in descending order
  case descending
}

/**
 Represents a single sort option with field and direction.
 */
public struct SortOption: Codable, Equatable, Sendable {
  /// The field to sort by
  public let field: String

  /// The direction to sort in
  public let direction: SortDirection

  /**
   Initialises a new sort option.

   - Parameters:
      - field: The field to sort by
      - direction: The direction to sort in
   */
  public init(field: String, direction: SortDirection) {
    self.field=field
    self.direction=direction
  }
}

/**
 Data Transfer Object for query options.

 This DTO provides options for querying data from the persistence layer,
 including filtering, sorting, and pagination.
 */
public struct QueryOptionsDTO {
  /// Optional filtering criteria as key-value pairs
  public let filter: [String: Any]?

  /// Optional sorting information as field-direction pairs
  public let sort: [SortOption]?

  /// Optional limit on the number of results
  public let limit: Int?

  /// Optional offset for pagination
  public let offset: Int?

  /// Whether to include soft-deleted items
  public let includeDeleted: Bool

  /// Whether to include associated objects
  public let includeRelated: Bool

  /**
   Initialises a new query options DTO.

   - Parameters:
      - filter: Optional filtering criteria as key-value pairs
      - sort: Optional sorting information as field-direction pairs
      - limit: Optional limit on the number of results
      - offset: Optional offset for pagination
      - includeDeleted: Whether to include soft-deleted items
      - includeRelated: Whether to include associated objects
   */
  public init(
    filter: [String: Any]?=nil,
    sort: [SortOption]?=nil,
    limit: Int?=nil,
    offset: Int?=nil,
    includeDeleted: Bool=false,
    includeRelated: Bool=false
  ) {
    self.filter=filter
    self.sort=sort
    self.limit=limit
    self.offset=offset
    self.includeDeleted=includeDeleted
    self.includeRelated=includeRelated
  }

  /// Default query options with no filtering or sorting
  public static var `default`: QueryOptionsDTO {
    QueryOptionsDTO()
  }
}

/**
 Extension to make QueryOptionsDTO Codable.

 This extension handles the encoding/decoding of the filter property,
 which contains Any values that aren't directly Codable.
 */
extension QueryOptionsDTO: Codable {
  private enum CodingKeys: String, CodingKey {
    case sort
    case limit
    case offset
    case includeDeleted
    case includeRelated
    case filter
  }

  public init(from decoder: Decoder) throws {
    let container=try decoder.container(keyedBy: CodingKeys.self)

    sort=try container.decodeIfPresent([SortOption].self, forKey: .sort)
    limit=try container.decodeIfPresent(Int.self, forKey: .limit)
    offset=try container.decodeIfPresent(Int.self, forKey: .offset)
    includeDeleted=try container.decodeIfPresent(Bool.self, forKey: .includeDeleted) ?? false
    includeRelated=try container.decodeIfPresent(Bool.self, forKey: .includeRelated) ?? false

    // Decode filter as a JSON object and convert to [String: Any]
    if let filterData=try container.decodeIfPresent(Data.self, forKey: .filter) {
      filter=try JSONSerialization.jsonObject(with: filterData) as? [String: Any]
    } else {
      filter=nil
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container=encoder.container(keyedBy: CodingKeys.self)

    try container.encodeIfPresent(sort, forKey: .sort)
    try container.encodeIfPresent(limit, forKey: .limit)
    try container.encodeIfPresent(offset, forKey: .offset)
    try container.encode(includeDeleted, forKey: .includeDeleted)
    try container.encode(includeRelated, forKey: .includeRelated)

    // Encode filter as JSON data
    if let filter {
      let filterData=try JSONSerialization.data(withJSONObject: filter)
      try container.encode(filterData, forKey: .filter)
    }
  }
}
