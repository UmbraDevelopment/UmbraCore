import Foundation
import UmbraCryptoService
import UmbraXPC
import XPCProtocolsCore

// A test double for CryptoXPCService to use in tests
class MockCryptoXPCService: CryptoXPCServiceInterface {
  // For tracking method calls
  var encryptCallCount=0
  var decryptCallCount=0
  var generateKeyCallCount=0
  var generateRandomDataCallCount=0
  var storeKeyCallCount=0
  var retrieveKeyCallCount=0

  // For controlling test responses
  var mockEncryptResult: (Data?, Error?)=(nil, nil)
  var mockDecryptResult: (Data?, Error?)=(nil, nil)
  var mockGenerateKeyResult: (Data?, Error?)=(nil, nil)
  var mockGenerateRandomDataResult: (Data?, Error?)=(nil, nil)
  var mockStoreKeyResult: (Bool, Error?)=(false, nil)
  var mockRetrieveKeyResult: (Data?, Error?)=(nil, nil)

  // Dictionary to simulate keychain storage
  private var storedKeys: [String: Data]=[:]

  // Flag to control whether to use real random data generation
  var useRealRandomData=true

  // For real implementations
  private func generateRandomBytes(count: Int) -> [UInt8] {
    var bytes=[UInt8](repeating: 0, count: count)
    _=SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
    return bytes
  }

  // No need for init now that we're not inheriting
  init() {}

  func encrypt(_ data: Data, key _: Data, completion: @escaping (Data?, Error?) -> Void) {
    encryptCallCount += 1

    if mockEncryptResult.0 != nil || mockEncryptResult.1 != nil {
      completion(mockEncryptResult.0, mockEncryptResult.1)
      return
    }

    // Simple encryption for testing
    var encryptedData=Data()
    // Add 16 bytes of "IV" for testing
    encryptedData.append(Data(generateRandomBytes(count: 16)))
    // Append the original data - not real encryption, just for testing
    encryptedData.append(data)
    completion(encryptedData, nil)
  }

  func decrypt(_ data: Data, key _: Data, completion: @escaping (Data?, Error?) -> Void) {
    decryptCallCount += 1

    if mockDecryptResult.0 != nil || mockDecryptResult.1 != nil {
      completion(mockDecryptResult.0, mockDecryptResult.1)
      return
    }

    // Simple decryption for testing
    if data.count <= 16 {
      let error=NSError(
        domain: "ErrorHandlingDomains.UmbraErrors.Security.Protocols",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Invalid data length"]
      )
      completion(nil, error)
      return
    }

    // Skip the first 16 bytes (simulated IV)
    let decryptedData=data.subdata(in: 16..<data.count)
    completion(decryptedData, nil)
  }

  func generateKey(bits: Int, completion: @escaping (Data?, Error?) -> Void) {
    generateKeyCallCount += 1

    if mockGenerateKeyResult.0 != nil || mockGenerateKeyResult.1 != nil {
      completion(mockGenerateKeyResult.0, mockGenerateKeyResult.1)
      return
    }

    // Simple key generation
    let bytes=bits / 8
    let keyData=Data(generateRandomBytes(count: bytes))
    completion(keyData, nil)
  }

  func generateRandomData(length: Int, completion: @escaping (Data?, Error?) -> Void) {
    generateRandomDataCallCount += 1

    if mockGenerateRandomDataResult.0 != nil || mockGenerateRandomDataResult.1 != nil {
      completion(mockGenerateRandomDataResult.0, mockGenerateRandomDataResult.1)
      return
    }

    if useRealRandomData {
      let randomData=Data(generateRandomBytes(count: length))
      completion(randomData, nil)
    } else {
      // Use predictable "random" data for testing
      var predictableData=Data(repeating: 0xAA, count: length)
      // Add some variation to make each call unique
      if let firstByte=predictableData.first, let lastByte=predictableData.last {
        predictableData[0]=firstByte + UInt8(generateRandomDataCallCount)
        predictableData[predictableData.count - 1]=lastByte + UInt8(generateRandomDataCallCount)
      }
      completion(predictableData, nil)
    }
  }

  func storeKey(_ key: Data, identifier: String, completion: @escaping (Bool, Error?) -> Void) {
    storeKeyCallCount += 1

    if mockStoreKeyResult.1 != nil {
      completion(mockStoreKeyResult.0, mockStoreKeyResult.1)
      return
    }

    // Store the key in our mock storage
    storedKeys[identifier]=key
    completion(true, nil)
  }

  func retrieveKey(identifier: String, completion: @escaping (Data?, Error?) -> Void) {
    retrieveKeyCallCount += 1

    if mockRetrieveKeyResult.0 != nil || mockRetrieveKeyResult.1 != nil {
      completion(mockRetrieveKeyResult.0, mockRetrieveKeyResult.1)
      return
    }

    // Retrieve the key from our mock storage
    let keyData=storedKeys[identifier]
    completion(keyData, nil)
  }
}
