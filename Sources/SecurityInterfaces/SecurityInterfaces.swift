/// SecurityInterfaces module
///
/// This module provides the core security interfaces and protocols for the UmbraCore framework.
/// It contains interfaces for security operations across the system.
///
/// Note: For Foundation-dependent interfaces, we've created a layered architecture with
/// SecurityInterfacesProtocols (foundation-free) at the base, SecurityInterfacesBase building on
/// top,
/// and SecurityInterfaces providing the high-level interfaces.
@_exported import SecurityInterfacesBase
@_exported import SecurityInterfacesProtocols
import UmbraCoreTypes
@_exported import UmbraErrors
@_exported import UmbraErrorsCore
import XPCProtocolsCore
