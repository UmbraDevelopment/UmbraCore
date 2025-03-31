package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
)

// PackageMapping maps source modules to target packages
type PackageMapping struct {
	SourceModule   string
	TargetPackage  string
	ImportModuleAs string // What the module should be imported as in the new structure
}

// BazelTarget represents a target returned by Bazel query
type BazelTarget struct {
	Name    string   `json:"name"`
	Rule    string   `json:"rule"`
	Tag     []string `json:"tag,omitempty"`
	Sources []string `json:"sources,omitempty"`
	Deps    []string `json:"deps,omitempty"`
}

// BazelQueryResult represents the result of a Bazel query
type BazelQueryResult struct {
	Target []BazelTarget `json:"target"`
}

// ValidDependency represents a valid dependency between packages
type ValidDependency struct {
	Source string
	Target string
}

// MigrationHelper helps migrate modules to the new package structure
type MigrationHelper struct {
	SourceDir       string
	TargetDir       string
	WorkspaceRoot   string
	DefaultMappings []PackageMapping
	ValidDeps       []ValidDependency
}

// NewMigrationHelper creates a new migration helper
func NewMigrationHelper(sourceDir, targetDir, workspaceRoot string) *MigrationHelper {
	// Define valid dependencies according to Alpha Dot Five structure
	validDeps := []ValidDependency{
		{"UmbraErrorKit", "UmbraCoreTypes"},
		{"UmbraInterfaces", "UmbraCoreTypes"},
		{"UmbraInterfaces", "UmbraErrorKit"},
		{"UmbraUtils", "UmbraCoreTypes"},
		{"UmbraImplementations", "UmbraInterfaces"},
		{"UmbraImplementations", "UmbraCoreTypes"},
		{"UmbraImplementations", "UmbraErrorKit"},
		{"UmbraImplementations", "UmbraUtils"},
		{"UmbraFoundationBridge", "UmbraCoreTypes"},
		{"ResticKit", "UmbraInterfaces"},
		{"ResticKit", "UmbraCoreTypes"},
		{"ResticKit", "UmbraUtils"},
	}

	// Define default package mappings
	defaultMappings := []PackageMapping{
		// Core Types
		{"CoreDTOs", "UmbraCoreTypes/CoreDTOs", "CoreDTOs"},
		{"KeyManagementTypes", "UmbraCoreTypes/KeyManagementTypes", "KeyManagementTypes"},
		{"ResticTypes", "UmbraCoreTypes/ResticTypes", "ResticTypes"},
		{"SecurityTypes", "UmbraCoreTypes/SecurityTypes", "SecurityTypes"},
		{"ServiceTypes", "UmbraCoreTypes/ServiceTypes", "ServiceTypes"},
		{"UmbraCoreTypes", "UmbraCoreTypes/Core", "UmbraCoreTypes"},

		// Error Kit
		{"ErrorHandling", "UmbraErrorKit/Implementation", "ErrorHandling"},
		{"ErrorHandlingInterfaces", "UmbraErrorKit/Interfaces", "ErrorInterfaces"},
		{"ErrorHandlingDomains", "UmbraErrorKit/Domains", "ErrorDomains"},
		{"ErrorTypes", "UmbraErrorKit/Types", "ErrorTypes"},
		{"UmbraErrors", "UmbraErrorKit/Core", "UmbraErrors"},

		// Interfaces
		{"SecurityInterfaces", "UmbraInterfaces/SecurityInterfaces", "SecurityInterfaces"},
		{"LoggingWrapperInterfaces", "UmbraInterfaces/LoggingInterfaces", "LoggingInterfaces"},
		{"FileSystemTypes", "UmbraInterfaces/FileSystemInterfaces", "FileSystemInterfaces"},
		{"XPCProtocolsCore", "UmbraInterfaces/XPCProtocolsCore", "XPCProtocolsCore"},
		{"CryptoInterfaces", "UmbraInterfaces/CryptoInterfaces", "CryptoInterfaces"},

		// Implementations
		{"UmbraSecurity", "UmbraImplementations/SecurityImpl", "SecurityImpl"},
		{"LoggingWrapper", "UmbraImplementations/LoggingImpl", "LoggingImpl"},
		{"FileSystemService", "UmbraImplementations/FileSystemImpl", "FileSystemImpl"},
		{"UmbraKeychainService", "UmbraImplementations/KeychainImpl", "KeychainImpl"},
		{"UmbraCryptoService", "UmbraImplementations/CryptoImpl", "CryptoImpl"},

		// Foundation Bridge
		{"ObjCBridgingTypes", "UmbraFoundationBridge/ObjCBridging", "ObjCBridging"},
		{"FoundationBridgeTypes", "UmbraFoundationBridge/CoreTypeBridges", "CoreTypeBridges"},

		// Restic Kit
		{"ResticCLIHelper", "ResticKit/CLIHelper", "CLIHelper"},
		{"ResticCLIHelperModels", "ResticKit/CommandBuilder", "CommandBuilder"},
		{"RepositoryManager", "ResticKit/RepositoryManager", "RepositoryManager"},

		// Utils
		{"DateTimeService", "UmbraUtils/DateUtils", "DateUtils"},
		{"NetworkService", "UmbraUtils/Networking", "Networking"},
	}

	return &MigrationHelper{
		SourceDir:       sourceDir,
		TargetDir:       targetDir,
		WorkspaceRoot:   workspaceRoot,
		DefaultMappings: defaultMappings,
		ValidDeps:       validDeps,
	}
}

