/// LoggingAdapters Module
///
/// This module provides adapter implementations that connect the core logging interfaces
/// to their underlying implementations. Following the Alpha Dot Five architecture pattern,
/// this module belongs to the implementations layer and provides concrete adapter implementations.
///
/// The adapters in this module bridge between:
/// - LoggingInterfaces (core logging protocols)
/// - LoggingWrapperInterfaces (wrapper protocols)
/// - LoggingWrapperServices (concrete implementations)
///
/// This adapter pattern helps maintain clean separation between the logging interfaces
/// defined in LoggingInterfaces and their implementations.
