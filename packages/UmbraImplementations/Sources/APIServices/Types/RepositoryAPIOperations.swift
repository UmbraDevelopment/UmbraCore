import Foundation
import APIInterfaces

/**
 A wrapper for values that need to be Sendable in dictionaries
 */
public enum SendableValue: Sendable, Hashable {
  case string(String)
  case int(Int)
  case double(Double)
  case bool(Bool)
  case date(Date)
  case stringArray([String])
  case dictionary([String: SendableValue])
  case none
  
  public var stringValue: String? {
    switch self {
      case .string(let value): return value
      case .int(let value): return String(value)
      case .double(let value): return String(value)
      case .bool(let value): return String(value)
      case .date(let value): return ISO8601DateFormatter().string(from: value)
      case .none: return nil
      default: return nil
    }
  }
  
  public var intValue: Int? {
    switch self {
      case .int(let value): return value
      case .string(let value): return Int(value)
      default: return nil
    }
  }
  
  public var boolValue: Bool? {
    switch self {
      case .bool(let value): return value
      case .string(let value): return Bool(value)
      default: return nil
    }
  }
}

/**
 Protocol defining a repository-related API operation
 */
public protocol RepositoryAPIOperation: APIOperation {}

/**
 Operation for listing repositories
 */
public struct ListRepositoriesOperation: RepositoryAPIOperation, Sendable {
  public let includeDetails: Bool
  public let statusFilter: String?
  
  public init(includeDetails: Bool = false, statusFilter: String? = nil) {
    self.includeDetails = includeDetails
    self.statusFilter = statusFilter
  }
}

/**
 Operation for getting repository details
 */
public struct GetRepositoryOperation: RepositoryAPIOperation, Sendable {
  public let repositoryID: String
  public let includeSnapshots: Bool
  
  public init(repositoryID: String, includeSnapshots: Bool = false) {
    self.repositoryID = repositoryID
    self.includeSnapshots = includeSnapshots
  }
}

/**
 Parameters for creating a repository
 */
public struct CreateRepositoryParameters: Sendable {
  public let name: String
  public let location: URL
  public let options: [String: String]
  
  public init(name: String, location: URL, options: [String: String] = [:]) {
    self.name = name
    self.location = location
    self.options = options
  }
}

/**
 Operation for creating a repository
 */
public struct CreateRepositoryOperation: RepositoryAPIOperation, Sendable {
  public let parameters: CreateRepositoryParameters
  
  public init(parameters: CreateRepositoryParameters) {
    self.parameters = parameters
  }
}

/**
 Operation for updating a repository
 */
public struct UpdateRepositoryOperation: RepositoryAPIOperation, Sendable {
  public let repositoryID: String
  public let updates: [String: SendableValue]
  
  public init(repositoryID: String, updates: [String: SendableValue]) {
    self.repositoryID = repositoryID
    self.updates = updates
  }
}

/**
 Operation for deleting a repository
 */
public struct DeleteRepositoryOperation: RepositoryAPIOperation, Sendable {
  public let repositoryID: String
  public let force: Bool
  
  public init(repositoryID: String, force: Bool = false) {
    self.repositoryID = repositoryID
    self.force = force
  }
}

/**
 Repository information data structure
 */
public struct RepositoryInfo: Sendable {
  public let id: String
  public let name: String
  public let status: RepositoryStatus
  public let creationDate: Date
  public let lastAccessDate: Date?
  
  public init(id: String, name: String, status: RepositoryStatus, creationDate: Date, lastAccessDate: Date?) {
    self.id = id
    self.name = name
    self.status = status
    self.creationDate = creationDate
    self.lastAccessDate = lastAccessDate
  }
}

/**
 Detailed repository information
 */
public struct RepositoryDetails: Codable, Sendable {
  public let id: String
  public let name: String
  public let status: RepositoryStatus
  public let creationDate: Date
  public let lastAccessDate: Date?
  public let snapshotCount: Int
  public let totalSize: Int
  public let location: String
  
  public init(
    id: String, 
    name: String, 
    status: RepositoryStatus, 
    creationDate: Date, 
    lastAccessDate: Date?, 
    snapshotCount: Int, 
    totalSize: Int, 
    location: String
  ) {
    self.id = id
    self.name = name
    self.status = status
    self.creationDate = creationDate
    self.lastAccessDate = lastAccessDate
    self.snapshotCount = snapshotCount
    self.totalSize = totalSize
    self.location = location
  }
}
