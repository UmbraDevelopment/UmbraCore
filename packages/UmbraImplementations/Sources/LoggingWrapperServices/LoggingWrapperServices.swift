/// LoggingWrapperServices Module
///
/// Provides concrete implementations of the logging system, following the Alpha Dot Five
/// architecture principle of separation between types, interfaces, and implementations.
///
/// This module is part of the Logger Isolation Pattern implemented in UmbraCore:
///
/// 1. **LoggingWrapperInterfaces** - The module containing only interfaces
///    - Contains no implementation details or third-party dependencies
///    - Can be safely imported by any module requiring stability
///
/// 2. **LoggingWrapperServices** - This implementation module
///    - Contains the actual logging implementation
///    - Implements interfaces defined in LoggingWrapperInterfaces
///
/// This module wraps the SwiftyBeaver logging library to provide a consistent
/// and maintainable logging implementation for UmbraCore.
