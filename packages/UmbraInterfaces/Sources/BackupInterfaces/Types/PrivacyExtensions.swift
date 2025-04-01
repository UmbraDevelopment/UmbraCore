import Foundation
import LoggingInterfaces

/**
 * Privacy-aware string extension for backup-related data.
 *
 * This extension provides a consistent way to handle privacy annotations in string
 * interpolation across the backup system, ensuring sensitive data is properly
 * marked with appropriate privacy levels.
 */
extension String {
  /**
   * Returns a privacy-annotated string for backup paths.
   *
   * Paths should generally be treated as private since they may contain
   * personally identifiable information such as usernames or directory structures.
   *
   * - Returns: A string with privacy annotation for backup paths
   */
  public func asBackupPath() -> PrivacyAnnotatedString {
    withPrivacyLevel(.private)
  }

  /**
   * Returns a privacy-annotated string for backup identifiers.
   *
   * Identifiers are considered restricted information since they might be
   * indirectly linkable to user data.
   *
   * - Returns: A string with privacy annotation for backup identifiers
   */
  public func asBackupID() -> PrivacyAnnotatedString {
    withPrivacyLevel(.restricted)
  }

  /**
   * Returns a privacy-annotated string for tags.
   *
   * Tags may contain sensitive information about the content or purpose of backups.
   *
   * - Returns: A string with privacy annotation for backup tags
   */
  public func asBackupTag() -> PrivacyAnnotatedString {
    withPrivacyLevel(.restricted)
  }

  /**
   * Returns a privacy-annotated string for error details.
   *
   * Error details might contain sensitive information that should be
   * protected in production environments but available for debugging.
   *
   * - Returns: A string with privacy annotation for error details
   */
  public func asErrorDetail() -> PrivacyAnnotatedString {
    withPrivacyLevel(.private)
  }

  /**
   * Returns a privacy-annotated string for error codes.
   *
   * Error codes are public information that can be safely logged.
   *
   * - Returns: A string with privacy annotation for error codes
   */
  public func asErrorCode() -> PrivacyAnnotatedString {
    withPrivacyLevel(.public)
  }

  /**
   * Returns a privacy-annotated string for command output.
   *
   * Command output is treated as private because it might contain paths,
   * authentication details, or other sensitive information.
   *
   * - Returns: A string with privacy annotation for command output
   */
  public func asCommandOutput() -> PrivacyAnnotatedString {
    withPrivacyLevel(.private)
  }

  /**
   * Returns a privacy-annotated string for public backup information.
   *
   * Use this for information that is safe to log in all environments.
   *
   * - Returns: A string with privacy annotation as public information
   */
  public func asPublicInfo() -> PrivacyAnnotatedString {
    withPrivacyLevel(.public)
  }
}

/**
 * Privacy-aware URL extension for backup-related data.
 *
 * This extension provides consistent privacy handling for URLs in the backup system.
 */
extension URL {
  /**
   * Returns a privacy-annotated string for the URL path.
   *
   * URL paths are treated as private as they may contain user-specific information.
   *
   * - Returns: A privacy-annotated string representing the URL path
   */
  public func asPrivatePath() -> PrivacyAnnotatedString {
    path.withPrivacyLevel(.private)
  }

  /**
   * Returns a redacted representation of the URL for logging.
   *
   * This representation maintains the last path component but redacts the rest
   * of the path to protect sensitive information.
   *
   * - Returns: A privacy-annotated string with a redacted path representation
   */
  public func asRedactedPath() -> PrivacyAnnotatedString {
    let lastComponent=lastPathComponent
    return "...\\\(lastComponent)".withPrivacyLevel(.restricted)
  }
}

/**
 * Extension to handle arrays of strings with privacy annotations.
 */
extension [String] {
  /**
   * Returns a privacy-annotated string for an array of paths.
   *
   * - Returns: A privacy-annotated string representing the paths
   */
  public func asPrivatePaths() -> PrivacyAnnotatedString {
    description.withPrivacyLevel(.private)
  }

  /**
   * Returns a privacy-annotated string for an array of backup tags.
   *
   * - Returns: A privacy-annotated string representing the tags
   */
  public func asBackupTags() -> PrivacyAnnotatedString {
    description.withPrivacyLevel(.restricted)
  }
}

/**
 * Extension to handle arrays of URLs with privacy annotations.
 */
extension [URL] {
  /**
   * Returns a privacy-annotated string for an array of URL paths.
   *
   * - Returns: A privacy-annotated string representing the URL paths
   */
  public func asPrivatePaths() -> PrivacyAnnotatedString {
    let paths=map(\.path)
    return paths.description.withPrivacyLevel(.private)
  }

  /**
   * Returns a privacy-annotated string for an array of redacted URL paths.
   *
   * - Returns: A privacy-annotated string with redacted path representations
   */
  public func asRedactedPaths() -> PrivacyAnnotatedString {
    let components=map(\.lastPathComponent)
    return components.description.withPrivacyLevel(.restricted)
  }
}
