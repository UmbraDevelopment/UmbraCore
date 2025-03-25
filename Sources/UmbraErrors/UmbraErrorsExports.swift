// File renamed from Exports.swift to UmbraErrorsExports.swift
// More descriptive name that clearly indicates its purpose

// Do not export Foundation directly to avoid forcing Foundation dependency
// @_exported import Foundation

// Export all symbols from the submodules in a specific order
// Core module first to establish base protocols and types
@_exported import UmbraErrorsCore

// Then domain-specific errors and components
@_exported import Domains
@_exported import DTOs
@_exported import Mapping
