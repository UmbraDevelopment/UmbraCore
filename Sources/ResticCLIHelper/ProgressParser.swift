import Foundation
import ResticTypes

/// Parses progress information from Restic JSON output.
/// This class is responsible for:
/// - Parsing JSON output from Restic commands
/// - Decoding progress information into strongly typed models
/// - Reporting progress updates through a delegate
final class ProgressParser {
  private let decoder=JSONDecoder()
  public private(set) var delegate: ResticProgressReporting

  /// Creates a new progress parser with the specified delegate.
  /// - Parameter delegate: The object that will receive progress updates
  public init(delegate: ResticProgressReporting) {
    self.delegate=delegate
  }

  /// Parses a line of output from Restic.
  /// - Parameter line: A line of output from Restic, expected to be JSON-formatted
  /// - Returns: true if the line was successfully parsed as progress information,
  ///           false if the line was empty or not valid progress JSON
  public func parseLine(_ line: String) -> Bool {
    guard !line.isEmpty else { return false }

    guard let data=line.data(using: .utf8) else {
      return false
    }

    do {
      let progress=try decoder.decode(BackupProgress.self, from: data)
      delegate.progressUpdated(progress)
      return true
    } catch {
      do {
        let progress=try decoder.decode(RestoreProgress.self, from: data)
        delegate.progressUpdated(progress)
        return true
      } catch {
        return false
      }
    }
  }
}
