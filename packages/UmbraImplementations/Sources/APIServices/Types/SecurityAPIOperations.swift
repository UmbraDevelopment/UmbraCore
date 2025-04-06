import Foundation
import APIInterfaces
import CryptoTypes

/**
 Protocol defining a security-related API operation
 */
public protocol SecurityAPIOperation: APIOperation {}

/**
 Operation for encrypting data
 */
public struct EncryptData: SecurityAPIOperation, Sendable {
  public let data: Data
  public let key: SendableCryptoMaterial?
  public let algorithm: String?
  
  public init(data: Data, key: SendableCryptoMaterial? = nil, algorithm: String? = nil) {
    self.data = data
    self.key = key
    self.algorithm = algorithm
  }
}

/**
 Operation for decrypting data
 */
public struct DecryptData: SecurityAPIOperation, Sendable {
  public let encryptedData: Data
  public let key: SendableCryptoMaterial?
  public let algorithm: String?
  
  public init(encryptedData: Data, key: SendableCryptoMaterial? = nil, algorithm: String? = nil) {
    self.encryptedData = encryptedData
    self.key = key
    self.algorithm = algorithm
  }
}

/**
 Operation for generating a cryptographic key
 */
public struct GenerateKey: SecurityAPIOperation, Sendable {
  public let keyType: String
  public let keySize: Int?
  public let algorithm: String?
  public let persistent: Bool
  public let identifier: String?
  
  public init(
    keyType: String,
    keySize: Int? = nil,
    algorithm: String? = nil,
    persistent: Bool = false,
    identifier: String? = nil
  ) {
    self.keyType = keyType
    self.keySize = keySize
    self.algorithm = algorithm
    self.persistent = persistent
    self.identifier = identifier
  }
}

/**
 Operation for retrieving a cryptographic key
 */
public struct RetrieveKey: SecurityAPIOperation, Sendable {
  public let identifier: String
  
  public init(identifier: String) {
    self.identifier = identifier
  }
}

/**
 Operation for storing a cryptographic key
 */
public struct StoreKey: SecurityAPIOperation, Sendable {
  public let key: SendableCryptoMaterial
  public let identifier: String?
  
  public init(key: SendableCryptoMaterial, identifier: String? = nil) {
    self.key = key
    self.identifier = identifier
  }
}

/**
 Operation for deleting a cryptographic key
 */
public struct DeleteKey: SecurityAPIOperation, Sendable {
  public let identifier: String
  
  public init(identifier: String) {
    self.identifier = identifier
  }
}

/**
 Operation for computing a hash
 */
public struct HashData: SecurityAPIOperation, Sendable {
  public let data: Data
  public let algorithm: String?
  
  public init(data: Data, algorithm: String? = nil) {
    self.data = data
    self.algorithm = algorithm
  }
}

/**
 Operation for storing a secret
 */
public struct StoreSecret: SecurityAPIOperation, Sendable {
  public let secret: SendableCryptoMaterial
  public let identifier: String?
  
  public init(secret: SendableCryptoMaterial, identifier: String? = nil) {
    self.secret = secret
    self.identifier = identifier
  }
}

/**
 Operation for retrieving a secret
 */
public struct RetrieveSecret: SecurityAPIOperation, Sendable {
  public let identifier: String
  
  public init(identifier: String) {
    self.identifier = identifier
  }
}

/**
 Operation for deleting a secret
 */
public struct DeleteSecret: SecurityAPIOperation, Sendable {
  public let identifier: String
  
  public init(identifier: String) {
    self.identifier = identifier
  }
}
