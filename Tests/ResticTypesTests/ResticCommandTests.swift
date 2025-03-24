@testable import ResticTypes
import XCTest

/// Test implementation of ResticCommand
private struct TestResticCommand: ResticCommand {
  let commandName: String
  let commandArguments: [String]
  let environment: [String: String]
  let options: CommonOptions

  init(
    command: String,
    arguments: [String],
    environment: [String: String],
    requiredEnvironmentVariables _: Set<String>
  ) {
    commandName=command
    commandArguments=arguments
    self.environment=environment
    options=CommonOptions(repository: "/test/repo", password: "test-password")
  }

  func validate() throws {
    guard !commandName.isEmpty else {
      throw ResticError.invalidConfiguration("Command cannot be empty")
    }
  }

  // Fix: provide correct implementation for arguments property to match protocol
  var arguments: [String] {
    var args=[String]()
    args.append(commandName)
    args.append(contentsOf: commandArguments)
    return args
  }
}

final class ResticCommandTests: XCTestCase {
  func testValidCommand() throws {
    let command=TestResticCommand(
      command: "backup",
      arguments: ["--tag", "test"],
      environment: ["RESTIC_PASSWORD": "test"],
      requiredEnvironmentVariables: ["RESTIC_PASSWORD"]
    )

    XCTAssertNoThrow(try command.validate())
    XCTAssertEqual(command.commandName, "backup")
    XCTAssertEqual(command.commandArguments, ["--tag", "test"])
  }

  func testInvalidCommand() {
    let command=TestResticCommand(
      command: "",
      arguments: [],
      environment: [:],
      requiredEnvironmentVariables: []
    )

    XCTAssertThrowsError(try command.validate()) { error in
      guard let resticError=error as? ResticError else {
        XCTFail("Expected ResticError")
        return
      }

      switch resticError {
        case let .invalidConfiguration(message):
          XCTAssertEqual(message, "Command cannot be empty")
        default:
          XCTFail("Expected invalidConfiguration error")
      }
    }
  }

  func testCommandArguments() {
    let command=TestResticCommand(
      command: "backup",
      arguments: ["--tag", "test"],
      environment: ["RESTIC_PASSWORD": "test"],
      requiredEnvironmentVariables: ["RESTIC_PASSWORD"]
    )

    let args=command.arguments
    XCTAssertEqual(args.first, "backup")
    XCTAssertTrue(args.contains("--tag"))
    XCTAssertTrue(args.contains("test"))
  }
}
