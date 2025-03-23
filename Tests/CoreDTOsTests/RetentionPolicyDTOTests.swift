@testable import CoreDTOs
import XCTest

final class RetentionPolicyDTOTests: XCTestCase {
  // Test initialization with valid values
  func testInitialization() {
    // Arrange & Act
    let policy=RetentionPolicyDTO(
      keepLastSnapshots: 5,
      keepDailySnapshots: 7,
      keepWeeklySnapshots: 4,
      keepMonthlySnapshots: 3,
      keepYearlySnapshots: 2,
      minimumRetentionDays: 30
    )

    // Assert
    XCTAssertEqual(policy.keepLastSnapshots, 5)
    XCTAssertEqual(policy.keepDailySnapshots, 7)
    XCTAssertEqual(policy.keepWeeklySnapshots, 4)
    XCTAssertEqual(policy.keepMonthlySnapshots, 3)
    XCTAssertEqual(policy.keepYearlySnapshots, 2)
    XCTAssertEqual(policy.minimumRetentionDays, 30)
  }

  // Test the default policy factory method
  func testDefaultPolicyCreation() {
    // Arrange & Act
    let policy=RetentionPolicyDTO.defaultPolicy()

    // Assert
    XCTAssertEqual(policy.keepLastSnapshots, 3)
    XCTAssertEqual(policy.keepDailySnapshots, 7)
    XCTAssertEqual(policy.keepWeeklySnapshots, 4)
    XCTAssertEqual(policy.keepMonthlySnapshots, 3)
    XCTAssertEqual(policy.keepYearlySnapshots, 1)
    XCTAssertEqual(policy.minimumRetentionDays, 7)
  }

  // Test the essential policy factory method
  func testEssentialPolicyCreation() {
    // Arrange & Act
    let policy=RetentionPolicyDTO.essentialPolicy()

    // Assert
    XCTAssertEqual(policy.keepLastSnapshots, 1)
    XCTAssertEqual(policy.keepDailySnapshots, 2)
    XCTAssertEqual(policy.keepWeeklySnapshots, 1)
    XCTAssertEqual(policy.keepMonthlySnapshots, 1)
    XCTAssertEqual(policy.keepYearlySnapshots, 0)
    XCTAssertEqual(policy.minimumRetentionDays, 2)
  }

  // Test the extended policy factory method
  func testExtendedPolicyCreation() {
    // Arrange & Act
    let policy=RetentionPolicyDTO.extendedPolicy()

    // Assert
    XCTAssertEqual(policy.keepLastSnapshots, 5)
    XCTAssertEqual(policy.keepDailySnapshots, 14)
    XCTAssertEqual(policy.keepWeeklySnapshots, 8)
    XCTAssertEqual(policy.keepMonthlySnapshots, 12)
    XCTAssertEqual(policy.keepYearlySnapshots, 5)
    XCTAssertEqual(policy.minimumRetentionDays, 30)
  }

  // Test the unlimited policy factory method
  func testUnlimitedPolicyCreation() {
    // Arrange & Act
    let policy=RetentionPolicyDTO.unlimitedPolicy()

    // Assert
    XCTAssertEqual(policy.keepLastSnapshots, -1)
    XCTAssertEqual(policy.keepDailySnapshots, -1)
    XCTAssertEqual(policy.keepWeeklySnapshots, -1)
    XCTAssertEqual(policy.keepMonthlySnapshots, -1)
    XCTAssertEqual(policy.keepYearlySnapshots, -1)
    XCTAssertEqual(policy.minimumRetentionDays, -1)
  }

  // Test the Equatable implementation
  func testEquality() {
    // Arrange
    let policy1=RetentionPolicyDTO.defaultPolicy()
    let policy2=RetentionPolicyDTO.defaultPolicy()
    let policy3=RetentionPolicyDTO.essentialPolicy()

    // Assert
    XCTAssertEqual(policy1, policy2)
    XCTAssertNotEqual(policy1, policy3)
  }

  // Test with empty policy
  func testEmptyPolicy() {
    // Arrange & Act
    let policy=RetentionPolicyDTO.empty()

    // Assert
    XCTAssertEqual(policy.keepLastSnapshots, 0)
    XCTAssertEqual(policy.keepDailySnapshots, 0)
    XCTAssertEqual(policy.keepWeeklySnapshots, 0)
    XCTAssertEqual(policy.keepMonthlySnapshots, 0)
    XCTAssertEqual(policy.keepYearlySnapshots, 0)
    XCTAssertEqual(policy.minimumRetentionDays, 0)
  }

  // Test the custom policy with validation
  func testCustomPolicyWithValidation() {
    // Arrange & Act
    let policy=RetentionPolicyDTO.customPolicy(
      keepLastSnapshots: -5, // Should be converted to 0
      keepDailySnapshots: 7,
      keepWeeklySnapshots: 4,
      keepMonthlySnapshots: 3,
      keepYearlySnapshots: 2,
      minimumRetentionDays: -10 // Should be converted to 0
    )

    // Assert
    XCTAssertEqual(
      policy.keepLastSnapshots,
      0,
      "Negative values other than -1 should be converted to 0"
    )
    XCTAssertEqual(policy.keepDailySnapshots, 7)
    XCTAssertEqual(policy.keepWeeklySnapshots, 4)
    XCTAssertEqual(policy.keepMonthlySnapshots, 3)
    XCTAssertEqual(policy.keepYearlySnapshots, 2)
    XCTAssertEqual(
      policy.minimumRetentionDays,
      0,
      "Negative values other than -1 should be converted to 0"
    )
  }

  // Test the isUnlimited property
  func testIsUnlimitedProperty() {
    // Arrange
    let unlimitedPolicy=RetentionPolicyDTO.unlimitedPolicy()
    let defaultPolicy=RetentionPolicyDTO.defaultPolicy()

    // Assert
    XCTAssertTrue(unlimitedPolicy.isUnlimited)
    XCTAssertFalse(defaultPolicy.isUnlimited)
  }

  // Test the isEmpty property
  func testIsEmptyProperty() {
    // Arrange
    let emptyPolicy=RetentionPolicyDTO.empty()
    let defaultPolicy=RetentionPolicyDTO.defaultPolicy()

    // Assert
    XCTAssertTrue(emptyPolicy.isEmpty)
    XCTAssertFalse(defaultPolicy.isEmpty)
  }
}
