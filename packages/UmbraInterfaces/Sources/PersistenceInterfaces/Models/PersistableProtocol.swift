import Foundation

/**
 Protocol defining requirements for objects that can be persisted.
 
 Any model that needs to be stored in the persistence layer must conform
 to this protocol to ensure it has the necessary identification and metadata.
 */
public protocol Persistable: Codable, Identifiable, Equatable {
    /// The unique identifier for the persistable object
    var id: String { get }
    
    /// The type identifier for the persistable object (typically the class/struct name)
    static var typeIdentifier: String { get }
    
    /// Creation timestamp of the persistable object
    var createdAt: Date { get }
    
    /// Last modification timestamp of the persistable object
    var updatedAt: Date { get }
    
    /// Optional version number for optimistic concurrency control
    var version: Int { get }
    
    /// Optional metadata associated with the object
    var metadata: [String: String] { get set }
}

/// Default implementation for common properties
public extension Persistable {
    /// Default type identifier based on the type name
    static var typeIdentifier: String {
        String(describing: Self.self)
    }
    
    /// Default equality check based on ID
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
