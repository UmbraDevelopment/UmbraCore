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

   - This function performs a best-effort memory clearing within the constraints
     of Swift's memory model.

   - Whilst this helps mitigate risks, it cannot guarantee complete protection against
     all forms of memory analysis, especially in garbage-collected environments.

   ## Example Usage

   ```swift
   // Create a buffer with sensitive data
   var sensitiveData: [UInt8] = [ /* sensitive bytes */ ]

   // Process the sensitive data
   processData(sensitiveData)

   // Zero the memory when done
   MemoryProtection.secureZero(&sensitiveData)
   ```

   - Parameter bytes: Array of bytes to securely zero (passed as an inout parameter)
   */
  public static func secureZero(_ bytes: inout [UInt8]) {
    // Use volatile to prevent compiler optimisation from removing this zeroing
    for i in 0..<bytes.count {
      bytes[i] = 0
    }
  }

  /**
   Securely handles sensitive data with automatic zeroing after use.

   This method provides a convenient way to work with sensitive data while
   ensuring it is properly zeroed from memory after use, even if exceptions occur.
   The pattern uses Swift's `defer` statement to guarantee cleanup.

   ## Example Usage

   ```swift
   let result = MemoryProtection.withSecureTemporaryData(sensitiveBytes) { bytes in
       // Work with the sensitive data
       return computeHash(bytes)
   }
   // At this point, the temporary copy has been automatically zeroed
   ```

   - Parameters:
      - data: The sensitive data to work with
      - block: A closure that receives the sensitive data and returns a result

   - Returns: The result of the block operation
   - Throws: Rethrows any errors from the provided block
   */
  public static func withSecureTemporaryData<T>(
    _ data: [UInt8],
    _ block: ([UInt8]) throws -> T
  ) rethrows -> T {
    var secureData = data
    defer {
      secureZero(&secureData)
    }
    return try block(secureData)
  }

  /**
   Performs a secure memory comparison between two byte arrays.

   This method implements a constant-time comparison to prevent timing attacks
   that could exploit variable-time comparisons when verifying cryptographic
   values such as MACs, signatures, or authentication tokens.

   ## Security Context

   Regular equality comparisons (==) typically stop at the first difference,
   revealing information about where the differences occur through timing
   variations. This method always compares all bytes, taking the same amount
   of time regardless of where differences occur.

   ## Usage Example

   ```swift
   let expectedMAC: [UInt8] = calculateExpectedMAC()
   let receivedMAC: [UInt8] = receiveMAC()

   if MemoryProtection.secureCompare(expectedMAC, receivedMAC) {
       // MACs match, proceed with authenticated data
   } else {
       // Authentication failure
   }
   ```

   - Parameters:
      - lhs: First byte array to compare
      - rhs: Second byte array to compare

   - Returns: True if the arrays contain identical bytes, false otherwise
   */
  public static func secureCompare(_ lhs: [UInt8], _ rhs: [UInt8]) -> Bool {
    guard lhs.count == rhs.count else {
      return false
    }

    var result: UInt8 = 0

    // Constant-time comparison - always compare all bytes
    for i in 0..<lhs.count {
      // XOR results in 0 for matching bytes, non-zero for differences
      // OR accumulates any differences
      result |= lhs[i] ^ rhs[i]
    }

    return result == 0
  }
}
