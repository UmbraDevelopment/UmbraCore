import FileSystemCommonTypes
import Foundation

/**
 # File Path DTO

 This file re-exports the FilePathDTO type from the FileSystemCommonTypes module.

 The implementation has been moved to FileSystemCommonTypes to avoid circular
 dependencies between CoreDTOs and FileSystemTypes, in accordance with the
 Alpha Dot Five architecture principles of clean separation of concerns.

 This re-export maintains backwards compatibility with existing code that
 imports FilePathDTO from CoreDTOs while using the canonical implementation
 in FileSystemCommonTypes.
 */

public typealias FilePathDTO=FileSystemCommonTypes.FilePathDTO
