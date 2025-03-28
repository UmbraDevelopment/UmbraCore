import Foundation

/// Statistics about files in a backup snapshot
public struct FileStatistics: Sendable, Equatable {
    /// Total number of files
    public let totalFileCount: Int
    
    /// Total size of all files in bytes
    public let totalSize: UInt64
    
    /// Breakdown of files by type
    public let fileTypeBreakdown: [String: Int]
    
    /// Breakdown of files by size ranges
    public let fileSizeDistribution: SizeDistribution
    
    /// Creates a new file statistics object
    /// - Parameters:
    ///   - totalFileCount: Total number of files
    ///   - totalSize: Total size in bytes
    ///   - fileTypeBreakdown: Breakdown by type
    ///   - fileSizeDistribution: Size distribution
    public init(
        totalFileCount: Int,
        totalSize: UInt64,
        fileTypeBreakdown: [String: Int],
        fileSizeDistribution: SizeDistribution
    ) {
        self.totalFileCount = totalFileCount
        self.totalSize = totalSize
        self.fileTypeBreakdown = fileTypeBreakdown
        self.fileSizeDistribution = fileSizeDistribution
    }
    
    /// File size distribution ranges
    public struct SizeDistribution: Sendable, Equatable {
        /// Files smaller than 10KB
        public let tiny: Int
        
        /// Files between 10KB and 100KB
        public let small: Int
        
        /// Files between 100KB and 1MB
        public let medium: Int
        
        /// Files between 1MB and 10MB
        public let large: Int
        
        /// Files between 10MB and 100MB
        public let veryLarge: Int
        
        /// Files larger than 100MB
        public let huge: Int
        
        /// Creates a new size distribution
        /// - Parameters:
        ///   - tiny: <10KB
        ///   - small: 10KB-100KB
        ///   - medium: 100KB-1MB
        ///   - large: 1MB-10MB
        ///   - veryLarge: 10MB-100MB
        ///   - huge: >100MB
        public init(
            tiny: Int,
            small: Int,
            medium: Int,
            large: Int,
            veryLarge: Int,
            huge: Int
        ) {
            self.tiny = tiny
            self.small = small
            self.medium = medium
            self.large = large
            self.veryLarge = veryLarge
            self.huge = huge
        }
    }
}
