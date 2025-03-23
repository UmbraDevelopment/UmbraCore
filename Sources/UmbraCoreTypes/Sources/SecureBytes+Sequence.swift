import Foundation

// Extension to make SecureBytes conform to Sequence protocol
extension SecureBytes: Sequence {
  public typealias Element=UInt8
  public typealias Iterator=SecureBytesIterator

  public func makeIterator() -> SecureBytesIterator {
    SecureBytesIterator(bytes: self)
  }
}

// Iterator for SecureBytes
public struct SecureBytesIterator: IteratorProtocol {
  public typealias Element=UInt8

  private let bytes: SecureBytes
  private var index: Int=0

  init(bytes: SecureBytes) {
    self.bytes=bytes
  }

  public mutating func next() -> UInt8? {
    guard index < bytes.count else {
      return nil
    }

    let element=bytes[index]
    index += 1
    return element
  }
}

// Extension to add prefix and dropFirst functionality
extension SecureBytes {
  public func prefix(_ maxLength: Int) -> [UInt8] {
    let count=Swift.min(count, maxLength)
    var result=[UInt8]()
    result.reserveCapacity(count)

    for i in 0..<count {
      result.append(self[i])
    }

    return result
  }

  public func dropFirst(_ n: Int=1) -> [UInt8] {
    guard n < count else {
      return []
    }

    var result=[UInt8]()
    result.reserveCapacity(count - n)

    for i in n..<count {
      result.append(self[i])
    }

    return result
  }
}
