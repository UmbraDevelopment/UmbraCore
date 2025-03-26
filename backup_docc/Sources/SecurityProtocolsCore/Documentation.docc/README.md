# SecurityProtocolsCore Documentation

This directory contains DocC documentation for the SecurityProtocolsCore module.

## Structure

- `SecurityProtocolsCore.md`: Main landing page for the module documentation
- `SecureStorageProtocolMigration.md`: Migration guide for the SecureStorageProtocol consolidation
- `Resources/`: Directory for images and other resources used in documentation
- `Info.plist`: Configuration for the DocC documentation bundle
- `BUILD.bazel`: Build configuration for the documentation

## Building Documentation

You can build and preview the documentation locally using the `docc` command-line tool or via Xcode.

## Adding New Documentation

To add new topics or guides:

1. Create a new Markdown file in this directory
2. Add a reference to it in the appropriate section of `SecurityProtocolsCore.md`
3. Use the appropriate Metadata directives at the top of your file

## Migration Guides

Migration guides should include:

- Overview of the changes
- Benefits of the migration
- Step-by-step instructions
- Code examples
- Future considerations

## Documentation Standards

- Use British English for user-facing content
- Use clear, concise explanations
- Include code examples where appropriate
- Reference related documentation using DocC links