// RunBazelQuery runs a Bazel query and returns the result
func (m *MigrationHelper) RunBazelQuery(query string) (*BazelQueryResult, error) {
	cmd := exec.Command("bazelisk", "query", "--output=json", query)
	cmd.Dir = m.WorkspaceRoot

	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("error running bazel query: %v", err)
	}

	var result BazelQueryResult
	if err := json.Unmarshal(output, &result); err != nil {
		return nil, fmt.Errorf("error parsing JSON output: %v", err)
	}

	return &result, nil
}

// GetModuleDependencies gets dependencies of a module using bazelisk query
func (m *MigrationHelper) GetModuleDependencies(moduleName string) ([]string, error) {
	query := fmt.Sprintf("deps(//Sources/%s:*)", moduleName)
	result, err := m.RunBazelQuery(query)
	if err != nil {
		return nil, fmt.Errorf("error querying dependencies: %v", err)
	}

	deps := []string{}
	for _, target := range result.Target {
		name := target.Name
		if strings.HasPrefix(name, "//Sources/") && strings.Contains(name, ":") {
			// Extract module name from target
			parts := strings.Split(name, "//Sources/")
			if len(parts) < 2 {
				continue
			}
			parts = strings.Split(parts[1], ":")
			module := parts[0]
			if module != moduleName && !contains(deps, module) {
				deps = append(deps, module)
			}
		}
	}

	return deps, nil
}

// CheckMigrationDependencies checks if all dependencies of a module have been migrated
func (m *MigrationHelper) CheckMigrationDependencies(moduleName, targetPackage string) (bool, []string) {
	// Extract target top-level package
	parts := strings.Split(targetPackage, "/")
	topLevelPackage := parts[0]

	deps, err := m.GetModuleDependencies(moduleName)
	if err != nil {
		fmt.Printf("Error getting dependencies: %v\n", err)
		return false, nil
	}

	if len(deps) == 0 {
		fmt.Printf("No dependencies found for %s\n", moduleName)
		return true, nil
	}

	missingDeps := []string{}
	for _, dep := range deps {
		// Skip dependencies that aren't mapped
		targetMapping := m.GetTargetMapping(dep)
		if targetMapping == nil {
			continue
		}

		depTargetPackage := targetMapping.TargetPackage
		depPackageParts := strings.Split(depTargetPackage, "/")
		depTopLevelPackage := depPackageParts[0]

		// Check if this dependency is valid according to Alpha Dot Five rules
		if depTopLevelPackage != topLevelPackage {
			isValid := false
			for _, validDep := range m.ValidDeps {
				if validDep.Source == topLevelPackage && validDep.Target == depTopLevelPackage {
					isValid = true
					break
				}
			}

			if !isValid {
				fmt.Printf("⚠️ Warning: %s depends on %s which maps to %s\n", moduleName, dep, depTargetPackage)
				fmt.Printf("   This would create an invalid dependency from %s to %s\n", topLevelPackage, depTopLevelPackage)
				fmt.Printf("   Valid dependencies for %s are: ", topLevelPackage)
				for i, validDep := range m.ValidDeps {
					if validDep.Source == topLevelPackage {
						if i > 0 {
							fmt.Printf(", ")
						}
						fmt.Printf("%s", validDep.Target)
					}
				}
				fmt.Println()
			}
		}

		// Check if the dependency has been migrated
		depPath := filepath.Join(m.TargetDir, depTargetPackage, "Sources")
		if !dirExists(depPath) || !dirHasSwiftFiles(depPath) {
			missingDeps = append(missingDeps, fmt.Sprintf("%s -> %s", dep, depTargetPackage))
		}
	}

	if len(missingDeps) > 0 {
		fmt.Printf("❌ The following dependencies of %s have not been migrated yet:\n", moduleName)
		for _, dep := range missingDeps {
			fmt.Printf("  • %s\n", dep)
		}
		fmt.Println("You should migrate these dependencies first to maintain proper dependency ordering.")
		return false, missingDeps
	}

	return true, nil
}

