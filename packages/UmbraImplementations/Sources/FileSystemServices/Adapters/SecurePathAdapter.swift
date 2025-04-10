import FileSystemInterfaces
import FileSystemTypes
import Foundation
import CoreDTOs

/**
 # SecurePathAdapter

 Provides conversion between FilePathDTO and SecurePath types to facilitate
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
   Converts a FilePathDTO to a SecurePath.

   - Parameter filePathDTO: The FilePathDTO to convert
   - Returns: A SecurePath representation, or nil if conversion fails
   */
  public static func toSecurePath(_ filePathDTO: FilePathDTO) -> SecurePath? {
    SecurePath(
      path: filePathDTO.path,
      isDirectory: filePathDTO.resourceType == .directory,
      securityLevel: mapSecurityLevel(filePathDTO.securityOptions)
    )
  }

  /**
   Converts a SecurePath to a FilePathDTO.

   - Parameter securePath: The SecurePath to convert
   - Returns: A FilePathDTO representation
   */
  public static func toFilePathDTO(_ securePath: SecurePath) -> FilePathDTO {
    let path = securePath.toString()
    let directoryPath = securePath.isDirectory ? path : (URL(fileURLWithPath: path).deletingLastPathComponent().path)
    let fileName = securePath.isDirectory ? "" : (URL(fileURLWithPath: path).lastPathComponent)
    
    return FilePathDTO(
      path: path,
      fileName: fileName,
      directoryPath: directoryPath,
      resourceType: securePath.isDirectory ? .directory : .file,
      isAbsolute: path.hasPrefix("/"),
      securityOptions: mapSecurityOptions(securePath.securityLevel)
    )
  }

  /**
   Maps FilePathDTO security options to SecurePath security level.

   - Parameter options: The FilePathDTO security options
   - Returns: The corresponding SecurePath security level
   */
  private static func mapSecurityLevel(_ options: SecurityOptions?) -> PathSecurityLevel {
    guard let options else {
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
   Maps SecurePath security level to FilePathDTO security options.

   - Parameter level: The SecurePath security level
   - Returns: The corresponding FilePathDTO security options
   */
  private static func mapSecurityOptions(_ level: PathSecurityLevel) -> SecurityOptions {
    let securityLevel: SecurityLevel = switch level {
      case .standard:
        .standard
      case .elevated:
        .elevated
      case .high:
        .high
      case .restricted:
        .restricted
    }

    return SecurityOptions(level: securityLevel)
  }
}
