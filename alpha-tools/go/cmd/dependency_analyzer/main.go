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
	"strings"
)

// ValidDependency represents a valid dependency between packages
type ValidDependency struct {
	Source string
	Target string
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

// DependencyAnalyzer analyzes Bazel dependencies
type DependencyAnalyzer struct {
	WorkspaceRoot string
	PackagesDir   string
	ValidDeps     []ValidDependency
}

// NewDependencyAnalyzer creates a new dependency analyzer
func NewDependencyAnalyzer(workspaceRoot, packagesDir string) *DependencyAnalyzer {
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

	return &DependencyAnalyzer{
		WorkspaceRoot: workspaceRoot,
		PackagesDir:   packagesDir,
		ValidDeps:     validDeps,
	}
}

// RunBazelQuery runs a Bazel query and returns the result
func (a *DependencyAnalyzer) RunBazelQuery(query string) (*BazelQueryResult, error) {
	cmd := exec.Command("bazelisk", "query", "--output=json", query)
	cmd.Dir = a.WorkspaceRoot

	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("error running bazel query: %v: %v", err, string(output))
	}

	var result BazelQueryResult
	if err := json.Unmarshal(output, &result); err != nil {
		return nil, fmt.Errorf("error parsing JSON output: %v", err)
	}

	return &result, nil
}

// ParseTargetPackage extracts the package name from a target
func (a *DependencyAnalyzer) ParseTargetPackage(target string) string {
	// Strip leading // and trailing :target if present
	if strings.HasPrefix(target, "//") {
		target = target[2:]
	}

	if idx := strings.Index(target, ":"); idx >= 0 {
		target = target[:idx]
	}

	// Extract the top-level package name
	if strings.HasPrefix(target, "packages/") {
		parts := strings.Split(target, "/")
		if len(parts) > 1 {
			return parts[1] // Return the package name (UmbraCoreTypes, etc.)
		}
	}

	return ""
}

// IsDependencyValid checks if a dependency is valid
func (a *DependencyAnalyzer) IsDependencyValid(source, target string) bool {
	if source == target {
		return true // Self-dependencies are allowed
	}

	for _, dep := range a.ValidDeps {
		if dep.Source == source && dep.Target == target {
			return true
		}
	}
	return false
}

// GetValidDependenciesFor returns valid dependencies for a package
func (a *DependencyAnalyzer) GetValidDependenciesFor(pkg string) []string {
	deps := []string{}
	for _, dep := range a.ValidDeps {
		if dep.Source == pkg {
			deps = append(deps, dep.Target)
		}
	}
	return deps
}

// AnalyzeDependencies analyzes dependencies between packages
func (a *DependencyAnalyzer) AnalyzeDependencies() (bool, error) {
	// Get all targets in packages directory
	result, err := a.RunBazelQuery("//packages/...")
	if err != nil {
		return false, fmt.Errorf("error querying packages: %v", err)
	}

	if result == nil || len(result.Target) == 0 {
		fmt.Println("No targets found in packages directory")
		return true, nil
	}

	// Track dependencies by package
	packageDeps := make(map[string]map[string]bool)

	// Process each target
	for _, target := range result.Target {
		sourcePkg := a.ParseTargetPackage(target.Name)
		if sourcePkg == "" {
			continue
		}

		// Initialize dependency map if needed
		if _, exists := packageDeps[sourcePkg]; !exists {
			packageDeps[sourcePkg] = make(map[string]bool)
		}

		// Query dependencies for this target
		depsResult, err := a.RunBazelQuery(fmt.Sprintf("deps(%s)", target.Name))
		if err != nil {
			fmt.Printf("Warning: Error querying dependencies for %s: %v\n", target.Name, err)
			continue
		}

		for _, depTarget := range depsResult.Target {
			targetPkg := a.ParseTargetPackage(depTarget.Name)
			if targetPkg != "" && targetPkg != sourcePkg {
				// Only track dependencies between Alpha Dot Five packages
				// Check if it's a known package
				isKnown := false
				for _, dep := range a.ValidDeps {
					if dep.Source == targetPkg || dep.Target == targetPkg {
						isKnown = true
						break
					}
				}
				if isKnown || targetPkg == "UmbraCoreTypes" {
					packageDeps[sourcePkg][targetPkg] = true
				}
			}
		}
	}

	// Validate dependencies
	invalidCount := 0
	for sourcePkg, deps := range packageDeps {
		for targetPkg := range deps {
			if !a.IsDependencyValid(sourcePkg, targetPkg) {
				invalidCount++
				fmt.Printf("❌ INVALID DEPENDENCY: %s depends on %s\n", sourcePkg, targetPkg)
				fmt.Printf("   This violates the Alpha Dot Five dependency rules.\n")
				fmt.Printf("   Valid dependencies for %s are:\n", sourcePkg)
				for _, validDep := range a.GetValidDependenciesFor(sourcePkg) {
					fmt.Printf("   - %s\n", validDep)
				}
				fmt.Println()
			}
		}
	}

	if invalidCount == 0 {
		fmt.Println("✅ All dependencies conform to Alpha Dot Five structure.")
		return true, nil
	} else {
		fmt.Printf("❌ Found %d invalid dependencies.\n", invalidCount)
		return false, nil
	}
}

