import Foundation
import KeychainInterfaces

/**
 # KeychainAccessOptions

 This file now imports and re-exports the canonical KeychainAccessOptions type from KeychainInterfaces.

 The original implementation has been consolidated into the KeychainInterfaces module
 to ensure a single source of truth and eliminate ambiguity.

 ## Usage

 Access this type through the KeychainInterfaces module directly for new code:

 ```swift
 import KeychainInterfaces

 let options: KeychainAccessOptions = [.whenUnlocked, .thisDeviceOnly]
 ```

 For backwards compatibility, this module continues to expose the same type through
 this typealias.
 */

// Re-export the canonical type for backwards compatibility
public typealias KeychainAccessOptions=KeychainInterfaces.KeychainAccessOptions
