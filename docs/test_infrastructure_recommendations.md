# UmbraCore Test Infrastructure Refactor

This document outlines a comprehensive plan for improving the test infrastructure of the UmbraCore project, focusing on three key areas:

1. Reorganizing tests into a consistent structure
2. Increasing test coverage across the project
3. Integrating with Codecov for coverage reporting

## 1. Reorganizing Tests into a Consistent Structure

The current test structure has tests split between a top-level `/Tests` directory and module-specific `/Sources/Module/Tests` directories. This mixed approach creates confusion and makes maintenance difficult.

### Recommendations

#### 1.1 Consolidate all tests in the `/Tests` directory

```
/Tests
  /UnitTests
    /CoreErrors
    /ErrorHandling
    /KeyManagement
    ...
  /IntegrationTests
    /Security
    /XPC
    ...
  /TestKit
    /Mocks
    /TestHelpers
    /TestData
```

#### 1.2 Update Bazel BUILD files

- Create a single BUILD.bazel in each test directory with proper dependencies
- Maintain consistent naming patterns: `ModuleNameTests` for the package
- Example structure for a test BUILD file:

```python
swift_test(
    name = "ModuleNameTests",
    srcs = glob(["**/*.swift"]),
    deps = [
        "//Sources/ModuleName",
        "//Tests/TestKit",
        "@SwiftProtobuf//:SwiftProtobuf",
        # Other dependencies
    ],
    visibility = ["//visibility:public"],
)
```

#### 1.3 Migration Strategy

- Move tests in steps, module by module
- Update the `team-utils/test_targets.txt` after each migration
- Verify tests still pass after each migration
- Consider writing a migration script to automate this process

## 2. Increasing Test Coverage

The current test coverage appears to be inconsistent across modules, with some areas having thorough testing while others have minimal or no tests.

### Recommendations

#### 2.1 Set up coverage measurement

- Add coverage instrumentation to Bazel test commands:
  ```
  --coverage
  --instrumentation_filter=//Sources/...
  --test_output=errors
  --experimental_coverage_report_format=lcov
  ```

#### 2.2 Establish coverage targets

- Set initial coverage targets based on current state (e.g., 70%)
- Gradually increase targets as you add tests (e.g., to 80% and then 90%)
- Prioritize security-related modules for higher coverage targets

#### 2.3 Add tests for untested components

- Focus first on critical security-related modules
- Create comprehensive test plans for Foundation-independent modules
- Address disabled tests (like the ResticCLIHelperTests)
- Document known issues and constraints for testing concurrent code

#### 2.4 Implement different test types

- **Unit tests** for individual components
- **Integration tests** for module interactions
- **Property-based tests** where appropriate
- **XPC communication tests** for service boundaries
- **Concurrency tests** for actor-based components

#### 2.5 Add test documentation

- Add docstrings to test classes and methods explaining test purpose and strategy
- Document any non-obvious test setup or teardown logic
- Use consistent patterns for mocking and dependency injection

## 3. Integrating with Codecov

Adding Codecov support will provide visibility into test coverage and help identify areas needing improvement.

### Recommendations

#### 3.1 Update the CI configuration

Add the following steps to the `run-tests` workflow in `ci_config.yml`:

```yaml
run-tests:
  # Existing configuration...
  steps:
    # After running tests...
    - name: Generate Coverage Reports
      run: |
        # Run tests with coverage instrumentation
        bazelisk coverage --combined_report=lcov --coverage_report_generator=@bazel_tools//tools/test:coverage_report_generator --define=build_environment=nonlocal $(cat team-utils/test_targets.txt)
        # Process the generated LCOV files
        mkdir -p coverage_reports
        cp $(bazelisk info output_path)/_coverage/_coverage_report.dat ./coverage_reports/lcov.info
    
    - name: Upload Coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        files: ./coverage_reports/lcov.info
        fail_ci_if_error: false
        verbose: true
```

#### 3.2 Add Codecov configuration file

Create a `codecov.yml` file at the root of your project:

```yaml
# codecov.yml
codecov:
  require_ci_to_pass: yes

coverage:
  precision: 2
  round: down
  range: "70...90"
  status:
    project:
      default:
        target: 75%
        threshold: 1%
    patch:
      default:
        target: 75%
        threshold: 1%

ignore:
  - "Tests/**/*"
  - "**/*.generated.swift"
  - "Examples/**/*"
```

#### 3.3 Add Codecov badge

Add a Codecov badge to your README.md file to display coverage status:

```markdown
[![codecov](https://codecov.io/gh/your-organization/umbracore/branch/main/graph/badge.svg)](https://codecov.io/gh/your-organization/umbracore)
```

## 4. Addressing Specific Issues

### 4.1 Fix disabled ResticCLIHelperTests

- Address the actor isolation issues that are causing the tests to be skipped
- Consider using Swift concurrency testing tools or refactoring the actor design
- Add proper `@MainActor` annotations where needed
- Provide special test environments for actor-based components

### 4.2 Update the test_targets.txt file

- Many test directories are not listed in your test targets file
- This means they're not being run in CI
- Perform a comprehensive inventory of all test directories
- Update `team-utils/test_targets.txt` to include all tests

### 4.3 Create comprehensive test documentation

- Testing standards and conventions
- How to write effective tests for UmbraCore modules
- Guidelines for mocking and dependency injection
- Procedures for testing actor-based concurrent code

## 5. Implementation Timeline

### Phase 1: Preparation (Week 1-2)
- Set up coverage measurement
- Create Codecov integration
- Update test_targets.txt file

### Phase 2: Reorganization (Week 3-6)
- Migrate tests to the new directory structure
- Update Bazel BUILD files
- Ensure all tests still pass

### Phase 3: Coverage Improvement (Week 7-12)
- Identify modules with lowest coverage
- Create test plans for critical modules
- Implement missing tests
- Fix disabled tests

### Phase 4: Documentation and Refinement (Week 13-14)
- Create test documentation
- Set up coverage targets and badges
- Review and refine the test infrastructure

## 6. Maintenance and Best Practices

### 6.1 Test-driven development

- Write tests before implementing new features
- Ensure all bug fixes include a regression test
- Run tests locally before committing changes

### 6.2 Regular review

- Regularly review coverage reports
- Address gaps in coverage proactively
- Include test improvements in sprint planning

### 6.3 Test automation

- Ensure all tests run in CI
- Configure branch protection to require passing tests
- Set up automatic test execution on PR creation

## 7. Conclusion

Implementing these recommendations will significantly improve the UmbraCore test infrastructure by:
- Creating a more maintainable and consistent test organization
- Increasing test coverage to catch more potential issues
- Providing visibility into coverage metrics with Codecov
- Establishing clear standards and documentation for testing

These improvements align with the project's focus on high-quality, secure code and will help ensure the reliability of the UmbraCore platform as it continues to evolve.
