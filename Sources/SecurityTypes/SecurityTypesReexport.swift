// This file has been intentionally removed.
// Instead of using compatibility layers, we're directly updating references
// to point to the consolidated SecurityInterfaces module.

import Foundation
@_exported import SecurityInterfaces
@_exported import UmbraCoreTypes

/// This is a compatibility layer to maintain build support during the transition to
/// the consolidated SecurityInterfaces module.
///
/// All types from the legacy SecurityTypes module are now re-exported from the
/// SecurityInterfaces module. For new code, import SecurityInterfaces directly.
///
/// This module will be removed in a future UmbraCore release once all imports are updated.
///
/// NOTE: This compatibility layer exists only to prevent build breakage during
/// the consolidation process. It is intended as a temporary solution.
