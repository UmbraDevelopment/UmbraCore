import APIInterfaces
import LoggingInterfaces

/**
 Placeholder implementation for the System domain handler.
 */
public class SystemDomainHandler: DomainHandler {
  private let logger: PrivacyAwareLoggingProtocol?

  public init(logger: PrivacyAwareLoggingProtocol?) {
    self.logger=logger
  }

  // MARK: - DomainHandler Conformance

  public var domain: String { APIDomain.system.rawValue }

  public func handleOperation(operation: some APIOperation) async throws -> Any {
    await logger?.debug(
      "Handling system operation: \(operation)",
      context: BaseLogContextDTO(domainName: domain, source: "handleOperation")
    )
    throw APIError.operationNotSupported(
      message: "Operation \(String(describing: type(of: operation))) not yet implemented for domain \(domain)",
      code: "NOT_IMPLEMENTED"
    )
  }
}
