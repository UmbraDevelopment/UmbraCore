import CryptoTypes
import CoreDTOs

/**
 # CryptoServiceMonitorProtocol
 
 Protocol defining monitoring capabilities for cryptographic operations.
 
 This protocol provides a standardised interface for monitoring
 cryptographic operations using Swift's modern concurrency features.
 It replaces the older delegate/callback pattern with async sequences
 for more structured and maintainable code.
 */
public protocol CryptoServiceMonitorProtocol: Sendable {
    /**
     Starts monitoring crypto operations.
     
     - Returns: True if monitoring was successfully started, false if already active
     */
    func startMonitoring() async -> Bool
    
    /**
     Stops monitoring crypto operations.
     
     - Returns: True if monitoring was successfully stopped, false if not active
     */
    func stopMonitoring() async -> Bool
    
    /**
     Returns an AsyncSequence of crypto operation events.
     
     This method provides a modern way to monitor crypto operations using
     Swift's AsyncSequence protocol, allowing for-await-in loops and other
     structured concurrency patterns.
     
     - Returns: AsyncStream of CryptoEventDTO
     */
    func events() -> AsyncStream<CryptoEventDTO>
    
    /**
     Records a crypto operation event.
     
     - Parameter event: The crypto event to record
     */
    func recordEvent(_ event: CryptoEventDTO) async
    
    /**
     Records a batch of crypto operation events.
     
     - Parameter events: The crypto events to record
     */
    func recordEvents(_ events: [CryptoEventDTO]) async
    
    /**
     Filters events based on specified criteria.
     
     - Parameter filter: The filter criteria to apply
     
     - Returns: AsyncStream of filtered CryptoEventDTO
     */
    func filteredEvents(
        matching filter: CryptoEventFilterDTO
    ) -> AsyncStream<CryptoEventDTO>
}
