import Foundation
import LoggingTypes
import LoggingInterfaces

/**
 A placeholder factory for logging commands used during actor initialisation.
 
 This class provides no-op implementations to avoid circular dependencies
 during the initialisation phase. It will be replaced with a real factory
 after initialisation is complete.
 */
public class LogCommandDummyFactory: LogCommandFactory {
    /**
     Initialises a new dummy logging command factory.
     */
    public init() {
        // Use a temporary DummyLoggingServicesActor that can't be fully initialized yet
        // This workaround is needed because Swift's initialisation rules require super.init
        // to be called, but we can't create proper dependencies without circular references
        let tempActor = UnsafeMutablePointer<LoggingServicesActor>.allocate(capacity: 1)
        defer { tempActor.deallocate() }
        
        // Call super.init with the raw pointer cast to LoggingServicesActor
        // This is unsafe but acceptable as a temporary bootstrapping measure
        // since the dummy factory will be immediately replaced after initialisation
        super.init(
            providers: [:],
            logger: DummyLoggingActor(),
            loggingServicesActor: unsafeBitCast(tempActor, to: LoggingServicesActor.self)
        )
    }
    
    // Implement only the methods that exist in the parent class
    public override func makeWriteLogCommand(
        entry: LoggingInterfaces.LogEntryDTO,
        destination: LoggingInterfaces.LogDestinationDTO
    ) throws -> WriteLogCommand {
        fatalError("Dummy factory should not be used")
    }
    
    public override func makeAddDestinationCommand(
        destination: LoggingInterfaces.LogDestinationDTO,
        options: LoggingInterfaces.AddDestinationOptionsDTO
    ) -> AddDestinationCommand {
        fatalError("Dummy factory should not be used")
    }
}
