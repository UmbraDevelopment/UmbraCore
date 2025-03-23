import ErrorHandlingDomains
import Foundation
@testable import SecurityInterfaces

// This module exists to provide @testable access to SecurityInterfaces
// for use in test targets. It re-exports the SecurityInterfaces module
// with testable access to internal members.

// Re-export SecurityError for convenience in tests
public typealias SecurityError=SecurityInterfaces.SecurityError