// GetTargetMapping gets the target mapping for a source module
func (m *MigrationHelper) GetTargetMapping(sourceModule string) *PackageMapping {
	for _, mapping := range m.DefaultMappings {
		if mapping.SourceModule == sourceModule {
			return &mapping
		}
	}
	return nil
}

// UpdateImports updates import statements in a Swift file
func (m *MigrationHelper) UpdateImports(filePath string, moduleMapping map[string]string) error {
	content, err := ioutil.ReadFile(filePath)
	if err != nil {
		return fmt.Errorf("error reading file: %v", err)
	}

	fileContent := string(content)

	// Find all import statements
	importPattern := regexp.MustCompile(`import\s+(\w+)`)
	matches := importPattern.FindAllStringSubmatch(fileContent, -1)

	// Replace imports according to mapping
	for _, match := range matches {
		if len(match) < 2 {
			continue
		}

		oldImport := match[1]
		if newImport, exists := moduleMapping[oldImport]; exists && newImport != oldImport {
			oldImportPattern := regexp.MustCompile(fmt.Sprintf(`import\s+%s\b`, oldImport))
			fileContent = oldImportPattern.ReplaceAllString(fileContent, fmt.Sprintf("import %s", newImport))
			fmt.Printf("Updated import: %s -> %s\n", oldImport, newImport)
		}
	}

	// Write updated content back to file
	if err := ioutil.WriteFile(filePath, []byte(fileContent), 0644); err != nil {
		return fmt.Errorf("error writing file: %v", err)
	}

	return nil
}

// MigrateModule migrates a module from the old structure to the new package structure
func (m *MigrationHelper) MigrateModule(moduleName, targetPackage string, skipDependencyCheck bool) (bool, error) {
	sourceModulePath := filepath.Join(m.SourceDir, moduleName)
	if !dirExists(sourceModulePath) {
		return false, fmt.Errorf("source module %s not found at %s", moduleName, sourceModulePath)
	}

	// Check dependencies unless skipped
	if !skipDependencyCheck {
		depsOk, _ := m.CheckMigrationDependencies(moduleName, targetPackage)
		if !depsOk {
			fmt.Printf("⚠️ Dependency check failed for %s\n", moduleName)
			fmt.Print("Do you want to continue anyway? (y/n): ")
			var response string
			fmt.Scanln(&response)
			if strings.ToLower(response) != "y" {
				return false, fmt.Errorf("migration aborted due to dependency check failure")
			}
		}
	}

	// Split target package into package name and subpackage path
	parts := strings.SplitN(targetPackage, "/", 2)
	packageName := parts[0]
	subpackage := ""
	if len(parts) > 1 {
		subpackage = parts[1]
	}

	// Create target directory
	targetModulePath := filepath.Join(m.TargetDir, packageName, "Sources")
	if subpackage != "" {
		targetModulePath = filepath.Join(targetModulePath, subpackage)
	}

	if err := os.MkdirAll(targetModulePath, 0755); err != nil {
		return false, fmt.Errorf("error creating target directory: %v", err)
	}

	// Prepare module mapping for import updates
	moduleMapping := make(map[string]string)
	for _, mapping := range m.DefaultMappings {
		moduleMapping[mapping.SourceModule] = mapping.ImportModuleAs
	}

	// Copy Swift files, excluding tests
	filesCopied := 0
	err := filepath.Walk(sourceModulePath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Skip tests and non-Swift files
		if info.IsDir() {
			if strings.Contains(path, "Tests") {
				return filepath.SkipDir
			}
			return nil
		}

		if !strings.HasSuffix(path, ".swift") || strings.HasSuffix(path, "Test.swift") {
			return nil
		}

		// Preserve subdirectory structure relative to the module
		relPath, err := filepath.Rel(sourceModulePath, filepath.Dir(path))
		if err != nil {
			return err
		}

		var targetFilePath string
		if relPath != "." {
			targetDir := filepath.Join(targetModulePath, relPath)
			if err := os.MkdirAll(targetDir, 0755); err != nil {
				return err
			}
			targetFilePath = filepath.Join(targetDir, filepath.Base(path))
		} else {
			targetFilePath = filepath.Join(targetModulePath, filepath.Base(path))
		}

		// Copy the file
		if err := copyFile(path, targetFilePath); err != nil {
			return err
		}

		filesCopied++
		fmt.Printf("Copied %s to %s\n", filepath.Base(path), targetFilePath)

		// Update imports
		if err := m.UpdateImports(targetFilePath, moduleMapping); err != nil {
			fmt.Printf("Warning: Error updating imports in %s: %v\n", targetFilePath, err)
		}

		return nil
	})

	if err != nil {
		return false, fmt.Errorf("error copying files: %v", err)
	}

	fmt.Printf("Migration complete: %d files copied\n", filesCopied)

	// Create or update BUILD file for the subpackage
	if err := m.CreateOrUpdateBuildFile(packageName, subpackage); err != nil {
		return false, fmt.Errorf("error creating BUILD file: %v", err)
	}

	return filesCopied > 0, nil
}

