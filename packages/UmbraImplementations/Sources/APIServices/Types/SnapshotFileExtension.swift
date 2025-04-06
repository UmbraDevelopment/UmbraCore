import Foundation
import BackupInterfaces

/**
 Extension for SnapshotFile to add properties for file identification and metadata.
 */
public extension SnapshotFile {
    /**
     A unique identifier for the file.
     
     This is derived from the path and other file metadata to ensure uniqueness.
     */
    var id: String {
        // Create a unique ID based on path and other metadata
        let idBase = "\(path):\(size):\(lastModifiedTime?.timeIntervalSince1970 ?? 0)"
        return idBase.md5Hash
    }
    
    /**
     The type of the file.
     */
    var type: SnapshotFileType {
        return isDirectory ? .directory : .file
    }
    
    /**
     A hash of the file contents, if available.
     
     For directories, this will be empty.
     */
    var hash: String? {
        return contentHash
    }
    
    /**
     The modification date of the file.
     */
    var modificationDate: Date? {
        return lastModifiedTime
    }
}

/**
 Defines the types of files that can be in a snapshot.
 */
public enum SnapshotFileType {
    case file
    case directory
    case symbolicLink
    case unknown
}

/**
 Extension to provide hashing utilities.
 */
extension String {
    /**
     Computes an MD5 hash of this string.
     */
    var md5Hash: String {
        // This is a placeholder implementation
        // In a real implementation, this would compute an actual MD5 hash
        let digest = Data(self.utf8).base64EncodedString()
        return digest.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "=", with: "")
    }
}
