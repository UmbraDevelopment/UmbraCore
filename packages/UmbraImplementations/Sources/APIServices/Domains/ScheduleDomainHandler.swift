import APIInterfaces
import LoggingInterfaces

/**
 Placeholder implementation for the Schedule domain handler.
 */
public class ScheduleDomainHandler: DomainHandler {
  private let logger: PrivacyAwareLoggingProtocol?

  public init(logger: PrivacyAwareLoggingProtocol?) {
    self.logger=logger
  }

  // MARK: - DomainHandler Conformance

  public var domain: String { APIDomain.schedule.rawValue }

  public func handleOperation(operation: some APIOperation) async throws -> Any {
    await logger?.debug(
      "Handling schedule operation: \(operation)",
      context: BaseLogContextDTO(domainName: domain, source: "handleOperation")
    )
    throw APIError.operationNotSupported(
      message: "Operation \(String(describing: type(of: operation))) not yet implemented for domain \(domain)",
      code: "NOT_IMPLEMENTED"
    )
  }
}