// CreateOrUpdateBuildFile creates or updates a BUILD.bazel file for a package or subpackage
func (m *MigrationHelper) CreateOrUpdateBuildFile(packageName, subpackage string) error {
	var buildDir, targetName string
	var visibility []string
	var deps []string

	if subpackage != "" {
		// Subpackage BUILD file
		buildDir = filepath.Join(m.TargetDir, packageName, "Sources", subpackage)
		parts := strings.Split(subpackage, "/")
		targetName = parts[len(parts)-1]
		visibility = []string{fmt.Sprintf("//packages/%s:__subpackages__", packageName)}

		// Determine dependencies based on package rules
		if packageName == "UmbraErrorKit" {
			if !strings.Contains(subpackage, "Interfaces") {
				deps = append(deps, "//packages/UmbraErrorKit/Sources/Interfaces")
			}
			if strings.Contains(subpackage, "Implementation") {
				deps = append(deps, "//packages/UmbraCoreTypes")
			}
		} else if packageName == "UmbraInterfaces" {
			if strings.Contains(subpackage, "SecurityInterfaces") {
				deps = append(deps, "//packages/UmbraCoreTypes")
				deps = append(deps, "//packages/UmbraErrorKit/Sources/Interfaces")
			}
		}
	} else {
		// Main package BUILD file
		buildDir = filepath.Join(m.TargetDir, packageName)
		targetName = packageName
		visibility = []string{"//visibility:public"}

		// Add standard dependencies based on package type
		if packageName == "UmbraErrorKit" {
			deps = append(deps, "//packages/UmbraCoreTypes")
		} else if packageName == "UmbraInterfaces" {
			deps = append(deps, "//packages/UmbraCoreTypes")
			deps = append(deps, "//packages/UmbraErrorKit")
		} else if packageName == "UmbraImplementations" {
			deps = append(deps, "//packages/UmbraInterfaces")
			deps = append(deps, "//packages/UmbraCoreTypes")
			deps = append(deps, "//packages/UmbraErrorKit")
		} else if packageName == "UmbraFoundationBridge" {
			deps = append(deps, "//packages/UmbraCoreTypes")
		} else if packageName == "ResticKit" {
			deps = append(deps, "//packages/UmbraInterfaces")
			deps = append(deps, "//packages/UmbraCoreTypes")
		} else if packageName == "UmbraUtils" {
			deps = append(deps, "//packages/UmbraCoreTypes")
		}
	}

	buildPath := filepath.Join(buildDir, "BUILD.bazel")

	// Only create the file if it doesn't exist or it's a subpackage (which gets recreated)
	if !fileExists(buildPath) || subpackage != "" {
		// Format dependencies for Starlark
		depsStr := ""
		if len(deps) > 0 {
			formattedDeps := make([]string, len(deps))
			for i, dep := range deps {
				formattedDeps[i] = fmt.Sprintf("        \"%s\"", dep)
			}
			depsStr = fmt.Sprintf("\n    deps = [\n%s,\n    ],", strings.Join(formattedDeps, ",\n"))
		}

		// Format glob pattern based on whether this is a subpackage
		globPattern := "\"*.swift\""
		if subpackage == "" {
			globPattern = "\"Sources/**/*.swift\""
		}

		// Format visibility for Starlark
		visibilityStr := make([]string, len(visibility))
		for i, v := range visibility {
			visibilityStr[i] = fmt.Sprintf("\"%s\"", v)
		}

		// Create BUILD file content
		buildContent := fmt.Sprintf(`load("//bazel:swift_rules.bzl", "umbra_swift_library")

umbra_swift_library(
    name = "%s",
    srcs = glob(
        [
            %s,
        ],
        allow_empty = False,
        exclude = [
            "**/Tests/**",
            "**/*Test.swift",
            "**/*.generated.swift",
        ],
        exclude_directories = 1,
    ),%s
    visibility = [%s],
)
`, targetName, globPattern, depsStr, strings.Join(visibilityStr, ", "))

		// Create parent directories if needed
		if err := os.MkdirAll(filepath.Dir(buildPath), 0755); err != nil {
			return fmt.Errorf("error creating directory: %v", err)
		}

		// Write the BUILD file
		if err := ioutil.WriteFile(buildPath, []byte(buildContent), 0644); err != nil {
			return fmt.Errorf("error writing BUILD file: %v", err)
		}

		// Run buildifier to ensure proper formatting
		cmd := exec.Command("buildifier", buildPath)
		if err := cmd.Run(); err != nil {
			fmt.Printf("Warning: Created BUILD file but buildifier formatting failed: %v\n", err)
		} else {
			fmt.Printf("Created and formatted BUILD file for %s\n", targetName)
		}
	}

	return nil
}

