import Foundation
@testable import UmbraKeychainService

enum MockXPCServiceHelper {
  private static let mockService=MockKeychainService()

  static func getServiceProxy() async throws -> any KeychainXPCProtocol {
    mockService
  }

  static func reset() async {
    await mockService.reset()
  }
}
