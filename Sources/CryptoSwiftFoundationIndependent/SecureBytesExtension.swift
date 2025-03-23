import UmbraCoreTypes

// MARK: - SecureBytes Extension

// Provides backwards compatibility for the UmbraCoreTypes.SecureBytes class

extension SecureBytes {
  /// Returns the raw bytes contained in the SecureBytes instance
  /// This method provides backwards compatibility for code that used to call bytes()
  public func bytes() -> [UInt8] {
    // Create a copy of the internal byte array
    var result = [UInt8](repeating: 0, count: count)
    for i in 0..<count {
      result[i] = self[i]
    }
    return result
  }
}
