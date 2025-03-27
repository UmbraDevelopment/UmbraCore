/**
 # SecurityInterfaces Module

 This module provides the core security interfaces and protocols for the UmbraCore framework.
 It contains interfaces for security operations across the system.

 ## Overview
 The SecurityInterfaces module includes:
 - Security protocols for cryptographic operations
 - Data Transfer Objects (DTOs) for security data exchange
 - Type definitions for security-related operations
 - XPC service interfaces for secure inter-process communication

 ## Module Structure
 The module is organised in a hierarchical manner:
 - DTOs: Data Transfer Objects for security operations
 - Protocols: Core, Foundation, and Composition protocols
 - Types: Common types, errors, and models for security
 - XPC: Modern XPC service implementations and protocols
 - Adapters: Adapter patterns for security interfaces
 - Models: Domain models for security operations
 */

import Foundation

// Export Foundation types needed for SecurityInterfaces
@_exported import Foundation

// Export UmbraErrors for error handling
@_exported import UmbraErrors

// Export UserDefaults for preference management
@_exported import UserDefaults

// Export SecurityTypes for type definitions
@_exported import SecurityTypes