// GenerateDependencyGraph generates a DOT format dependency graph
func (a *DependencyAnalyzer) GenerateDependencyGraph(outputFile string) error {
	// Get all targets in packages directory
	result, err := a.RunBazelQuery("//packages/...")
	if err != nil {
		return fmt.Errorf("error querying packages: %v", err)
	}

	if result == nil || len(result.Target) == 0 {
		return fmt.Errorf("no targets found in packages directory")
	}

	// Track dependencies by package
	packageDeps := make(map[string]map[string]bool)
	allPackages := make(map[string]bool)

	// Process each target
	for _, target := range result.Target {
		sourcePkg := a.ParseTargetPackage(target.Name)
		if sourcePkg == "" {
			continue
		}

		allPackages[sourcePkg] = true

		// Initialize dependency map if needed
		if _, exists := packageDeps[sourcePkg]; !exists {
			packageDeps[sourcePkg] = make(map[string]bool)
		}

		// Query dependencies for this target
		depsResult, err := a.RunBazelQuery(fmt.Sprintf("deps(%s)", target.Name))
		if err != nil {
			fmt.Printf("Warning: Error querying dependencies for %s: %v\n", target.Name, err)
			continue
		}

		for _, depTarget := range depsResult.Target {
			targetPkg := a.ParseTargetPackage(depTarget.Name)
			if targetPkg != "" && targetPkg != sourcePkg {
				// Only track dependencies between Alpha Dot Five packages
				isKnown := false
				for _, dep := range a.ValidDeps {
					if dep.Source == targetPkg || dep.Target == targetPkg {
						isKnown = true
						break
					}
				}
				if isKnown || targetPkg == "UmbraCoreTypes" {
					packageDeps[sourcePkg][targetPkg] = true
					allPackages[targetPkg] = true
				}
			}
		}
	}

	// Generate DOT file content
	var sb strings.Builder
	sb.WriteString("digraph Dependencies {\n")
	sb.WriteString("  rankdir=LR;\n")
	sb.WriteString("  node [shape=box, style=filled, fillcolor=lightblue];\n")

	// Add nodes with different colors based on package type
	for pkg := range allPackages {
		color := "lightblue"
		if pkg == "UmbraCoreTypes" {
			color = "lightgreen"
		} else if pkg == "UmbraErrorKit" {
			color = "lightyellow"
		} else if pkg == "UmbraInterfaces" {
			color = "lightcoral"
		}

		sb.WriteString(fmt.Sprintf("  \"%s\" [fillcolor=%s];\n", pkg, color))
	}

	// Add edges
	for source, targets := range packageDeps {
		for target := range targets {
			// Color invalid dependencies red
			if a.IsDependencyValid(source, target) {
				sb.WriteString(fmt.Sprintf("  \"%s\" -> \"%s\";\n", source, target))
			} else {
				sb.WriteString(fmt.Sprintf("  \"%s\" -> \"%s\" [color=red, penwidth=2.0];\n", source, target))
			}
		}
	}

	sb.WriteString("}\n")

	// Write to file
	if err := ioutil.WriteFile(outputFile, []byte(sb.String()), 0644); err != nil {
		return fmt.Errorf("error writing to file %s: %v", outputFile, err)
	}

	fmt.Printf("Dependency graph written to %s\n", outputFile)
	fmt.Printf("To generate a PNG: dot -Tpng -o %s.png %s\n", strings.TrimSuffix(outputFile, filepath.Ext(outputFile)), outputFile)

	return nil
}

func main() {
	workspaceFlag := flag.String("workspace", "", "Workspace root directory")
	packagesFlag := flag.String("packages", "packages", "Packages directory relative to workspace")
	graphFlag := flag.String("graph", "", "Generate dependency graph and save to specified file")

	flag.Parse()

	workspaceRoot := *workspaceFlag
	if workspaceRoot == "" {
		// Try to detect workspace root
		var err error
		workspaceRoot, err = os.Getwd()
		if err != nil {
			log.Fatalf("Error getting current directory: %v", err)
		}
	}

	// Validate workspace root
	if _, err := os.Stat(filepath.Join(workspaceRoot, "WORKSPACE")); err != nil && !os.IsNotExist(err) {
		log.Printf("Warning: Could not find WORKSPACE file in %s", workspaceRoot)
	}

	packagesDir := filepath.Join(workspaceRoot, *packagesFlag)

	analyzer := NewDependencyAnalyzer(workspaceRoot, packagesDir)

	// Generate dependency graph if requested
	if *graphFlag != "" {
		if err := analyzer.GenerateDependencyGraph(*graphFlag); err != nil {
			log.Fatalf("Error generating dependency graph: %v", err)
		}
	}

	// Analyze dependencies
	valid, err := analyzer.AnalyzeDependencies()
	if err != nil {
		log.Fatalf("Error analyzing dependencies: %v", err)
	}

	if !valid {
		os.Exit(1)
	}
}
