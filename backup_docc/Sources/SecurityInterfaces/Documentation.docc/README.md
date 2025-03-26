# SecurityInterfaces Documentation

This directory contains the DocC documentation for the SecurityInterfaces module.

## Structure

- `SecurityInterfaces.md`: Main documentation page for the module
- `SecurityInterfacesSymbols.md`: Documentation for important symbols
- `SecurityProviderProtocol.md`: Documentation for the security provider protocol
- `SecurityErrorMigration.md`: Guide for migrating security errors
- `ErrorHandlingGuide.md`: Guide for error handling
- `TypealiasRefactoring.md`: Guide for typealias refactoring

## Building Documentation

The documentation can be built using the UmbraCore tools:

```bash
cd /path/to/UmbraCore
tools/go/bin/docc --module SecurityInterfaces
```

This will create a DocC archive in the `docs` directory, which can be viewed by running:

```bash
xcrun docc preview docs/SecurityInterfacesDocC.doccarchive --allow-arbitrary-catalog-directories --port 8000
```

## CI/CD Integration

The documentation is automatically built and deployed by the GitHub Actions workflow defined in `.github/workflows/docc-documentation.yml`. When changes are pushed to main branches or documentation files are modified in pull requests, the documentation is rebuilt and deployed.
