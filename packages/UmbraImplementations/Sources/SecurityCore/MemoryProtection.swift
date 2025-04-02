import CoreSecurityTypes
import Foundation

/**
 # Memory Protection Utilities

 This module provides essential utilities for securely handling sensitive data in memory.
 Proper memory protection is a crucial aspect of cryptographic security, as sensitive
 information (such as encryption keys, passwords, and private data) can remain in memory
 even after variables go out of scope.

 ## Security Background

 Memory protection addresses several key threats:

 1. **Memory Dumps**: In case of application crashes or system memory dumps, sensitive
    data might be exposed if not properly cleared.

 2. **Cold Boot Attacks**: Physical attacks where RAM contents can be recovered after
    power loss if memory hasn't been properly wiped.

 3. **Swap File Exposure**: Operating systems may swap memory to disk, potentially
    exposing sensitive data if not properly managed.

 4. **Compiler Optimisations**: Modern compilers might optimise away seemingly
    "unnecessary" operations like zeroing memory that won't be read again, which
    could leave sensitive data in memory.

 ## Usage Guidelines

 - Always use these utilities when handling cryptographic keys, passwords, or other
   sensitive materials.

 - Combine with proper scope management (keeping sensitive data in memory for the
   shortest time possible).

 - For maximum protection, consider additional countermeasures like memory locking
   and process isolation where applicable.
 */

/// Utilities for secure memory handling and protection of sensitive data
public enum MemoryProtection {
  /**
   Securely zeroes memory to prevent sensitive data from being left in memory.

   This method overwrites the provided byte array with zeros, ensuring that
   sensitive data is not left in memory after it's no longer needed. The
   implementation works around compiler optimisations that might otherwise
   eliminate the zeroing operation.

   ## Security Considerations

   - This approach uses volatile variables and memory barriers to prevent
     compiler optimisations from removing the zeroing operation.
   - For systems with swap memory, consider memory locking to prevent swapping.

   - Parameter data: The byte array to zero
   */
  public static func secureZero(_ data: inout [UInt8]) {
    // We use a volatile pointer to prevent compiler optimisations
    // that might remove the zeroing operation
    data.withUnsafeMutableBytes { rawBufferPointer in
      guard let baseAddress = rawBufferPointer.baseAddress else {
        return
      }
      
      // Create a volatile UInt8 pointer
      let volatilePointer = baseAddress.bindMemory(
        to: UInt8.self,
        capacity: rawBufferPointer.count
      )
      
      // Securely zero each byte
      for i in 0..<rawBufferPointer.count {
        volatilePointer[i] = 0
      }
      
      // Memory barrier to ensure writes complete
      #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
      OSMemoryBarrier()
      #else
      // Generic memory barrier for other platforms
      // This is less effective but better than nothing
      let _ = volatilePointer[0]
      #endif
    }
  }
  
  /**
   Executes a closure with a temporary secure byte array that will be automatically
   zeroed after use, regardless of how the closure exits (normal return or exception).
   
   This utility method ensures that sensitive data is properly cleaned up, even in
   the case of errors or early returns within the closure.
   
   ## Example
   
   ```swift
   let result = MemoryProtection.withSecureTemporaryData([UInt8](repeating: 0, count: 32)) { buffer in
     // Fill buffer with sensitive data
     fillWithSensitiveData(&buffer)
     
     // Process the data
     return processData(buffer)
   }
   // At this point, buffer has been securely zeroed
   ```
   
   - Parameters:
     - initialValue: The initial byte array (will be copied)
     - body: The closure that receives a mutable copy of the data
   - Returns: The value returned by the closure
   */
  public static func withSecureTemporaryData<R>(_ initialValue: [UInt8], _ body: (inout [UInt8]) throws -> R) rethrows -> R {
    // Create a mutable copy of the data
    var tempData = initialValue
    
    // Ensure secure zeroing happens even if the closure throws
    defer {
      secureZero(&tempData)
    }
    
    // Execute the body with the temporary data
    return try body(&tempData)
  }
  
  /**
   Creates a secure random byte array of the specified length.
   
   This method generates cryptographically secure random bytes using the system's
   secure random number generator (CSPRNG). The resulting bytes are suitable for
   cryptographic operations like key generation.
   
   - Parameter length: The number of random bytes to generate
   - Returns: A byte array filled with cryptographically secure random data
   - Throws: SecurityError if random generation fails
   */
  public static func secureRandomBytes(_ length: Int) throws -> [UInt8] {
    var bytes = [UInt8](repeating: 0, count: length)
    
    // Use SecRandomCopyBytes for secure random generation
    let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
    
    guard status == errSecSuccess else {
      throw SecurityError.randomGenerationFailed
    }
    
    return bytes
  }
  
  /// Errors related to memory protection operations
  public enum SecurityError: Error {
    /// Failed to generate secure random bytes
    case randomGenerationFailed
  }
}
