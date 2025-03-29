import Foundation
import Interfaces
import UmbraErrorsCore

// This file provides protocol conformance extensions to ensure
// that error types properly conform to UmbraError from the Interfaces module

// MARK: - Typealias for ErrorSource compatibility

/// Type bridge between UmbraErrorsCore.ErrorSource and Interfaces.ErrorSource
public typealias InterfacesErrorSource=UmbraErrorsCore.ErrorSource

// MARK: - Protocol Conformance Extensions

// We're now selectively enabling extensions that don't cause circular dependencies

// The following extensions are commented out temporarily while we resolve type issues

/*
 // MARK: - UmbraErrors.Network.Core Extensions

 extension UmbraErrors.Network.Core: Interfaces.UmbraError {
   // All required properties and methods are implemented directly on the type
 }

 // MARK: - UmbraErrors.Security.Core Extensions

 extension UmbraErrors.Security.Core: Interfaces.UmbraError {
   // All required properties and methods are implemented directly on the type
 }

 // MARK: - UmbraErrors.Repository.Core Extensions

 extension UmbraErrors.Repository.Core: Interfaces.UmbraError {
   // Add the missing code property required by the UmbraError protocol
   // This is already defined in the RepositoryCoreErrors.swift
 }

 // The Resource.Core extension is temporarily commented out to avoid circular dependencies
 // MARK: - UmbraErrors.Resource.Core Extensions

 extension UmbraErrors.Resource.Core: Interfaces.UmbraError {
   // All required properties and methods are implemented directly on the type
 }
 */
