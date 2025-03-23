# UmbraCore Test Coverage Guide

This guide explains how to use the test coverage tools in the UmbraCore project.

## Overview

Test coverage is a measure of how much of your code is executed during tests. The UmbraCore project uses Bazel's built-in coverage instrumentation with LCOV reporting to track coverage. This coverage data is then uploaded to Codecov for visualisation and tracking over time.

## Coverage Tools

The following tools are available for working with test coverage:

1. **CI Coverage** - Automatically runs on GitHub Actions
2. **Local Coverage Measurement** - Using the `coverage_manager.sh` script
3. **Codecov Dashboard** - Web interface for analysing coverage

## Running Coverage Locally

The project includes a `coverage_manager.sh` script in the `tools` directory that simplifies working with test coverage.

### Basic Usage

To run all tests with coverage instrumentation and view the results:

```bash
./tools/coverage_manager.sh all
```

This will:
1. Run all tests with coverage instrumentation
2. Process the coverage data into an HTML report
3. Open the report in your default browser

### Targeting Specific Modules

To run coverage for a specific module:

```bash
./tools/coverage_manager.sh all --target //Sources/CoreErrors/Tests:CoreErrorsTests
```

### Filtering Coverage Reports

To focus coverage analysis on specific parts of the codebase:

```bash
./tools/coverage_manager.sh all --filter //Sources/SecurityImplementation/...
```

### Other Options

The script provides several other commands and options:

- `run` - Only run tests with coverage instrumentation
- `process` - Process existing coverage data into reports
- `view` - Open the HTML coverage report
- `--format` - Specify the report format (html or lcov)
- `--open` - Automatically open the report when complete

For a full list of options, run:

```bash
./tools/coverage_manager.sh help
```

## Interpreting Coverage Reports

The HTML coverage report provides a hierarchical view of your project with coverage statistics:

- **Line Coverage** - Percentage of lines executed during tests
- **Function Coverage** - Percentage of functions called during tests

Files are colour-coded:
- **Green** - High coverage (>80%)
- **Yellow** - Medium coverage (50-80%)
- **Red** - Low coverage (<50%)

You can click on any file to see line-by-line coverage information.

## Codecov Integration

UmbraCore uploads coverage data to Codecov after CI runs, which provides:

1. Coverage trends over time
2. Pull request coverage reports
3. Coverage comparison between branches
4. Detailed file and function coverage information

## Increasing Test Coverage

When working to increase test coverage:

1. Focus on critical modules first (especially security-related code)
2. Look for uncovered branches in conditionals
3. Test error paths, not just success paths
4. Ensure all public APIs have thorough test coverage

## Common Coverage Issues and Solutions

### Actor Isolation Warnings

Many Swift 6 actor isolation warnings can prevent tests from running. To address these:

1. Properly annotate test functions with `@MainActor` where needed
2. Use `actor.isolated { }` for accessing actor state safely
3. Add `@Sendable` annotations to closures crossing actor boundaries

### Disabled Tests

For tests like `ResticCLIHelperTests` that are disabled due to actor isolation issues:

1. Review the `setUpWithError()` method and remove the `XCTSkipIf(true, ...)` call
2. Address the actor isolation warnings that caused the test to be disabled
3. Consider refactoring the tested code to be more testable

### Missing Test Targets

Ensure all test targets are included in the `team-utils/test_targets.txt` file so they're run during CI.

## Best Practices

1. **Keep coverage high** - Aim for >80% coverage for critical modules
2. **Test edge cases** - Focus on error handling and boundary conditions
3. **Run coverage locally** before submitting pull requests
4. **Add tests for bugs** - Every bug fix should include a regression test
5. **Monitor the Codecov dashboard** to track coverage trends

## Further Reading

- [Bazel Coverage Documentation](https://bazel.build/reference/command-line-reference#coverage)
- [LCOV Documentation](https://github.com/linux-test-project/lcov)
- [Codecov Documentation](https://docs.codecov.io/)
