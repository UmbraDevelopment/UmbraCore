import Foundation
import LoggingInterfaces
import TaskSchedulingInterfaces

/**
 Factory for creating TaskSchedulingService instances.

 This factory centralises the creation of TaskSchedulingService implementations,
 providing a consistent way to instantiate the service with all required dependencies.
 */
public class TaskSchedulingServiceFactory {

  /**
   Creates a new instance of a TaskSchedulingService.

   - Parameters:
      - logger: The logger to use for task scheduling operations
   - Returns: An implementation of TaskSchedulingServiceProtocol
   */
  public static func createTaskSchedulingService(
    logger: PrivacyAwareLoggingProtocol
  ) -> TaskSchedulingServiceProtocol {
    TaskSchedulingServicesActor(logger: logger)
  }

  /**
   Private initialiser to prevent instantiation of the factory.
   */
  private init() {
    // This factory should not be instantiated
  }
}
