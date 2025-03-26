import CoreDTOs
import Foundation
import SecurityBridgeTypes
import UmbraCoreTypes
import UmbraSecurity

/// Example demonstrating the use of Foundation-independent DTOs with UmbraSecurity
import FileSystemTypes
final class FoundationIndependentExample {
  // MARK: - Properties

  /// Security service adapter
  private let securityService: SecurityServiceDTOAdapter

  /// Bookmark service adapter
  private let bookmarkService: BookmarkServiceDTOAdapter

  // MARK: - Initialization

  /// Initialize the example
  init() {
    // Create the service adapters using the factory
    let services=SecurityServiceDTOFactory.createComplete()
    securityService=services.security
    bookmarkService=services.bookmarks
  }

  // MARK: - Examples

  /// Run the example
  func run() {
    print("Running Foundation-independent security examples...")

    // 1. Generate random bytes
    generateRandomBytesExample()

    // 2. Hash data with different algorithms
    hashDataExample()

    // 3. Encrypt and decrypt data
    encryptionExample()

    // 4. Work with bookmarks
    bookmarkExample()
  }

  /// Example of generating random bytes
  private func generateRandomBytesExample() {
    print("\n--- Random Bytes Example ---")

    // Generate 32 random bytes (Foundation-independent)
    let randomBytesResult=securityService.generateRandomBytes(count: 32)

    switch randomBytesResult {
      case let .success(bytes):
        print("✅ Generated \(bytes.count) random bytes successfully")

        // Convert to hex for display
        let hexString=bytes.map { String(format: "%02x", $0) }.joined()
        print("Bytes (hex): \(hexString)")

        // Generate a secure token (Foundation-independent)
        let tokenResult=securityService.generateSecureToken(byteCount: 16)
        switch tokenResult {
          case let .success(token):
            print("✅ Generated secure token: \(token)")
          case let .failure(error):
            print("❌ Failed to generate token: \(error.error.message)")
        }

      case let .failure(error):
        print("❌ Failed to generate random bytes: \(error.error.message)")
    }
  }

  /// Example of hashing data with different algorithms
  private func hashDataExample() {
    print("\n--- Hashing Example ---")

    // Sample data to hash (Foundation-independent)
    let sampleData: [UInt8]=Array("Hello, Foundation-independent world!".utf8)

    // Hash algorithms to test
    let algorithms=["sha1", "sha256", "sha512", "md5"]

    for algorithm in algorithms {
      // Create configuration with the algorithm (Foundation-independent)
      let config=SecurityConfigDTO(
        algorithm: algorithm,
        options: ["algorithm": algorithm]
      )

      // Hash the data (Foundation-independent)
      let hashResult=securityService.hashData(sampleData, config: config)

      switch hashResult {
        case let .success(hash):
          // Convert hash to hex for display
          let hexString=hash.map { String(format: "%02x", $0) }.joined()
          print("✅ \(algorithm.uppercased()) hash: \(hexString)")

        case let .failure(error):
          print("❌ Failed to hash with \(algorithm): \(error.error.message)")
      }
    }
  }

  /// Example of encrypting and decrypting data
  private func encryptionExample() {
    print("\n--- Encryption Example ---")

    // Sample data to encrypt (Foundation-independent)
    let originalData: [UInt8]=Array("Sensitive data that needs protection".utf8)
    print("Original data: \(String(bytes: originalData, encoding: .utf8) ?? "invalid")")

    // Generate a key for encryption (Foundation-independent)
    let keyResult=securityService.generateRandomBytes(count: 32)

    switch keyResult {
      case let .success(key):
        // Basic encryption configuration (Foundation-independent)
        let config=SecurityConfigDTO(
          algorithm: "aes",
          options: ["mode": "gcm"]
        )

        // Encrypt the data (Foundation-independent)
        let encryptResult=securityService.encrypt(originalData, key: key, config: config)

        switch encryptResult {
          case let .success(encryptedData):
            print("✅ Encrypted data length: \(encryptedData.count) bytes")

            // Decrypt the data (Foundation-independent)
            let decryptResult=securityService.decrypt(encryptedData, key: key, config: config)

            switch decryptResult {
              case let .success(decryptedData):
                let decryptedString=String(bytes: decryptedData, encoding: .utf8) ?? "invalid"
                print("✅ Decrypted data: \(decryptedString)")

                // Verify the decrypted data matches the original
                let isMatch=decryptedData == originalData
                print("Decryption successful: \(isMatch ? "✅ Yes" : "❌ No")")

              case let .failure(error):
                print("❌ Failed to decrypt: \(error.error.message)")
            }

          case let .failure(error):
            print("❌ Failed to encrypt: \(error.error.message)")
        }

      case let .failure(error):
        print("❌ Failed to generate key: \(error.error.message)")
    }
  }

  /// Example of working with bookmarks
  private func bookmarkExample() {
    print("\n--- Bookmark Example ---")

    // Get a path to the Documents directory (Foundation-independent)
    let documentsPath=FilePathDTO.documentsDirectory()
    print("Documents directory: \(documentsPath.path)")

    // Create a path for a file (Foundation-independent)
    let filePath=documentsPath.appendingComponent("example.txt")
    print("File path: \(filePath.path)")

    // Create a bookmark for the file (Foundation-independent)
    let bookmarkResult=bookmarkService.createBookmark(for: filePath)

    switch bookmarkResult {
      case let .success(bookmark):
        print("✅ Created bookmark for \(bookmark.displayPath)")
        print("Bookmark data size: \(bookmark.data.count) bytes")

        // Resolve the bookmark (Foundation-independent)
        let resolveResult=bookmarkService.resolveBookmark(bookmark)

        switch resolveResult {
          case .success(let (resolvedPath, wasStale)):
            print("✅ Resolved to: \(resolvedPath.path)")
            print("Was stale: \(wasStale ? "Yes" : "No")")

            // Start accessing the resource (Foundation-independent)
            let startResult=bookmarkService.startAccessing(resolvedPath)

            switch startResult {
              case let .success(success):
                print("✅ Started accessing resource: \(success ? "Success" : "Failed")")

                // Stop accessing the resource (Foundation-independent)
                let stopResult=bookmarkService.stopAccessing(resolvedPath)

                switch stopResult {
                  case .success:
                    print("✅ Stopped accessing resource")
                  case let .failure(error):
                    print("❌ Failed to stop accessing: \(error.error.message)")
                }

              case let .failure(error):
                print("❌ Failed to start accessing: \(error.error.message)")
            }

          case let .failure(error):
            print("❌ Failed to resolve bookmark: \(error.error.message)")
        }

      case let .failure(error):
        print("❌ Failed to create bookmark: \(error.error.message)")
    }
  }
}

// Example usage:
// let example = FoundationIndependentExample()
// example.run()
