import APIInterfaces
import LoggingInterfaces

/**
 Placeholder implementation for the Network domain handler.
 */
public class NetworkDomainHandler: DomainHandler {
  private let logger: PrivacyAwareLoggingProtocol?

  public init(logger: PrivacyAwareLoggingProtocol?) {
    self.logger = logger
  }
  
  // MARK: - DomainHandler Conformance
  public var domain: String { APIDomain.network.rawValue }

  public func handleOperation<T: APIOperation>(operation: T) async throws -> Any {
    await logger?.debug("Handling network operation: \(operation)", context: BaseLogContextDTO(domainName: domain, source: "handleOperation"))
    throw APIError.operationNotSupported(
      message: "Operation \(String(describing: type(of: operation))) not yet implemented for domain \(domain)",
      code: "NOT_IMPLEMENTED"
    )
  }
}
