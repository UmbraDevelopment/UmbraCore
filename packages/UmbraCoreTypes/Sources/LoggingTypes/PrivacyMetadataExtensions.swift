// PrivacyMetadataExtensions.swift
// Part of the Alpha Dot Five architecture for UmbraCore
//
// Copyright 2025 MPY. All rights reserved.

import Foundation

/// Extensions for converting between privacy-aware metadata types
extension PrivacyMetadata {
    /// Convert PrivacyMetadata to LogMetadata for logging
    ///
    /// This method flattens privacy-annotated values to regular strings
    /// while respecting the privacy level of each entry.
    ///
    /// - Returns: LogMetadata suitable for use with logging methods
    public func toLogMetadata() -> LogMetadata {
        var result = LogMetadata()
        
        for (key, value) in storage {
            // Extract the string value according to privacy level
            result[key] = value.valueString
        }
        
        return result
    }
}

/// Extensions for LogContextDTO to simplify conversion
extension LogContextDTO {
    /// Convert context metadata to LogMetadata
    ///
    /// - Returns: LogMetadata suitable for logging methods
    public func asLogMetadata() -> LogMetadata {
        return toPrivacyMetadata().toLogMetadata()
    }
}
