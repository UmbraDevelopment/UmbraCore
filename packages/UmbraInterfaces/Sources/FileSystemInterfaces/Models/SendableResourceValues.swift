import Foundation

/**
 # Sendable Resource Values
 
 A Swift 6-compatible wrapper for URL resource values that
 preserves type information while conforming to Sendable.
 
 This replaces the non-Sendable [URLResourceKey: Any] dictionary
 with a type-safe wrapper that conforms to the Sendable protocol.
 
 ## Alpha Dot Five Architecture
 
 This type follows the Alpha Dot Five architecture principles:
 - Uses immutable struct for thread safety
 - Explicitly implements Sendable for concurrency safety
 - Provides type-safe access to resource values
 - Uses British spelling in documentation
 */
public struct SendableResourceValues: Sendable, Equatable {
    /// The underlying storage for the resource values
    private let storage: [URLResourceKey: SendableValue]
    
    /// Creates a new instance with the specified resource values
    /// - Parameter values: The resource values to store
    public init(values: [URLResourceKey: Any]? = nil) {
        var storage: [URLResourceKey: SendableValue] = [:]
        
        if let values = values {
            for (key, value) in values {
                if let stringValue = value as? String {
                    storage[key] = .string(stringValue)
                } else if let boolValue = value as? Bool {
                    storage[key] = .bool(boolValue)
                } else if let intValue = value as? Int {
                    storage[key] = .int(intValue)
                } else if let doubleValue = value as? Double {
                    storage[key] = .double(doubleValue)
                } else if let dateValue = value as? Date {
                    storage[key] = .date(dateValue)
                } else if let dataValue = value as? Data {
                    storage[key] = .data(dataValue)
                } else if let urlValue = value as? URL {
                    storage[key] = .url(urlValue)
                } else {
                    // For any other type, we'll use its string description
                    storage[key] = .string(String(describing: value))
                }
            }
        }
        
        self.storage = storage
    }
    
    /// Get a value for a specific resource key
    /// - Parameter key: The resource key
    /// - Returns: The value, if it exists
    public func value(for key: URLResourceKey) -> Any? {
        guard let wrappedValue = storage[key] else {
            return nil
        }
        
        switch wrappedValue {
        case .string(let value): return value
        case .bool(let value): return value
        case .int(let value): return value
        case .double(let value): return value
        case .date(let value): return value
        case .data(let value): return value
        case .url(let value): return value
        }
    }
    
    /// Get a strongly typed value for a specific resource key
    /// - Parameter key: The resource key
    /// - Returns: The value if it exists and matches the expected type
    public func value<T>(for key: URLResourceKey, as type: T.Type = T.self) -> T? {
        return value(for: key) as? T
    }
    
    /// Get all the keys in the resource values
    public var keys: [URLResourceKey] {
        return Array(storage.keys)
    }
    
    /// Check if the resource values contain a specific key
    public func contains(key: URLResourceKey) -> Bool {
        return storage[key] != nil
    }
    
    /// Count of resource values
    public var count: Int {
        return storage.count
    }
    
    /// Whether there are no resource values
    public var isEmpty: Bool {
        return storage.isEmpty
    }
    
    /// Convert to a dictionary with Any values
    /// - Returns: A dictionary with the same keys and values
    public func toDictionary() -> [URLResourceKey: Any] {
        var result: [URLResourceKey: Any] = [:]
        
        for (key, wrappedValue) in storage {
            switch wrappedValue {
            case .string(let value): result[key] = value
            case .bool(let value): result[key] = value
            case .int(let value): result[key] = value
            case .double(let value): result[key] = value
            case .date(let value): result[key] = value
            case .data(let value): result[key] = value
            case .url(let value): result[key] = value
            }
        }
        
        return result
    }
    
    /// A type-safe wrapper for values that can be stored in resource values
    private enum SendableValue: Sendable, Equatable {
        case string(String)
        case bool(Bool)
        case int(Int)
        case double(Double)
        case date(Date)
        case data(Data)
        case url(URL)
    }
}
