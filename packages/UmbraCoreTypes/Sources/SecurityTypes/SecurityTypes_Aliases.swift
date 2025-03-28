import Foundation

// Type aliases for security related types
// These aliases provide semantic meaning to standard types when used in security contexts

/// Alias for a cryptographic nonce value (number used once)
public typealias Nonce=[UInt8]

/// Alias for a cryptographic salt value
public typealias Salt=[UInt8]

/// Alias for a cryptographic key
public typealias Key=[UInt8]

/// Alias for a cryptographic initialisation vector
public typealias InitialisationVector=[UInt8]

/// Alias for a cryptographic hash
public typealias Hash=[UInt8]
