import CoreErrors
import CryptoTypesProtocols
import Foundation

/// Mock implementation of CryptoService for testing
@objc
public final class MockCryptoService: NSObject, @unchecked Sendable, CryptoServiceProtocol {
  private let keysLock=NSLock()
  private var keysDict: [String: Data]=[:]

  public override init() {
    super.init()
  }

  /// Mock implementation of generateSecureRandomKey
  public func generateSecureRandomKey(length: Int) async throws -> Data {
    // Return a predictable pattern of bytes for testing
    Data(repeating: 0xA5, count: length)
  }

  /// Mock implementation of encrypt
  public func encrypt(_ data: Data, using key: Data, iv: Data) async throws -> Data {
    // Simple mock encryption - just append the key and IV for verification
    var encrypted=Data()
    encrypted.append(data)
    encrypted.append(iv)
    encrypted.append(key)
    return encrypted
  }

  /// Mock implementation of decrypt
  public func decrypt(_ data: Data, using key: Data, iv: Data) async throws -> Data {
    // Check if this is data we "encrypted"
    if data.count > (key.count + iv.count) {
      return data.subdata(in: 0..<(data.count - key.count - iv.count))
    }

    // If not our encrypted data, just return it as is
    return data
  }

  /// Mock implementation of deriveKey
  public func deriveKey(from password: String, salt: Data, iterations: Int) async throws -> Data {
    // Create a deterministic "key" from the inputs
    guard let passwordData=password.data(using: .utf8) else {
      throw CoreErrors.CryptoError.invalidKey(reason: "Invalid password encoding")
    }

    var combined=passwordData
    combined.append(salt)
    let iterData=withUnsafeBytes(of: iterations) { Data($0) }
    combined.append(iterData)

    // Return a hash-like result
    return combined.prefix(32)
  }

  /// Mock implementation of generateHMAC
  public func generateHMAC(for data: Data, using key: Data) async throws -> Data {
    // Simply combine the data and key for a predictable result
    var hmac=Data()
    hmac.append(data)
    hmac.append(key)
    return hmac.prefix(32) // Return a fixed size HMAC
  }
}
