/// # KeychainTypes Module
///
/// Provides types and enumerations for the keychain system, following the Alpha Dot Five
/// architecture principle of separation between types, interfaces, and implementations.
///
/// This module contains:
/// - Error types for keychain operations
/// - Access control options and settings
/// - Data transfer objects for keychain operations
///
/// Following Alpha Dot Five principles, this module:
/// - Contains only type definitions
/// - Has no implementation logic
/// - Uses British spelling in documentation
/// - Provides comprehensive documentation
///
/// ## Key Components
///
/// ```swift
/// KeychainError
/// KeychainAccessOptions
/// ```
///
/// ## Example Usage
///
/// ```swift
/// do {
///     try await keychainService.storePassword("secret", for: "account")
/// } catch let error as KeychainError {
///     switch error {
///     case .itemAlreadyExists:
///         // Handle duplicate item
///     case .accessDenied:
///         // Handle permission issues
///     default:
///         // Handle other errors
///     }
/// }
/// ```
