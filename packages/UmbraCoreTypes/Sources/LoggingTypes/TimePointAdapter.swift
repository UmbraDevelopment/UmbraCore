#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

/// A Foundation-free time representation for logging
public struct TimePointAdapter: Sendable, Equatable, Hashable, Comparable, Codable {
  /// The time interval since January 1, 1970 at 00:00:00 UTC
  public let timeIntervalSince1970: Double
  
  /// Create a new time adapter with the current time
  public init() {
    self.timeIntervalSince1970 = TimePointAdapter.currentTimeIntervalSince1970()
  }
  
  /// Create a new time adapter with a specific time interval
  /// - Parameter timeIntervalSince1970: Time interval since 1970
  public init(timeIntervalSince1970: Double) {
    self.timeIntervalSince1970 = timeIntervalSince1970
  }
  
  /// Create a TimePointAdapter representing the current time
  public static func now() -> TimePointAdapter {
    TimePointAdapter(timeIntervalSince1970: currentTimeIntervalSince1970())
  }
  
  /// Get the current time interval since 1970
  /// - Returns: The current time interval
  private static func currentTimeIntervalSince1970() -> Double {
    // Using a simple time calculation that doesn't require Foundation
    return Double(time(nil))
  }
  
  /// Compare two time points
  public static func < (lhs: TimePointAdapter, rhs: TimePointAdapter) -> Bool {
    lhs.timeIntervalSince1970 < rhs.timeIntervalSince1970
  }

  /// Get a string description of the timestamp
  public var description: String {
    // Format the timestamp as a simple string without Foundation
    // Format: "YYYY-MM-DD HH:MM:SS"
    let totalSeconds = Int(timeIntervalSince1970)
    
    let seconds = totalSeconds % 60
    let minutes = (totalSeconds / 60) % 60
    let hours = (totalSeconds / 3600) % 24
    
    let days = totalSeconds / 86400
    let epochDate = 719163 // Days from year 0 to 1970-01-01
    let (year, month, day) = TimePointAdapter.getDateComponents(daysSinceEpoch: days + epochDate)
    
    return String(format: "%04d-%02d-%02d %02d:%02d:%02d", 
                  year, month, day, hours, minutes, seconds)
  }
  
  /// Convert days since epoch to year, month, day components
  /// - Parameter daysSinceEpoch: Days since epoch (starting from year 0)
  /// - Returns: Tuple of (year, month, day)
  private static func getDateComponents(daysSinceEpoch: Int) -> (Int, Int, Int) {
    // Basic date calculation algorithm
    // Note: This is a simplified version and doesn't handle all edge cases
    var remainingDays = daysSinceEpoch
    
    // Approximate year
    var year = remainingDays / 365
    
    // Adjust for leap years
    let leapYears = year / 4 - year / 100 + year / 400
    remainingDays -= year * 365 + leapYears
    
    // Correction if we went too far
    if remainingDays < 0 {
      year -= 1
      remainingDays += 365 + (TimePointAdapter.isLeapYear(year: year) ? 1 : 0)
    }
    
    // Month calculation
    let daysInMonth = TimePointAdapter.getDaysInMonth(year: year)
    var month = 1
    
    while month <= 12 && remainingDays >= daysInMonth[month - 1] {
      remainingDays -= daysInMonth[month - 1]
      month += 1
    }
    
    // Day calculation (add 1 because days are 1-based)
    let day = remainingDays + 1
    
    return (year, month, day)
  }
  
  /// Check if a year is a leap year
  /// - Parameter year: Year to check
  /// - Returns: True if leap year
  private static func isLeapYear(year: Int) -> Bool {
    (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
  }
  
  /// Get days in each month for a specific year
  /// - Parameter year: Year to get days for
  /// - Returns: Array of days in each month
  private static func getDaysInMonth(year: Int) -> [Int] {
    let febDays = isLeapYear(year: year) ? 29 : 28
    return [31, febDays, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  }
}
