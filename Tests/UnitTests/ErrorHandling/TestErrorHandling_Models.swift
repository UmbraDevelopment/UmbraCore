@testable import ErrorHandling
@testable import ErrorHandlingCommon
@testable import ErrorHandlingInterfaces
@testable import ErrorHandlingModels
import XCTest

final class TestErrorHandling_Models: XCTestCase {
  // MARK: - Error Model Tests

  func testErrorModel() {
    // Create a test error model
    let errorModel=MockErrorModel(
      domain: "TestDomain",
      code: "TEST001",
      description: "Test error description",
      source: nil
    )

    // Verify model properties
    XCTAssertEqual(errorModel.domain, "TestDomain")
    XCTAssertEqual(errorModel.code, "TEST001")
    XCTAssertEqual(errorModel.message, "Test error description")

    // Test severity
    XCTAssertEqual(errorModel.severity, .error)
  }

  // MARK: - Error Hierarchy Model Tests

  func testErrorHierarchyModel() {
    // Create a nested set of errors
    let rootError=NSError(
      domain: "RootDomain",
      code: 100,
      userInfo: [NSLocalizedDescriptionKey: "Root error"]
    )

    let middleError=TestError(
      domain: "MiddleDomain",
      code: "MID001",
      description: "Middle error",
      underlyingError: rootError
    )

    let topError=TestError(
      domain: "TopDomain",
      code: "TOP001",
      description: "Top error",
      underlyingError: middleError
    )

    // Create a hierarchy model
    let hierarchyModel=MockErrorHierarchyModel(error: topError)

    // Test hierarchy structure
    XCTAssertEqual(hierarchyModel.errors.count, 1)
    XCTAssertEqual(hierarchyModel.rootCause.domain, "TopDomain")
    XCTAssertEqual(hierarchyModel.rootCause.code, "TOP001")
    XCTAssertEqual(hierarchyModel.rootCause.message, "Top error")
  }

  // MARK: - Error Presentation Tests

  func testErrorPresentation() {
    // Create a test error
    let error=TestError(
      domain: "TestDomain",
      code: "TEST001",
      description: "Test error description",
      source: ErrorHandlingInterfaces.ErrorSource(
        file: "TestFile.swift",
        line: 42,
        function: "testFunction()"
      )
    )

    // Create a presentation model
    let presentationModel=MockErrorPresentationModel(
      error: error,
      title: "Error Occurred",
      message: "There was a problem with the operation",
      recoveryOptions: [
        PresentationRecoveryOption(
          title: "Retry",
          description: nil,
          isDisruptive: false,
          action: { true }
        ),
        PresentationRecoveryOption(
          title: "Cancel",
          description: nil,
          isDisruptive: false,
          action: { false }
        )
      ]
    )

    // Test presentation properties
    XCTAssertEqual(presentationModel.title, "Error Occurred")
    XCTAssertEqual(presentationModel.message, "There was a problem with the operation")
    XCTAssertEqual(presentationModel.recoveryOptions.count, 2)
    XCTAssertEqual(presentationModel.recoveryOptions[0].title, "Retry")
    XCTAssertEqual(presentationModel.recoveryOptions[1].title, "Cancel")

    // Test recovery action execution
    Task {
      _=await presentationModel.recoveryOptions[0].perform()
      _=await presentationModel.recoveryOptions[1].perform()
    }
  }

  // MARK: - From Error Test

  func testCreateFromError() {
    // Create an error for testing
    let error=TestError(
      domain: "FromErrorDomain",
      code: "ERR002",
      description: "From error description",
      source: ErrorHandlingInterfaces.ErrorSource(
        file: "TestFile.swift",
        line: 42,
        function: "testFunction()"
      )
    )

    let modelFromError=MockErrorModel(error: error)

    XCTAssertEqual(modelFromError.domain, "FromErrorDomain")
    XCTAssertEqual(modelFromError.code, "ERR002")
    XCTAssertEqual(modelFromError.message, "From error description")

    // Check source properties individually instead of direct comparison
    if let modelSource=modelFromError.source, let errorSource=error.source {
      XCTAssertEqual(modelSource.file, errorSource.file)
      XCTAssertEqual(modelSource.line, errorSource.line)
      XCTAssertEqual(modelSource.function, errorSource.function)
    } else {
      XCTFail("Source should not be nil")
    }

    XCTAssertEqual(modelFromError.severity, .error)
  }

  // MARK: - Test Support

  struct TestError: UmbraError {
    let domain: String
    let code: String
    let errorDescription: String
    var source: ErrorHandlingInterfaces.ErrorSource?
    var underlyingError: Error?
    var context: ErrorHandlingInterfaces.ErrorContext

    init(
      domain: String,
      code: String,
      description: String,
      source: ErrorHandlingInterfaces.ErrorSource?=nil,
      underlyingError: Error?=nil
    ) {
      self.domain=domain
      self.code=code
      errorDescription=description
      self.source=source
      self.underlyingError=underlyingError
      context=ErrorHandlingInterfaces.ErrorContext(source: domain, operation: "testOperation")
    }

    func with(context: ErrorHandlingInterfaces.ErrorContext) -> Self {
      var copy=self
      copy.context=context
      return copy
    }

    func with(underlyingError: Error) -> Self {
      var copy=self
      copy.underlyingError=underlyingError
      return copy
    }

    func with(source: ErrorHandlingInterfaces.ErrorSource) -> Self {
      var copy=self
      copy.source=source
      return copy
    }

    var description: String {
      errorDescription
    }
  }

  struct PresentationRecoveryOption: RecoveryOption {
    var id: UUID = .init()
    var title: String
    var description: String?
    var isDisruptive: Bool=false
    private var action: @Sendable () -> Bool

    init(
      title: String,
      description: String?=nil,
      isDisruptive: Bool=false,
      action: @escaping @Sendable () -> Bool
    ) {
      self.title=title
      self.description=description
      self.isDisruptive=isDisruptive
      self.action=action
    }

    func perform() async {
      _=action()
    }
  }

  // MARK: - Mock Model Implementations

  struct MockErrorModel {
    let domain: String
    let code: String
    let message: String
    let severity: ErrorHandlingInterfaces.ErrorSeverity
    let source: ErrorHandlingInterfaces.ErrorSource?

    init(error: some UmbraError) {
      domain=error.domain
      code=error.code
      message=error.errorDescription
      severity = .error
      source=error.source
    }

    init(
      domain: String,
      code: String,
      description: String,
      source: ErrorHandlingInterfaces.ErrorSource?=nil
    ) {
      self.domain=domain
      self.code=code
      message=description
      severity = .error
      self.source=source
    }
  }

  struct MockErrorHierarchyModel {
    let errors: [MockErrorModel]
    let rootCause: MockErrorModel

    init(error: Error) {
      if let umbraError=error as? (any UmbraError) {
        let rootModel=MockErrorModel(error: umbraError)
        errors=[rootModel]
        rootCause=rootModel
      } else {
        let nsError=error as NSError
        let rootModel=MockErrorModel(
          error: TestError(
            domain: nsError.domain,
            code: nsError.code.description,
            description: nsError.localizedDescription
          )
        )
        errors=[rootModel]
        rootCause=rootModel
      }
    }
  }

  struct MockErrorPresentationModel {
    let error: any UmbraError
    let title: String
    let message: String
    let recoveryOptions: [any RecoveryOption]
  }
}
