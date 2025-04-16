import Foundation

/**
 # File Creation Options

 Options for controlling how files are created in the file system.

 ## Alpha Dot Five Architecture

 This type follows the Alpha Dot Five architecture principles:
 - Uses immutable structs for thread safety
 - Provides clear, well-documented options
 - Uses British spelling in documentation
 */
public struct FileCreationOptions: Sendable {
  /// File attributes to set when creating the file
  public let attributes: SendableFileAttributes?

  /// Whether to overwrite an existing file at the path
  public let shouldOverwrite: Bool

  /// Creates new file creation options
  public init(
    attributes: [FileAttributeKey: Any]?=nil,
    shouldOverwrite: Bool=false
  ) {
    self.attributes=attributes != nil ? SendableFileAttributes(attributes: attributes) : nil
    self.shouldOverwrite=shouldOverwrite
  }
}

// MARK: - Equatable Implementation for FileCreationOptions

extension FileCreationOptions: Equatable {
  public static func == (lhs: FileCreationOptions, rhs: FileCreationOptions) -> Bool {
    // Compare shouldOverwrite directly
    guard lhs.shouldOverwrite == rhs.shouldOverwrite else { return false }

    // Handle attributes specially - both nil means equal
    if lhs.attributes == nil && rhs.attributes == nil {
      return true
    }

    // If one is nil and the other isn't, they're not equal
    if lhs.attributes == nil || rhs.attributes == nil {
      return false
    }

    // Compare attributes by keys and values where possible
    guard lhs.attributes == rhs.attributes else { return false }

    return true
  }
}

/**
 # File Write Options

 Options for controlling how data is written to files.

 ## Alpha Dot Five Architecture

 This type follows the Alpha Dot Five architecture principles:
 - Uses immutable structs for thread safety
 - Provides clear, well-documented options
 - Uses British spelling in documentation
 */
public struct FileWriteOptions: Sendable {
  /// Whether to create parent directories if they don't exist
  public let createIntermediateDirectories: Bool

  /// Whether to append to an existing file rather than overwriting
  public let append: Bool

  /// Whether to use atomic write operations
  public let atomicWrite: Bool

  /// File attributes to set when writing the file
  public let attributes: SendableFileAttributes?

  /// Creates new file write options
  public init(
    createIntermediateDirectories: Bool=false,
    append: Bool=false,
    atomicWrite: Bool=false,
    attributes: [FileAttributeKey: Any]?=nil
  ) {
    self.createIntermediateDirectories=createIntermediateDirectories
    self.append=append
    self.atomicWrite=atomicWrite
    self.attributes=attributes != nil ? SendableFileAttributes(attributes: attributes) : nil
  }
}

// MARK: - Equatable Implementation for FileWriteOptions

extension FileWriteOptions: Equatable {
  public static func == (lhs: FileWriteOptions, rhs: FileWriteOptions) -> Bool {
    // Compare simple properties
    guard
      lhs.createIntermediateDirectories == rhs.createIntermediateDirectories,
      lhs.append == rhs.append,
      lhs.atomicWrite == rhs.atomicWrite
    else {
      return false
    }

    // Handle attributes specially - both nil means equal
    if lhs.attributes == nil && rhs.attributes == nil {
      return true
    }

    // If one is nil and the other isn't, they're not equal
    if lhs.attributes == nil || rhs.attributes == nil {
      return false
    }

    // Compare attributes by keys and values where possible
    guard lhs.attributes == rhs.attributes else { return false }

    return true
  }
}

/**
 # Directory Creation Options

 Options for controlling how directories are created.

 ## Alpha Dot Five Architecture

 This type follows the Alpha Dot Five architecture principles:
 - Uses immutable structs for thread safety
 - Provides clear, well-documented options
 - Uses British spelling in documentation
 */
public struct DirectoryCreationOptions: Sendable {
  /// POSIX permissions to set on the new directory
  public let posixPermissions: Int16?

  /// Owner account ID to set for the directory
  public let ownerAccountID: Int?

  /// Group owner account ID to set for the directory
  public let groupOwnerAccountID: Int?

  /// Directory attributes to set when creating the directory
  public let attributes: SendableFileAttributes?

  /// Creates new directory creation options
  public init(
    posixPermissions: Int16?=nil,
    ownerAccountID: Int?=nil,
    groupOwnerAccountID: Int?=nil,
    attributes: [FileAttributeKey: Any]?=nil
  ) {
    self.posixPermissions=posixPermissions
    self.ownerAccountID=ownerAccountID
    self.groupOwnerAccountID=groupOwnerAccountID
    self.attributes=attributes != nil ? SendableFileAttributes(attributes: attributes) : nil
  }
}

// MARK: - Equatable Implementation for DirectoryCreationOptions

extension DirectoryCreationOptions: Equatable {
  public static func == (lhs: DirectoryCreationOptions, rhs: DirectoryCreationOptions) -> Bool {
    // Compare simple properties
    guard
      lhs.posixPermissions == rhs.posixPermissions,
      lhs.ownerAccountID == rhs.ownerAccountID,
      lhs.groupOwnerAccountID == rhs.groupOwnerAccountID
    else {
      return false
    }

    // Handle attributes specially - both nil means equal
    if lhs.attributes == nil && rhs.attributes == nil {
      return true
    }

    // If one is nil and the other isn't, they're not equal
    if lhs.attributes == nil || rhs.attributes == nil {
      return false
    }

    // Compare attributes by keys and values where possible
    guard lhs.attributes == rhs.attributes else { return false }

    return true
  }
}

