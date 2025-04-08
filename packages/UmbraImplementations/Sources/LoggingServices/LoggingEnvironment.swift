import Foundation
import LoggingTypes

/**
 Re-export of the DeploymentEnvironment from LoggingTypes.
 
 This file ensures backward compatibility with code that imports DeploymentEnvironment
 from LoggingServices while centralizing the actual definition in LoggingTypes.
 */
public typealias DeploymentEnvironment = LoggingTypes.DeploymentEnvironment
