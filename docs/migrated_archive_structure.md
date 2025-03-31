# MigratedArchive Structure Documentation

## Overview

The `MigratedArchive` directory is a centralised repository for modules that have been successfully migrated to the Alpha Dot Five architecture. This archive serves multiple purposes:

1. **Preserves Historical Code**: Maintains a snapshot of successfully migrated code for reference
2. **Reduces Source Directory Clutter**: Keeps the main `Sources` directory focused on active development
3. **Documents Migration Process**: Each archived module includes metadata about its migration
4. **Provides Reference Implementation**: Serves as a template for future migrations

## Directory Structure

Each migrated module follows this structure:

```
MigratedArchive/
├── ModuleName_<timestamp>/
│   ├── MIGRATION_INFO.json
│   ├── README_MIGRATION.md (optional)
│   └── [Original module structure preserved]
```

The timestamp suffix (`_<timestamp>`) ensures uniqueness and provides a reference for when the migration occurred.

## Migration Metadata

Each archived module contains a `MIGRATION_INFO.json` file with the following information:

- `module_name`: The name of the migrated module
- `migration_date`: Date when the module was migrated
- `original_path`: Path to the original module before migration
- `migrated_by`: Person or system responsible for migration
- `dependencies`: List of modules this module depends on
- `dependents`: List of modules that depend on this module
- `migration_status`: Status of the migration (typically "Completed")
- `notes`: Additional information about the migration

Example:
```json
{
  "module_name": "SecurityInterfaces",
  "migration_date": "2025-03-27",
  "original_path": "/Sources/SecurityInterfaces",
  "migrated_by": "Alpha Dot Five Migration Team",
  "dependencies": ["UmbraErrors", "CoreDTOs", "UserDefaults"],
  "dependents": [],
  "migration_status": "Completed",
  "notes": "Successfully migrated to Alpha Dot Five architecture with proper integration with UmbraErrors and UserDefaults."
}
```

## Migration Process

The migration process involves several steps:

1. **Identification**: Identify modules ready for migration (dependencies already migrated)
2. **Code Migration**: Update imports, fix circular dependencies, and ensure proper integration
3. **Build Verification**: Verify the module builds successfully with the new architecture
4. **Archiving**: Move the module to the MigratedArchive directory with appropriate metadata
5. **Documentation**: Update migration status and documentation

The archiving process is automated using the `migrate_to_archive.py` script located in the `alpha-tools/python` directory.

## Using the Migration Script

The migration script is used to automate the archiving process:

```bash
python alpha-tools/python/migrate_to_archive.py --module-name <module_name> --source-path <source_path>
```

This script:
- Creates a timestamped directory in the MigratedArchive
- Copies all files from the source directory to the archive
- Generates the MIGRATION_INFO.json file
- Creates a migration log

## Accessing Archived Code

While the code in MigratedArchive is preserved for reference, it should not be directly used in new development. Instead:

1. Use the migrated equivalent modules in the new Alpha Dot Five architecture
2. If needed, consult the archived code to understand the original implementation
3. Reference the migration logs to understand the changes made during migration

## Current Migrated Modules

The following modules have been successfully migrated and archived:

1. **UmbraErrors**: Core error handling module
2. **CoreDTOs**: Data transfer objects for core functionality
3. **UserDefaults**: User preferences management
4. **SecurityInterfaces**: Security provider interfaces and implementations
5. **Scheduling**: Task scheduling and management

Each module's migration status is also tracked in the `migration_status.json` file at the root of the repository.

## Future Work

As more modules are migrated to the Alpha Dot Five architecture, they will be added to the MigratedArchive. The goal is to eventually migrate all modules while maintaining backward compatibility during the transition period.

## Troubleshooting

If you encounter issues when using references to migrated modules:

1. Check the `migration_status.json` file to confirm the module has been fully migrated
2. Ensure you're using the new import paths for the migrated module
3. Review the module's `MIGRATION_INFO.json` file for any migration notes
4. Consult the migration log files (`migration_archive_log_*.txt`) for details on the migration process

## Maintenance

The MigratedArchive directory should be considered read-only. Any updates or fixes should be made to the active modules in the Alpha Dot Five architecture, not to the archived code.
