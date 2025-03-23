import Foundation

/// Basic error source information
public struct ErrorSource: Sendable, Equatable, Codable {
  /// The file where the error occurred
  public let file: String

  /// The function where the error occurred
  public let function: String

  /// The line where the error occurred
  public let line: Int

  /// Initialize a new error source
  /// - Parameters:
  ///   - file: The file where the error occurred
  ///   - function: The function where the error occurred
  ///   - line: The line where the error occurred
  public init(file: String=#file, function: String=#function, line: Int=#line) {
    self.file=file
    self.function=function
    self.line=line
  }

  /// A shortened version of the file path, showing only the file name
  public var shortFile: String {
    URL(fileURLWithPath: file).lastPathComponent
  }
}

/// Basic interface for error categories
public protocol ErrorCategory {
  /// The category identifier
  var rawValue: String { get }

  /// The category description
  var description: String { get }
}

/// Basic interface for error domains
public protocol ErrorDomain {
  /// The domain identifier
  static var identifier: String { get }

  /// The domain name
  static var name: String { get }

  /// The domain description
  static var description: String { get }
}
