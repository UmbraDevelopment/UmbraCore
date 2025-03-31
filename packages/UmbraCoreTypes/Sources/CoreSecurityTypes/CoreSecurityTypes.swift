/**
 # CoreSecurityTypes Module

 This module provides foundational security-related types, DTOs, and error definitions for the UmbraCore security framework.
 It includes the fundamental building blocks used across the security subsystem, with particular focus on
 type safety and actor isolation support.

 ## Components

 - Error types for security operations
 - Data Transfer Objects (DTOs) for security configuration and results
 - Core security type definitions
 - Hash and encryption algorithm specifications

 All types in this module conform to `Sendable` to support safe usage across actor boundaries.
 */

// Export Foundation types needed by this module
@_exported import Foundation

@_exported import LoggingTypes

// Export dependencies
@_exported import UmbraErrors