/**
 # File Move Options

 Options for controlling how files are moved.

 ## Alpha Dot Five Architecture

 This type follows the Alpha Dot Five architecture principles:
 - Uses immutable structs for thread safety
 - Provides clear, well-documented options
 - Uses British spelling in documentation
 */
public struct FileMoveOptions: Sendable, Equatable {
  /// Whether to overwrite the destination if it already exists
  public let shouldOverwrite: Bool

  /// Whether to create parent directories if they don't exist
  public let createIntermediateDirectories: Bool

  /// Creates new file move options
  public init(
    shouldOverwrite: Bool=false,
    createIntermediateDirectories: Bool=false
  ) {
    self.shouldOverwrite=shouldOverwrite
    self.createIntermediateDirectories=createIntermediateDirectories
  }
}

/**
 # File Copy Options

 Options for controlling how files are copied.

 ## Alpha Dot Five Architecture

 This type follows the Alpha Dot Five architecture principles:
 - Uses immutable structs for thread safety
 - Provides clear, well-documented options
 - Uses British spelling in documentation
 */
public struct FileCopyOptions: Sendable, Equatable {
  /// Whether to overwrite the destination if it already exists
  public let shouldOverwrite: Bool

  /// Whether to create parent directories if they don't exist
  public let createIntermediateDirectories: Bool

  /// Whether to preserve file attributes during the copy
  public let preserveAttributes: Bool

  /// Creates new file copy options
  public init(
    shouldOverwrite: Bool=false,
    createIntermediateDirectories: Bool=false,
    preserveAttributes: Bool=true
  ) {
    self.shouldOverwrite=shouldOverwrite
    self.createIntermediateDirectories=createIntermediateDirectories
    self.preserveAttributes=preserveAttributes
  }
}

/**
 # Secure File Options

 Base options for secure file operations.

 ## Alpha Dot Five Architecture

 This type follows the Alpha Dot Five architecture principles:
 - Uses immutable structs for thread safety
 - Provides clear, well-documented options
 - Uses British spelling in documentation
 */
public struct SecureFileOptions: Sendable, Equatable {
  /// The encryption algorithm to use
  public enum EncryptionAlgorithm: String, Sendable, Equatable {
    case aes256="AES-256"
    case chaChaPoly="ChaCha20-Poly1305"
  }

  /// The encryption algorithm to use
  public let encryptionAlgorithm: EncryptionAlgorithm

  /// Whether to use secure memory for cryptographic operations
  public let useSecureMemory: Bool

  /// Creates new secure file options
  public init(
    encryptionAlgorithm: EncryptionAlgorithm = .aes256,
    useSecureMemory: Bool=true
  ) {
    self.encryptionAlgorithm=encryptionAlgorithm
    self.useSecureMemory=useSecureMemory
  }
}

/**
 # Secure File Write Options

 Options for secure file write operations.

 ## Alpha Dot Five Architecture

 This type follows the Alpha Dot Five architecture principles:
 - Uses immutable structs for thread safety
 - Provides clear, well-documented options
 - Uses British spelling in documentation
 */
public struct SecureFileWriteOptions: Sendable, Equatable {
  /// The base secure file options
  public let secureOptions: SecureFileOptions

  /// The standard file write options
  public let writeOptions: FileWriteOptions

  /// Creates new secure file write options
  public init(
    secureOptions: SecureFileOptions=SecureFileOptions(),
    writeOptions: FileWriteOptions=FileWriteOptions()
  ) {
    self.secureOptions=secureOptions
    self.writeOptions=writeOptions
  }
}

/**
 # Secure File Read Options

 Options for secure file read operations.

 ## Alpha Dot Five Architecture

 This type follows the Alpha Dot Five architecture principles:
 - Uses immutable structs for thread safety
 - Provides clear, well-documented options
 - Uses British spelling in documentation
 */
public struct SecureFileReadOptions: Sendable, Equatable {
  /// The base secure file options
  public let secureOptions: SecureFileOptions

  /// Whether to verify file integrity before reading
  public let verifyIntegrity: Bool

  /// Creates new secure file read options
  public init(
    secureOptions: SecureFileOptions=SecureFileOptions(),
    verifyIntegrity: Bool=true
  ) {
    self.secureOptions=secureOptions
    self.verifyIntegrity=verifyIntegrity
  }
}

/**
 # Secure Deletion Options

 Options for secure file deletion.

 ## Alpha Dot Five Architecture

 This type follows the Alpha Dot Five architecture principles:
 - Uses immutable structs for thread safety
 - Provides clear, well-documented options
 - Uses British spelling in documentation
 */
public struct SecureDeletionOptions: Sendable, Equatable {
  /// The number of overwrite passes to perform
  public let overwritePasses: Int

  /// Whether to use random data for overwriting
  public let useRandomData: Bool

  /// Creates new secure deletion options
  public init(
    overwritePasses: Int=3,
    useRandomData: Bool=true
  ) {
    self.overwritePasses=overwritePasses
    self.useRandomData=useRandomData
  }
}

/**
 # Secure File Permissions

 Secure file permissions settings.

 ## Alpha Dot Five Architecture

 This type follows the Alpha Dot Five architecture principles:
 - Uses immutable structs for thread safety
 - Provides clear, well-documented options
 - Uses British spelling in documentation
 */
public struct SecureFilePermissions: Sendable, Equatable {
  /// The POSIX permissions to set
  public let posixPermissions: Int16

  /// Whether the file should be readable only by the owner
  public let ownerReadOnly: Bool

  /// Creates new secure file permissions
  public init(
    posixPermissions: Int16=0o600, // Owner read/write only
    ownerReadOnly: Bool=false
  ) {
    self.posixPermissions=posixPermissions
    self.ownerReadOnly=ownerReadOnly
  }
}
