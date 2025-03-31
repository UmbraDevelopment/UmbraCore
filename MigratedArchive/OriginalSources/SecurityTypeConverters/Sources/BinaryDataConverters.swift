import CoreTypesInterfaces
import FoundationBridgeTypes
import UmbraCoreTypes

// MARK: - BinaryData Extensions

extension CoreTypesInterfaces.BinaryData {
  /// Convert to SecureBytes for use in security operations
  /// - Returns: SecureBytes representation of this data
  public func toSecureBytes() -> UmbraCoreTypes.SecureBytes {
    UmbraCoreTypes.SecureBytes(bytes: rawBytes)
  }

  /// Convert to DataBridge for cross-module compatibility
  /// - Returns: DataBridge representation of this data
  public func toDataBridge() -> DataBridge {
    DataBridge(rawBytes)
  }

  /// Create from SecureBytes
  /// - Parameter secureBytes: The SecureBytes to convert
  /// - Returns: BinaryData representation
  public static func from(secureBytes: UmbraCoreTypes.SecureBytes) -> CoreTypesInterfaces
  .BinaryData {
    // Access each byte in the secure bytes and create a new array
    var bytes=[UInt8]()
    for i in 0..<secureBytes.count {
      bytes.append(secureBytes[i])
    }
    return CoreTypesInterfaces.BinaryData(bytes: bytes)
  }

  /// Create from DataBridge
  /// - Parameter bridge: The DataBridge to convert
  /// - Returns: BinaryData representation
  public static func from(bridge: DataBridge) -> CoreTypesInterfaces.BinaryData {
    CoreTypesInterfaces.BinaryData(bytes: bridge.bytes)
  }
}

// MARK: - SecureBytes Extensions

extension UmbraCoreTypes.SecureBytes {
  /// Convert to BinaryData
  /// - Returns: BinaryData representation of these bytes
  public func toBinaryData() -> CoreTypesInterfaces.BinaryData {
    // Access each byte in the secure bytes and create a new array
    var bytes=[UInt8]()
    for i in 0..<count {
      bytes.append(self[i])
    }
    return CoreTypesInterfaces.BinaryData(bytes: bytes)
  }

  /// Convert to DataBridge for cross-module compatibility
  /// - Returns: DataBridge representation of these bytes
  public func toDataBridge() -> DataBridge {
    // Access each byte in the secure bytes and create a new array
    var bytes=[UInt8]()
    for i in 0..<count {
      bytes.append(self[i])
    }
    return DataBridge(bytes)
  }
}

// MARK: - DataBridge Extensions

extension DataBridge {
  /// Convert to BinaryData
  /// - Returns: BinaryData representation of this bridge
  public func toBinaryData() -> CoreTypesInterfaces.BinaryData {
    CoreTypesInterfaces.BinaryData(bytes: bytes)
  }

  /// Convert to SecureBytes
  /// - Returns: SecureBytes representation of this bridge
  public func toSecureBytes() -> UmbraCoreTypes.SecureBytes {
    UmbraCoreTypes.SecureBytes(bytes: bytes)
  }
}
