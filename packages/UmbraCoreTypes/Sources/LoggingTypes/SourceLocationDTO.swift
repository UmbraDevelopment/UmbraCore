import Foundation

/// Represents the source location of a log entry
///
/// This DTO provides information about the file, function, and line
/// where a log entry was created, enabling better debugging and tracing.
public struct SourceLocationDTO: Sendable, Equatable, Hashable, Codable {
    /// The source file path
    public let file: String
    
    /// The function or method name
    public let function: String
    
    /// The line number
    public let line: UInt
    
    /// Creates a new source location DTO
    ///
    /// - Parameters:
    ///   - file: The source file path
    ///   - function: The function or method name
    ///   - line: The line number
    public init(file: String, function: String, line: UInt) {
        self.file = file
        self.function = function
        self.line = line
    }
    
    /// Creates a source location using file, function and line parameters
    /// from the Swift compiler
    ///
    /// - Parameters:
    ///   - file: The source file path (typically #file)
    ///   - function: The function name (typically #function)
    ///   - line: The line number (typically #line)
    /// - Returns: A source location DTO
    public static func capture(
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) -> SourceLocationDTO {
        return SourceLocationDTO(
            file: file,
            function: function,
            line: line
        )
    }
    
    /// Returns a string representation of this source location
    public var description: String {
        return "\(file):\(function):\(line)"
    }
}
