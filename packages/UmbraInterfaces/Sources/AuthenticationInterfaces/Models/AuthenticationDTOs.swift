import CoreDTOs
import Foundation

/**
 Authentication status representing the current state of the authentication process.
 */
public enum AuthenticationStatus: String, Codable, Sendable {
  /// User is authenticated
  case authenticated
  /// User is not authenticated
  case notAuthenticated
  /// Authentication is in progress
  case inProgress
  /// Token is expired but can be refreshed
  case requiresRefresh
}

/**
 Type of authentication method being used.
 */
public enum AuthenticationMethodType: String, Codable, Sendable {
  /// Username and password authentication
  case password
  /// Biometric authentication (Touch ID, Face ID)
  case biometric
  /// Single Sign-On integration
  case sso
  /// OAuth token-based authentication
  case oauth
  /// Custom authentication mechanism
  case custom
}

/**
 Credentials for authenticating a user.
 */
public struct AuthCredentialsDTO: Sendable {
  /// Unique identifier for the user (e.g., username, email)
  public let identifier: String

  /// Secret for authentication (e.g., password, token)
  public let secret: String

  /// Additional metadata needed for specific authentication types
  public let metadata: [String: String]

  /// Type of authentication method to use
  public let methodType: AuthenticationMethodType

  /**
   Initialises a new authentication credentials object.

   - Parameters:
      - identifier: Unique identifier for the user
      - secret: Secret for authentication
      - methodType: Type of authentication method
      - metadata: Additional metadata for authentication
   */
  public init(
    identifier: String,
    secret: String,
    methodType: AuthenticationMethodType,
    metadata: [String: String]=[:]
  ) {
    self.identifier=identifier
    self.secret=secret
    self.methodType=methodType
    self.metadata=metadata
  }
}

/**
 Authentication token representing a successful authentication session.
 */
public struct AuthTokenDTO: Sendable {
  /// The actual token string
  public let tokenString: String

  /// Type of token (e.g., JWT, OAuth)
  public let tokenType: String

  /// When the token was issued
  public let issuedAt: Date

  /// When the token expires
  public let expiresAt: Date

  /// The authenticated user identifier
  public let userIdentifier: String

  /// Additional claims or metadata
  public let claims: [String: String]

  /**
   Initialises a new authentication token.

   - Parameters:
      - tokenString: The actual token string
      - tokenType: Type of token
      - issuedAt: When the token was issued
      - expiresAt: When the token expires
      - userIdentifier: The authenticated user identifier
      - claims: Additional claims or metadata
   */
  public init(
    tokenString: String,
    tokenType: String,
    issuedAt: Date,
    expiresAt: Date,
    userIdentifier: String,
    claims: [String: String]=[:]
  ) {
    self.tokenString=tokenString
    self.tokenType=tokenType
    self.issuedAt=issuedAt
    self.expiresAt=expiresAt
    self.userIdentifier=userIdentifier
    self.claims=claims
  }

  /**
   Checks if the token is currently valid (not expired).

   - Returns: True if the token is valid, false if expired
   */
  public func isValid() -> Bool {
    Date() < expiresAt
  }

  /**
   Checks if the token will expire soon (within the specified time interval).

   - Parameters:
      - timeInterval: The time interval to check
   - Returns: True if the token will expire within the given interval
   */
  public func willExpireSoon(within timeInterval: TimeInterval=300) -> Bool {
    let expirationThreshold=Date().addingTimeInterval(timeInterval)
    return expiresAt < expirationThreshold
  }
}
