import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes
import LoggingWrapperServices
import NetworkInterfaces

/// Implementation of NetworkServiceFactory that provides methods for creating network service
/// instances
public struct NetworkServiceFactoryImpl: NetworkServiceFactoryProtocol {
  /// The logging service factory for creating loggers
  private let loggingFactory=LoggingServiceFactory.shared

  /// Initialise a new NetworkServiceFactoryImpl
  public init() {}

  /// Creates a default network service
  public func createDefault() -> any NetworkServiceProtocol {
    // Create a network service with default settings
    // We need to use a non-async initializer since this method isn't async
    let networkLogger=LoggingWrapperServices.Logger.createPrivacyAwareLogger()

    return NetworkServiceImpl(
      timeoutInterval: 60.0,
      cachePolicy: .useProtocolCachePolicy,
      enableMetrics: true,
      logger: networkLogger
    )
  }

  /// Creates a network service with custom configuration
  public func createService(
    timeoutInterval: Double,
    cachePolicy: CachePolicy,
    enableMetrics: Bool
  ) -> any NetworkServiceProtocol {
    // Create a network service with custom settings
    // We need to use a non-async initializer since this method isn't async
    let networkLogger=LoggingWrapperServices.Logger.createPrivacyAwareLogger()

    return NetworkServiceImpl(
      timeoutInterval: timeoutInterval,
      cachePolicy: cachePolicy,
      enableMetrics: enableMetrics,
      logger: networkLogger
    )
  }

  /// Creates a network service with authentication
  public func createAuthenticatedService(
    authenticationType: AuthenticationType,
    credentials: AuthCredentials,
    timeoutInterval: Double
  ) -> any NetworkServiceProtocol {
    let sessionConfig=URLSessionConfiguration.default
    sessionConfig.timeoutIntervalForRequest=timeoutInterval
    sessionConfig.timeoutIntervalForResource=timeoutInterval * 2

    // Add authentication headers
    var additionalHeaders: [String: String]=[:]

    switch authenticationType {
      case .basic:
        if let username=credentials.username, let password=credentials.password {
          let authString="\(username):\(password)"
          if let authData=authString.data(using: .utf8) {
            let base64Auth=authData.base64EncodedString()
            additionalHeaders["Authorization"]="Basic \(base64Auth)"
          }
        }

      case .bearer:
        if let token=credentials.token {
          additionalHeaders["Authorization"]="Bearer \(token)"
        }

      case .oauth2:
        if let token=credentials.token {
          additionalHeaders["Authorization"]="Bearer \(token)"
        }

      case let .custom(authType):
        if let token=credentials.token {
          additionalHeaders["Authorization"]="\(authType) \(token)"
        }
    }

    // Add any additional parameters from credentials
    for (key, value) in credentials.additionalParameters {
      additionalHeaders[key]=value
    }

    // Set headers in configuration
    sessionConfig.httpAdditionalHeaders=additionalHeaders

    let session=URLSession(configuration: sessionConfig)

    // Create and return the network service
    let networkLogger=LoggingWrapperServices.Logger.createPrivacyAwareLogger()

    return NetworkServiceImpl(
      session: session,
      defaultTimeoutInterval: timeoutInterval,
      defaultCachePolicy: .useProtocolCachePolicy,
      logger: networkLogger
    )
  }

  /// Creates a network service with a custom URLSession
  public func createServiceWithSession(
    session: URLSession,
    timeoutInterval: Double
  ) -> any NetworkServiceProtocol {
    // Create a network service with a custom session
    // We need to use a non-async initializer since this method isn't async
    let networkLogger=LoggingWrapperServices.Logger.createPrivacyAwareLogger()

    return NetworkServiceImpl(
      session: session,
      defaultTimeoutInterval: timeoutInterval,
      defaultCachePolicy: .useProtocolCachePolicy,
      logger: networkLogger
    )
  }
}
