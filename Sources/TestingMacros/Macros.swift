import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Macro that creates a test suite
public struct SuiteMacro: MemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf _: some DeclGroupSyntax,
    in _: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard
      let argument = node.arguments?.as(LabeledExprListSyntax.self)?.first?.expression,
      let stringLiteral = argument.as(StringLiteralExprSyntax.self)?.segments.first?
        .as(StringSegmentSyntax.self)?.content
    else {
      throw TestingMacroError.invalidArgument
    }

    return [
      """
      public var suiteName: String { "\(raw: stringLiteral)" }
      """
    ]
  }
}

/// Macro that marks a function as a test
public struct TestMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf _: some DeclSyntaxProtocol,
    in _: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard
      let argument = node.arguments?.as(LabeledExprListSyntax.self)?.first?.expression,
      let stringLiteral = argument.as(StringLiteralExprSyntax.self)?.segments.first?
        .as(StringSegmentSyntax.self)?.content
    else {
      throw TestingMacroError.invalidArgument
    }

    return []
  }
}

/// Macro that implements test assertions
public struct ExpectMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in _: some MacroExpansionContext
  ) throws -> ExprSyntax {
    guard let argument = node.argumentList.first?.expression else {
      throw TestingMacroError.invalidArgument
    }

    return "try Testing.assert(\(argument), message: \"Expectation failed\")"
  }
}

enum TestingMacroError: Error {
  case invalidArgument
}

@main
struct TestingMacrosPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    SuiteMacro.self,
    TestMacro.self,
    ExpectMacro.self
  ]
}
