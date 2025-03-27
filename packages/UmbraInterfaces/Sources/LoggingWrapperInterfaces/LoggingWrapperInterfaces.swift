/// LoggingWrapperInterfaces Module
///
/// Provides protocol definitions for the logging system, following the Alpha Dot Five
/// architecture principle of separation between types, interfaces, and implementations.
///
/// This module is part of the Logger Isolation Pattern implemented in UmbraCore:
///
/// 1. **LoggingWrapperInterfaces** - This module containing only interfaces
///    - Has no implementation details or third-party dependencies
///    - Can be safely imported by any module
///
/// 2. **LoggingWrapperServices** - The implementation module
///    - Contains the actual logging implementation
///    - Should only be imported by modules that need the implementation
///
/// This pattern allows for the internal logging implementation to change without
/// breaking compatibility of modules using logging functionality.
