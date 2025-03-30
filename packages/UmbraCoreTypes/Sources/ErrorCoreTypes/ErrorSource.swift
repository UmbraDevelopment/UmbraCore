import Foundation

/**
 # ErrorSource
 
 Provides location information about where an error occurred.
 
 ErrorSource captures file, function, and line information to help with
 debugging and to provide context for error handling and logging.
 */
public struct ErrorSource: Sendable, Equatable {
    /// File where the error occurred
    public let file: String
    
    /// Function where the error occurred
    public let function: String
    
    /// Line number where the error occurred
    public let line: Int
    
    /**
     Initialises a new error source with the specified location information.
     
     - Parameters:
        - file: File path where the error occurred
        - function: Function name where the error occurred
        - line: Line number where the error occurred
     */
    public init(
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        self.file = file
        self.function = function
        self.line = line
    }
    
    /**
     Returns a string representation of the source location.
     
     The format is: [filename:line function]
     */
    public var description: String {
        let filename = URL(fileURLWithPath: file).lastPathComponent
        return "[\(filename):\(line) \(function)]"
    }
}
