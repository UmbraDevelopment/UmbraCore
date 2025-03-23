import Foundation

// Interface that matches CryptoXPCService's public methods
protocol CryptoXPCServiceInterface {
  func encrypt(_ data: Data, key: Data, completion: @escaping (Data?, Error?) -> Void)
  func decrypt(_ data: Data, key: Data, completion: @escaping (Data?, Error?) -> Void)
  func generateKey(bits: Int, completion: @escaping (Data?, Error?) -> Void)
  func generateRandomData(length: Int, completion: @escaping (Data?, Error?) -> Void)
  func storeKey(_ key: Data, identifier: String, completion: @escaping (Bool, Error?) -> Void)
  func retrieveKey(identifier: String, completion: @escaping (Data?, Error?) -> Void)
}
