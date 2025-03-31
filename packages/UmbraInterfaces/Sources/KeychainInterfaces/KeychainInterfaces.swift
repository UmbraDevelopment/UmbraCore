/// # KeychainInterfaces Module
///
/// Provides protocol interfaces for the keychain system, following the Alpha Dot Five
/// architecture principle of separation between types, interfaces, and implementations.
///
/// This module contains:
/// - Protocol interfaces for keychain operations
/// - Service contracts for secure storage
///
/// Following Alpha Dot Five principles, this module:
/// - Contains only interfaces
/// - Uses types defined in KeychainTypes
/// - Contains no implementation code
/// - Defines clear boundaries for capabilities
///
/// ## Key Components
///
/// ```swift
/// KeychainServiceProtocol
/// ```
///
/// ## Example Usage
///
/// ```swift
/// let keychainService: KeychainServiceProtocol = await KeychainServices.createService()
/// try await keychainService.storePassword("password123", for: "user@example.com")
/// ```
