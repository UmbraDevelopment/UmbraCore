import Foundation
import FileSystemTypes
import FileSystemInterfaces

/**
 # SecurePathAdapter
 
 Provides conversion between FilePath and SecurePath types to facilitate
 the transition from Foundation-dependent to Foundation-independent code.
 
 This adapter follows the Alpha Dot Five architecture principles by enabling
 gradual migration from Foundation dependencies while maintaining compatibility
 with existing code.
 
 ## Thread Safety
 
 This type is designed to be thread-safe and can be safely used across
 actor boundaries as it uses only static methods with no shared state.
 
 ## British Spelling
 
 This implementation uses British spelling conventions where appropriate
 in documentation and public-facing elements.
 */
public enum SecurePathAdapter {
    /**
     Converts a FilePath to a SecurePath.
     
     - Parameter filePath: The FilePath to convert
     - Returns: A SecurePath representation, or nil if conversion fails
     */
    public static func toSecurePath(_ filePath: FilePath) -> SecurePath? {
        return SecurePath(
            path: filePath.path,
            isDirectory: filePath.isDirectory,
            securityLevel: mapSecurityLevel(filePath.securityOptions)
        )
    }
    
    /**
     Converts a SecurePath to a FilePath.
     
     - Parameter securePath: The SecurePath to convert
     - Returns: A FilePath representation
     */
    public static func toFilePath(_ securePath: SecurePath) -> FilePath {
        return FilePath(
            path: securePath.toString(),
            isDirectory: securePath.isDirectory,
            securityOptions: mapSecurityOptions(securePath.securityLevel)
        )
    }
    
    /**
     Maps FilePath security options to SecurePath security level.
     
     - Parameter options: The FilePath security options
     - Returns: The corresponding SecurePath security level
     */
    private static func mapSecurityLevel(_ options: SecurityOptions?) -> PathSecurityLevel {
        guard let options = options else {
            return .standard
        }
        
        switch options.level {
        case .standard:
            return .standard
        case .elevated:
            return .elevated
        case .high:
            return .high
        case .restricted:
            return .restricted
        }
    }
    
    /**
     Maps SecurePath security level to FilePath security options.
     
     - Parameter level: The SecurePath security level
     - Returns: The corresponding FilePath security options
     */
    private static func mapSecurityOptions(_ level: PathSecurityLevel) -> SecurityOptions {
        let securityLevel: SecurityLevel
        
        switch level {
        case .standard:
            securityLevel = .standard
        case .elevated:
            securityLevel = .elevated
        case .high:
            securityLevel = .high
        case .restricted:
            securityLevel = .restricted
        }
        
        return SecurityOptions(level: securityLevel)
    }
}
