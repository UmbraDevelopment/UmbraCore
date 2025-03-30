import Foundation

/**
 # ErrorMappingProtocol
 
 Protocol defining requirements for error mapping components.
 
 This protocol establishes a consistent interface for translating errors
 between different domains or representations. It follows the Alpha Dot Five
 architecture by providing a clear separation between mapping interfaces
 and implementations.
 */
public protocol ErrorMappingProtocol: Sendable {
    associatedtype SourceError: Error
    associatedtype TargetError: Error
    
    /**
     Maps a source error to a target error type.
     
     This method should transform errors from one domain or representation
     to another, preserving relevant context and information.
     
     - Parameter error: The source error to map
     - Returns: The equivalent error in the target domain
     */
    func map(_ error: SourceError) -> TargetError
    
    /**
     Determines if this mapper can handle a specific error type.
     
     - Parameter error: The error to check
     - Returns: True if this mapper can handle the specified error
     */
    func canMap(_ error: SourceError) -> Bool
}
