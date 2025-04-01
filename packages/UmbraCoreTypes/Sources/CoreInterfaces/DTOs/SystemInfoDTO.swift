/// SystemInfoDTO
///
/// Represents information about the system environment in which
/// the UmbraCore framework is running. This includes operating system details,
/// hardware information, and runtime environment characteristics.
///
/// All properties are immutable to ensure thread safety when
/// passing instances between actors or across module boundaries.
public struct SystemInfoDTO: Sendable, Equatable {
  /// Operating system information
  public let operatingSystem: OperatingSystemInfo

  /// Hardware information
  public let hardware: HardwareInfo

  /// Runtime environment information
  public let runtime: RuntimeInfo

  /// Creates a new SystemInfoDTO instance
  /// - Parameters:
  ///   - operatingSystem: Operating system information
  ///   - hardware: Hardware information
  ///   - runtime: Runtime environment information
  public init(
    operatingSystem: OperatingSystemInfo,
    hardware: HardwareInfo,
    runtime: RuntimeInfo
  ) {
    self.operatingSystem=operatingSystem
    self.hardware=hardware
    self.runtime=runtime
  }
}

/// Operating system information
public struct OperatingSystemInfo: Sendable, Equatable {
  /// Operating system name (e.g., "macOS")
  public let name: String

  /// Operating system version (e.g., "14.0")
  public let version: String

  /// Build identifier (e.g., "23A344")
  public let buildID: String

  /// Creates a new OperatingSystemInfo instance
  /// - Parameters:
  ///   - name: Operating system name
  ///   - version: Operating system version
  ///   - buildId: Build identifier
  public init(name: String, version: String, buildID: String) {
    self.name=name
    self.version=version
    self.buildID=buildID
  }
}

/// Hardware information
public struct HardwareInfo: Sendable, Equatable {
  /// Model identifier (e.g., "MacBookPro18,3")
  public let model: String

  /// CPU architecture (e.g., "arm64", "x86_64")
  public let cpuArchitecture: String

  /// Number of CPU cores
  public let cpuCoreCount: UInt

  /// Physical memory in bytes
  public let memoryBytes: UInt64

  /// Creates a new HardwareInfo instance
  /// - Parameters:
  ///   - model: Model identifier
  ///   - cpuArchitecture: CPU architecture
  ///   - cpuCoreCount: Number of CPU cores
  ///   - memoryBytes: Physical memory in bytes
  public init(
    model: String,
    cpuArchitecture: String,
    cpuCoreCount: UInt,
    memoryBytes: UInt64
  ) {
    self.model=model
    self.cpuArchitecture=cpuArchitecture
    self.cpuCoreCount=cpuCoreCount
    self.memoryBytes=memoryBytes
  }
}

/// Runtime environment information
public struct RuntimeInfo: Sendable, Equatable {
  /// Application bundle identifier
  public let bundleIdentifier: String

  /// Application version
  public let applicationVersion: String

  /// Process identifier
  public let processID: UInt

  /// User locale identifier (e.g., "en_GB")
  public let localeIdentifier: String

  /// Creates a new RuntimeInfo instance
  /// - Parameters:
  ///   - bundleIdentifier: Application bundle identifier
  ///   - applicationVersion: Application version
  ///   - processId: Process identifier
  ///   - localeIdentifier: User locale identifier
  public init(
    bundleIdentifier: String,
    applicationVersion: String,
    processID: UInt,
    localeIdentifier: String
  ) {
    self.bundleIdentifier=bundleIdentifier
    self.applicationVersion=applicationVersion
    self.processID=processID
    self.localeIdentifier=localeIdentifier
  }
}
