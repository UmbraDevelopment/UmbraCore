import UmbraCoreTypes_CoreErrors

/// Extension to provide utility methods for SecureBytes
extension SecureBytes {
  /// Combines two or more SecureBytes instances into a single instance
  /// - Parameters:
  ///   - first: The first SecureBytes
  ///   - second: The second SecureBytes
  ///   - additional: Additional SecureBytes to combine
  /// - Returns: A new SecureBytes instance containing all the bytes from the provided instances
  public static func combine(
    _ first: SecureBytes,
    _ second: SecureBytes,
    _ additional: SecureBytes...
  ) -> SecureBytes {
    var combined=[UInt8]()

    // Since we can't access private storage directly, we'll convert to array and access elements
    for i in 0..<first.count {
      combined.append(first[i])
    }

    for i in 0..<second.count {
      combined.append(second[i])
    }

    for bytes in additional {
      for i in 0..<bytes.count {
        combined.append(bytes[i])
      }
    }

    return SecureBytes(bytes: combined)
  }

  /// Splits the SecureBytes at the specified position
  /// - Parameter at: Position at which to split the bytes
  /// - Returns: A tuple containing the bytes before and after the split point
  /// - Throws: SecureBytesError.outOfBounds if the split position is out of bounds
  public func split(at position: Int) throws -> (SecureBytes, SecureBytes) {
    guard position >= 0, position <= count else {
      throw SecureBytesError.outOfBounds
    }

    var firstPart=[UInt8]()
    var secondPart=[UInt8]()

    for i in 0..<position {
      firstPart.append(self[i])
    }

    for i in position..<count {
      secondPart.append(self[i])
    }

    return (SecureBytes(bytes: firstPart), SecureBytes(bytes: secondPart))
  }

  /// Converts SecureBytes to an array of UInt8
  /// - Returns: Array of UInt8 bytes
  public func toArray() -> [UInt8] {
    var result=[UInt8]()
    for i in 0..<count {
      result.append(self[i])
    }
    return result
  }
}