// Helper functions

// contains checks if a string is in a slice
func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}

// dirExists checks if a directory exists
func dirExists(path string) bool {
	info, err := os.Stat(path)
	if os.IsNotExist(err) {
		return false
	}
	return err == nil && info.IsDir()
}

// fileExists checks if a file exists
func fileExists(path string) bool {
	info, err := os.Stat(path)
	if os.IsNotExist(err) {
		return false
	}
	return err == nil && !info.IsDir()
}

// dirHasSwiftFiles checks if a directory contains Swift files
func dirHasSwiftFiles(path string) bool {
	files, err := ioutil.ReadDir(path)
	if err != nil {
		return false
	}

	for _, file := range files {
		if !file.IsDir() && strings.HasSuffix(file.Name(), ".swift") {
			return true
		}
	}
	return false
}

// copyFile copies a file from src to dst
func copyFile(src, dst string) error {
	input, err := ioutil.ReadFile(src)
	if err != nil {
		return err
	}
	return ioutil.WriteFile(dst, input, 0644)
}

func main() {
	sourceFlag := flag.String("source", "Sources", "Source directory containing old modules")
	targetFlag := flag.String("target", "packages", "Target directory for new packages")
	workspaceFlag := flag.String("workspace", "", "Workspace root for running Bazel queries")
	moduleFlag := flag.String("module", "", "Name of the module to migrate")
	destinationFlag := flag.String("destination", "", "Destination path in new structure (e.g., UmbraCoreTypes/KeyManagementTypes)")
	skipDepsFlag := flag.Bool("skip-deps", false, "Skip dependency validation")

	flag.Parse()

	if *moduleFlag == "" || *destinationFlag == "" {
		log.Fatal("Required flags: -module and -destination")
	}

	// Create absolute paths
	sourceDir := *sourceFlag
	if !filepath.IsAbs(sourceDir) {
		var err error
		sourceDir, err = filepath.Abs(sourceDir)
		if err != nil {
			log.Fatalf("Error getting absolute path: %v", err)
		}
	}

	targetDir := *targetFlag
	if !filepath.IsAbs(targetDir) {
		var err error
		targetDir, err = filepath.Abs(targetDir)
		if err != nil {
			log.Fatalf("Error getting absolute path: %v", err)
		}
	}

	workspaceRoot := *workspaceFlag
	if workspaceRoot == "" {
		// Use parent of source directory as default workspace root
		workspaceRoot = filepath.Dir(sourceDir)
	} else if !filepath.IsAbs(workspaceRoot) {
		var err error
		workspaceRoot, err = filepath.Abs(workspaceRoot)
		if err != nil {
			log.Fatalf("Error getting absolute path: %v", err)
		}
	}

	migrator := NewMigrationHelper(sourceDir, targetDir, workspaceRoot)
	success, err := migrator.MigrateModule(*moduleFlag, *destinationFlag, *skipDepsFlag)
	if err != nil {
		log.Fatalf("Error migrating module: %v", err)
	}

	if !success {
		os.Exit(1)
	}
}
