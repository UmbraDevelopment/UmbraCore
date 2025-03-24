use std::fs;
use std::io::{Read};
use std::path::{Path, PathBuf};
use regex::Regex;
use walkdir::WalkDir;

// Configuration for the fix script
struct Config {
    dry_run: bool,
    verbose: bool,
    root_dir: PathBuf,
}

// Types of issues that can be fixed
#[derive(Debug, PartialEq, Clone, Copy)]
enum BuildIssue {
    EmptySrcs,
    IncorrectGlobPattern,
    VisibilityIssue,
    MissingDependency,
    IndentationIssue,
    CommentBlockIssue,
    FileGroupIssue,
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    
    let mut config = Config {
        dry_run: args.contains(&"--dry-run".to_string()),
        verbose: args.contains(&"--verbose".to_string()),
        root_dir: std::env::current_dir().expect("Failed to get current directory"),
    };
    
    // Allow overriding the root directory
    for (i, arg) in args.iter().enumerate() {
        if arg == "--root" && i + 1 < args.len() {
            config.root_dir = PathBuf::from(&args[i + 1]);
        }
    }
    
    println!("Starting BUILD file fixes in: {}", config.root_dir.display());
    println!("Dry run: {}", config.dry_run);
    
    let build_files = find_build_files(&config.root_dir);
    println!("Found {} BUILD.bazel files", build_files.len());
    
    let mut fixed_count = 0;
    
    for build_file in build_files {
        if let Some(issues) = analyze_build_file(&build_file, &config) {
            if !issues.is_empty() {
                if fix_build_file(&build_file, &issues, &config) {
                    fixed_count += 1;
                }
            }
        }
    }
    
    println!("Fixed {} BUILD.bazel files", fixed_count);
    
    // Final summary
    if config.dry_run {
        println!("This was a dry run. No files were actually modified.");
        println!("Run without --dry-run to apply the fixes.");
    } else {
        println!("All fixes applied. Consider running 'bazelisk build -k --verbose_failures //...' to verify.");
    }
}

fn find_build_files(root_dir: &Path) -> Vec<PathBuf> {
    let mut build_files = Vec::new();
    
    for entry in WalkDir::new(root_dir)
        .follow_links(false)
        .into_iter()
        .filter_map(|e| e.ok())
    {
        let path = entry.path();
        if path.file_name().map_or(false, |name| name == "BUILD.bazel") {
            build_files.push(path.to_path_buf());
        }
    }
    
    build_files
}

fn analyze_build_file(build_file: &Path, config: &Config) -> Option<Vec<(BuildIssue, String)>> {
    if config.verbose {
        println!("Analyzing: {}", build_file.display());
    }
    
    let mut issues = Vec::new();
    let mut file_content = String::new();
    
    if let Ok(mut file) = fs::File::open(build_file) {
        if let Ok(_) = file.read_to_string(&mut file_content) {
            // Check for empty srcs with allow_empty = False
            if let Some(issue) = check_empty_srcs(build_file, &file_content) {
                issues.push((BuildIssue::EmptySrcs, issue));
            }
            
            // Check for incorrect glob patterns
            if let Some(issue) = check_incorrect_glob_pattern(build_file, &file_content) {
                issues.push((BuildIssue::IncorrectGlobPattern, issue));
            }
            
            // Check for visibility issues
            if let Some(issue) = check_visibility_issues(&file_content) {
                issues.push((BuildIssue::VisibilityIssue, issue));
            }
            
            // Check for indentation issues
            if file_content.contains("outdent") || 
               file_content.contains("indentation error") ||
               file_content.contains("visibility") && file_content.contains("),") {
                issues.push((BuildIssue::IndentationIssue, "Indentation issue detected".to_string()));
            }
            
            // Check for missing dependencies
            if let Some(issue) = check_missing_dependencies(build_file, &file_content) {
                issues.push((BuildIssue::MissingDependency, issue));
            }
            
            // Check for comment block issues
            if let Some(issue) = fix_comment_block_issues(build_file, &file_content) {
                issues.push((BuildIssue::CommentBlockIssue, issue));
            }
            
            // Check for filegroup equals pattern issues
            if let Some(issue) = fix_filegroup_equals_pattern(build_file, &file_content) {
                issues.push((BuildIssue::FileGroupIssue, issue));
            }
        }
    }
    
    if issues.is_empty() {
        None
    } else {
        Some(issues)
    }
}

fn check_empty_srcs(build_file: &Path, content: &str) -> Option<String> {
    // Check if this BUILD file has a swift_library rule with empty srcs
    let re_swift_library = match Regex::new(r#"swift_library\s*\(\s*name\s*=\s*["']([^"']+)["']"#) {
        Ok(re) => re,
        Err(_) => return None,
    };
    let re_srcs_glob = match Regex::new(r#"srcs\s*=\s*glob\s*\(\s*\[\s*["']([^"']+)["']"#) {
        Ok(re) => re,
        Err(_) => return None,
    };
    let re_allow_empty = match Regex::new(r"allow_empty\s*=\s*(True|False)") {
        Ok(re) => re,
        Err(_) => return None,
    };
    
    if let Some(lib_cap) = re_swift_library.captures(content) {
        let target_name = &lib_cap[1];
        
        if let Some(srcs_cap) = re_srcs_glob.captures(content) {
            let glob_pattern = &srcs_cap[1];
            
            // Check if the build file directory actually has Swift files
            let build_dir = build_file.parent().unwrap();
            let has_swift_files = has_swift_files_in_directory(build_dir);
            
            if has_swift_files {
                // If it has Swift files but the glob pattern doesn't match them
                let mut file_paths = Vec::new();
                collect_swift_files(build_dir, &mut file_paths);
                
                if !file_paths.is_empty() {
                    // Determine if glob pattern needs to be fixed
                    for file_path in &file_paths {
                        let relative_path = file_path.strip_prefix(build_dir).unwrap();
                        let path_str = relative_path.to_string_lossy();
                        
                        // Check if the glob pattern would match this file
                        let would_match = glob_match(glob_pattern, &path_str);
                        
                        if !would_match {
                            return Some(format!(
                                "Target {} has Swift files but glob pattern '{}' doesn't match them", 
                                target_name, glob_pattern
                            ));
                        }
                    }
                }
            } else {
                // No Swift files but allow_empty might be False
                if let Some(allow_cap) = re_allow_empty.captures(content) {
                    let allow_empty = &allow_cap[1];
                    if allow_empty == "False" {
                        return Some(format!(
                            "Target {} has no Swift files but allow_empty is False", 
                            target_name
                        ));
                    }
                }
            }
        }
    }
    
    None
}

fn check_incorrect_glob_pattern(build_file: &Path, content: &str) -> Option<String> {
    let re_srcs_glob = match Regex::new(r#"srcs\s*=\s*glob\s*\(\s*\[\s*["']([^"']+)["']"#) {
        Ok(re) => re,
        Err(_) => return None,
    };
    
    if let Some(srcs_cap) = re_srcs_glob.captures(content) {
        let glob_pattern = &srcs_cap[1];
        let build_dir = build_file.parent().unwrap();
        
        // Common patterns that might be problematic
        if glob_pattern == "**/*.swift" {
            // Check if the directory has a Sources subdirectory
            let sources_dir = build_dir.join("Sources");
            if sources_dir.exists() && sources_dir.is_dir() {
                // Check if there are Swift files directly in the Sources directory
                let mut has_swift_in_sources = false;
                if let Ok(entries) = fs::read_dir(&sources_dir) {
                    for entry in entries {
                        if let Ok(entry) = entry {
                            let path = entry.path();
                            if path.extension().map_or(false, |ext| ext == "swift") {
                                has_swift_in_sources = true;
                                break;
                            }
                        }
                    }
                }
                
                if has_swift_in_sources {
                    return Some(format!(
                        "Target should use 'Sources/**/*.swift' glob pattern instead of '{}' to match files", 
                        glob_pattern
                    ));
                }
            }
        } else if glob_pattern == "Sources/**/*.swift" {
            // Check if the Sources directory exists
            let sources_dir = build_dir.join("Sources");
            if !sources_dir.exists() || !sources_dir.is_dir() {
                return Some(format!(
                    "Target uses 'Sources/**/*.swift' glob pattern but no Sources directory exists"
                ));
            }
        }
    }
    
    None
}

fn check_visibility_issues(content: &str) -> Option<String> {
    let re_visibility = match Regex::new(r#"visibility\s*=\s*\[\s*["']([^"']+)["']"#) {
        Ok(re) => re,
        Err(_) => return None,
    };
    
    if let Some(vis_cap) = re_visibility.captures(content) {
        let visibility = &vis_cap[1];
        
        // Check if visibility is too restrictive
        if visibility != "//visibility:public" && !visibility.starts_with("//") {
            return Some(format!(
                "Target has potentially restrictive visibility: '{}'", 
                visibility
            ));
        }
    } else {
        // No visibility specified
        return Some("Target has no visibility specified, might need //visibility:public".to_string());
    }
    
    None
}

fn check_missing_dependencies(_build_file: &Path, _content: &str) -> Option<String> {
    // This is a more complex check that would need to analyze imports in Swift files
    // For now, just return None as a placeholder
    None
}

fn fix_comment_block_issues(build_file: &Path, content: &str) -> Option<String> {
    let mut modified_content = content.to_string();
    let mut changes_made = false;
    
    // Fix equals sign in commented sections that are malformed
    let re_commented_equals = match Regex::new(r#"(#\s*=\s*\["\S+"\]\s*),?\s*\n"#) {
        Ok(re) => re,
        Err(_) => return None,
    };
    
    if re_commented_equals.is_match(&modified_content) {
        modified_content = re_commented_equals.replace_all(&modified_content, r#"#    visibility = $1
"#).to_string();
        changes_made = true;
        println!("  - CommentBlockIssue: Fixed commented visibility in {}", build_file.display());
    }
    
    // Fix outdent pattern at the end of comment blocks
    let re_comment_outdent = match Regex::new(r#"(#[^#\n]+\n)(\s*)visibility\s*=\s*\["\S+"\]"#) {
        Ok(re) => re,
        Err(_) => return None,
    };
    
    if re_comment_outdent.is_match(&modified_content) {
        modified_content = re_comment_outdent.replace_all(&modified_content, r#"$1$2# visibility = ["//visibility:public"]"#).to_string();
        changes_made = true;
        println!("  - CommentBlockIssue: Fixed outdented visibility in comment block in {}", build_file.display());
    }
    
    // Fix outdent syntax with trailing commas and outdent text
    let re_outdent_syntax = match Regex::new(r#"(\],?\s*\n[^#\n]*?\n\s*visibility\s*=\s*\["\S+"\]\s*),\s*\n\s*outdent"#) {
        Ok(re) => re,
        Err(_) => return None,
    };
    
    if re_outdent_syntax.is_match(&modified_content) {
        modified_content = re_outdent_syntax.replace_all(&modified_content, r#"$1"#).to_string();
        changes_made = true;
        println!("  - OutdentIssue: Fixed outdent syntax with trailing commas in {}", build_file.display());
    }
    
    // Fix duplicate visibility attributes
    let re_duplicate_visibility = match Regex::new(r#"(visibility\s*=\s*\["\S+"\]\s*),?\s*\n\s*visibility\s*=\s*\["\S+"\](,?\s*)\n"#) {
        Ok(re) => re,
        Err(_) => return None,
    };
    
    if re_duplicate_visibility.is_match(&modified_content) {
        modified_content = re_duplicate_visibility.replace_all(&modified_content, r#"$1$2
"#).to_string();
        changes_made = true;
        println!("  - VisibilityIssue: Fixed duplicate visibility in {}", build_file.display());
    }
    
    if changes_made {
        Some(modified_content)
    } else {
        None
    }
}

fn fix_build_file(build_file: &Path, issues: &[(BuildIssue, String)], config: &Config) -> bool {
    if config.verbose || config.dry_run {
        println!("Fixing: {}", build_file.display());
        for (issue_type, message) in issues {
            println!("  - {:?}: {}", issue_type, message);
        }
    }
    
    if config.dry_run {
        return true;
    }
    
    // Read the original file
    let mut content = String::new();
    if let Ok(mut file) = fs::File::open(build_file) {
        if let Ok(_) = file.read_to_string(&mut content) {
            // Create a backup
            let backup_path = build_file.with_extension("bazel.bak");
            if let Err(err) = fs::write(&backup_path, &content) {
                println!("Error creating backup: {}", err);
                return false;
            }
            
            // Apply fixes
            let mut modified_content = content.clone();
            
            for (issue_type, _) in issues {
                match issue_type {
                    BuildIssue::EmptySrcs => {
                        modified_content = fix_empty_srcs_issue(build_file, &modified_content);
                    },
                    BuildIssue::IncorrectGlobPattern => {
                        modified_content = fix_incorrect_glob_pattern(build_file, &modified_content);
                        // Also fix empty glob patterns as they often go together
                        modified_content = fix_empty_glob_pattern(build_file, &modified_content);
                    },
                    BuildIssue::VisibilityIssue => {
                        modified_content = fix_visibility_issue(&modified_content);
                    },
                    BuildIssue::MissingDependency => {
                        // Complex fix, not implemented yet
                    },
                    BuildIssue::IndentationIssue => {
                        modified_content = fix_indentation_issues(build_file, &modified_content);
                    },
                    BuildIssue::CommentBlockIssue => {
                        if let Some(modified) = fix_comment_block_issues(build_file, &modified_content) {
                            modified_content = modified;
                        }
                    },
                    BuildIssue::FileGroupIssue => {
                        if let Some(modified) = fix_filegroup_equals_pattern(build_file, &modified_content) {
                            modified_content = modified;
                        }
                    },
                }
            }
            
            // Always try to fix indentation issues as a last step, even if not explicitly detected
            modified_content = fix_indentation_issues(build_file, &modified_content);
            
            // Write the modified content back
            if let Err(err) = fs::write(build_file, modified_content) {
                println!("Error writing modified BUILD file: {}", err);
                return false;
            }
        } else {
            println!("Error reading BUILD file");
            return false;
        }
    } else {
        println!("Error opening BUILD file");
        return false;
    }
    
    true
}

fn fix_empty_srcs_issue(build_file: &Path, content: &str) -> String {
    // Define a regex to find swift_library declarations with empty srcs
    let re = match Regex::new(r#"swift_library\s*\(\s*name\s*=\s*"([^"]+)""#) {
        Ok(re) => re,
        Err(_) => return content.to_string(), // Return original content if regex fails
    };
    
    let srcs_re = match Regex::new(r#"srcs\s*=\s*glob\(\[\s*"([^"]+)"\s*\]\s*"#) {
        Ok(re) => re,
        Err(_) => return content.to_string(), // Return original content if regex fails
    };
    
    let mut modified_content = content.to_string();
    let mut changes_made = false;
    
    for cap in re.captures_iter(content) {
        let target_name = &cap[1];
        
        // Check if this target has an empty srcs attribute
        if let Some(srcs_match) = srcs_re.find(&modified_content) {
            let srcs_pattern = &modified_content[srcs_match.start()..srcs_match.end()];
            
            // If the glob pattern is "**/*.swift" and there are actual Swift files in the directory,
            // update the pattern to match them more specifically
            if srcs_pattern.contains("\"**/*.swift\"") {
                // Get the directory of the build file
                if let Some(dir) = build_file.parent() {
                    // See if there are Swift files directly in this directory
                    if let Ok(entries) = fs::read_dir(dir) {
                        let has_swift_files = entries
                            .filter_map(Result::ok)
                            .any(|entry| {
                                entry.path().extension().map_or(false, |ext| ext == "swift")
                            });
                        
                        if has_swift_files {
                            // Replace the pattern with one that would match files in the current directory
                            let new_pattern = srcs_pattern.replace("\"**/*.swift\"", "\"*.swift\"");
                            modified_content = modified_content.replace(srcs_pattern, &new_pattern);
                            changes_made = true;
                            
                            println!("  - EmptySrcs: Target {} has Swift files but glob pattern '**/*.swift' doesn't match them", target_name);
                        }
                    }
                }
            }
        }
    }
    
    if changes_made {
        modified_content
    } else {
        content.to_string()
    }
}

fn fix_incorrect_glob_pattern(build_file: &Path, content: &str) -> String {
    // Define a regex to identify glob patterns with newline before comma
    let re = match Regex::new(r#"\[\s*"[^"]+"\s*\]\s*\n\s*,"#) {
        Ok(re) => re,
        Err(_) => return content.to_string(), // Return original content if regex fails
    };
    
    if re.is_match(content) {
        let modified_content = re.replace_all(content, "],").to_string();
        println!("  - IncorrectGlobPattern: Fixed malformed glob pattern in {}", build_file.display());
        return modified_content;
    }
    
    // Also fix commented out glob patterns
    let comment_re = match Regex::new(r#"#\s*\[\s*"[^"]+"\s*\]\s*\n\s*,"#) {
        Ok(re) => re,
        Err(_) => return content.to_string(),
    };
    
    if comment_re.is_match(content) {
        let modified_content = comment_re.replace_all(content, "# ],").to_string();
        println!("  - IncorrectGlobPattern: Fixed malformed commented glob pattern in {}", build_file.display());
        return modified_content;
    }
    
    content.to_string()
}

fn fix_empty_glob_pattern(build_file: &Path, content: &str) -> String {
    // Match a glob with empty brackets (or just a closing bracket without content)
    let re = match Regex::new(r#"glob\(\s*\[\s*\]\s*"#) {
        Ok(re) => re,
        Err(_) => return content.to_string(),
    };
    
    if re.is_match(content) {
        // Replace with a valid glob pattern for Swift files
        let modified_content = re.replace_all(content, r#"glob(["*.swift"]"#).to_string();
        println!("  - EmptyGlobPattern: Fixed empty glob pattern in {}", build_file.display());
        return modified_content;
    }
    
    // Also check for malformed case like: glob(\n        ],
    let malformed_re = match Regex::new(r#"glob\(\s*\]\s*"#) {
        Ok(re) => re,
        Err(_) => return content.to_string(),
    };
    
    if malformed_re.is_match(content) {
        // Replace with a valid glob pattern for Swift files
        let modified_content = malformed_re.replace_all(content, r#"glob(["*.swift"]"#).to_string();
        println!("  - MalformedGlobPattern: Fixed malformed glob pattern in {}", build_file.display());
        return modified_content;
    }
    
    content.to_string()
}

fn fix_visibility_issue(content: &str) -> String {
    // Fix visibility attributes placed outside of rule block
    let re = match Regex::new(r#"\)\s*\n\s*visibility\s*=\s*\[\s*"//visibility:public"\s*\]\s*,\s*\)"#) {
        Ok(re) => re,
        Err(_) => return content.to_string(),
    };
    
    if re.is_match(content) {
        let modified_content = re.replace_all(content, r#"    visibility = ["//visibility:public"],
)"#).to_string();
        println!("  - VisibilityIssue: Fixed misplaced visibility attribute");
        return modified_content;
    }
    
    // Check if there is a target without visibility
    let rule_re = match Regex::new(r#"swift_library\s*\(\s*name\s*=\s*"([^"]+)""#) {
        Ok(re) => re,
        Err(_) => return content.to_string(),
    };
    
    let vis_re = match Regex::new(r#"visibility\s*="#) {
        Ok(re) => re,
        Err(_) => return content.to_string(),
    };
    
    if rule_re.is_match(content) && !vis_re.is_match(content) {
        // Find where to insert the visibility attribute
        let rule_end_re = match Regex::new(r#"\)[\s\n]*$"#) {
            Ok(re) => re,
            Err(_) => return content.to_string(),
        };
        
        // If there's a match, insert the visibility attribute before the closing parenthesis
        if let Some(rule_end_match) = rule_end_re.find(content) {
            let mut modified_content = content.to_string();
            let insert_pos = rule_end_match.start();
            
            // Insert the visibility attribute at the correct position
            let vis_attr = "    visibility = [\"//visibility:public\"],\n";
            modified_content.insert_str(insert_pos, vis_attr);
            
            println!("  - VisibilityIssue: Target has no visibility specified, might need //visibility:public");
            return modified_content;
        }
    }
    
    content.to_string()
}

fn fix_indentation_issues(build_file: &Path, content: &str) -> String {
    let mut modified_content = content.to_string();
    let mut changes_made = false;
    
    // Fix the "comma space equals" pattern (e.g., ] , = ["//visibility:public"])
    let re_comma_space_equals = match Regex::new(r#"(\]\s*),\s*=\s*(\["\S+"\])"#) {
        Ok(re) => re,
        Err(_) => return content.to_string(),
    };
    
    if re_comma_space_equals.is_match(&modified_content) {
        modified_content = re_comma_space_equals.replace_all(&modified_content, r#"$1, 
    visibility = $2"#).to_string();
        changes_made = true;
        println!("  - IndentationIssue: Fixed comma space equals pattern in {}", build_file.display());
    }
    
    // Fix the "outdent" issues 
    let re_outdent = match Regex::new(r#"(visibility\s*=\s*\["\S+"\]\s*),?\s*=\s*\["\S+"\](,?)\s*\)"#) {
        Ok(re) => re,
        Err(_) => return modified_content,
    };
    
    if re_outdent.is_match(&modified_content) {
        modified_content = re_outdent.replace_all(&modified_content, r#"$1$2)"#).to_string();
        changes_made = true;
        println!("  - IndentationIssue: Fixed duplicate visibility attributes in {}", build_file.display());
    }
    
    // Fix visibility with 'outdent' text
    let re_outdent_text = match Regex::new(r#"(#\s*=\s*\["\S+"\]\s*),\s*=\s*\["\S+"\]\s*,\s*outdent"#) {
        Ok(re) => re,
        Err(_) => return modified_content,
    };
    
    if re_outdent_text.is_match(&modified_content) {
        modified_content = re_outdent_text.replace_all(&modified_content, r#"$1"#).to_string();
        changes_made = true;
        println!("  - IndentationIssue: Fixed outdent text in visibility attributes in {}", build_file.display());
    }
    
    // Fix the case where visibility follows a closing parenthesis without a comma
    let re_closing_paren_equals = match Regex::new(r#"(\)\s*)=\s*(\["\S+"\])"#) {
        Ok(re) => re,
        Err(_) => return modified_content,
    };
    
    if re_closing_paren_equals.is_match(&modified_content) {
        modified_content = re_closing_paren_equals.replace_all(&modified_content, r#"$1, 
    visibility = $2"#).to_string();
        changes_made = true;
        println!("  - IndentationIssue: Fixed missing comma after closing parenthesis in {}", build_file.display());
    }
    
    // Fix the case where there's an equals sign directly after the closing bracket (no comma)
    let re_direct_equals = match Regex::new(r#"(\]\s*)=\s*(\["\S+"\])"#) {
        Ok(re) => re,
        Err(_) => return modified_content,
    };
    
    if re_direct_equals.is_match(&modified_content) {
        modified_content = re_direct_equals.replace_all(&modified_content, r#"$1, 
    visibility = $2"#).to_string();
        changes_made = true;
        println!("  - IndentationIssue: Fixed direct equals after bracket in {}", build_file.display());
    }
    
    // Fix the double comma before visibility attribute issue (],, = ["//visibility:public"])
    let re_double_comma = match Regex::new(r#"(\],?),\s*=\s*(\["\S+"\])"#) {
        Ok(re) => re,
        Err(_) => return modified_content,
    };
    
    if re_double_comma.is_match(&modified_content) {
        modified_content = re_double_comma.replace_all(&modified_content, r#"$1, 
    visibility = $2"#).to_string();
        changes_made = true;
        println!("  - IndentationIssue: Fixed double comma before visibility attribute in {}", build_file.display());
    }
    
    // Fix case where visibility is on the same line as the closing parenthesis
    let re_bad_visibility = match Regex::new(r#"(visibility\s*=\s*\["\S+"\]\s*),?\s*\)"#) {
        Ok(re) => re,
        Err(_) => return modified_content,
    };
    
    if re_bad_visibility.is_match(&modified_content) {
        modified_content = re_bad_visibility.replace_all(&modified_content, r#"$1,
)"#).to_string();
        changes_made = true;
        println!("  - IndentationIssue: Fixed misplaced visibility and closing parenthesis in {}", build_file.display());
    }
    
    // Fix issues with commented packages that have incorrect formatting
    let re_bad_commented_package = match Regex::new(r#"(#\s*swift_package\(\s*\n#\s*name\s*=\s*"[^"]+",\s*\n#\s*srcs\s*=\s*glob\(\[\s*\n[^)]+\))\s*,\s*\n\s*visibility"#) {
        Ok(re) => re,
        Err(_) => return modified_content,
    };
    
    if re_bad_commented_package.is_match(&modified_content) {
        modified_content = re_bad_commented_package.replace_all(&modified_content, r#"$1,
#    visibility"#).to_string();
        changes_made = true;
        println!("  - IndentationIssue: Fixed commented out package format in {}", build_file.display());
    }
    
    // Fix "outdent" error - specific pattern found in multiple files
    let re_outdent_error = match Regex::new(r#"(\s*deps\s*=\s*\[[^\]]*\],?)\s*\n(\s*)visibility"#) {
        Ok(re) => re,
        Err(_) => return modified_content,
    };
    
    if re_outdent_error.is_match(&modified_content) {
        modified_content = re_outdent_error.replace_all(&modified_content, r#"$1
$2visibility"#).to_string();
        changes_made = true;
        println!("  - IndentationIssue: Fixed outdent issue in {}", build_file.display());
    }
    
    // Fix issue with incorrect closing parenthesis placement
    let re_incomplete_rule = match Regex::new(r#"(swift_[a-z_]+\(\s*\n(?:[^)]+\n)+)(\s*\n)"#) {
        Ok(re) => re,
        Err(_) => return modified_content,
    };
    
    if re_incomplete_rule.is_match(&modified_content) {
        modified_content = re_incomplete_rule.replace_all(&modified_content, r#"$1)$2"#).to_string();
        changes_made = true;
        println!("  - IndentationIssue: Fixed missing closing parenthesis in {}", build_file.display());
    }
    
    if changes_made {
        modified_content
    } else {
        content.to_string()
    }
}

fn has_swift_files_in_directory(dir: &Path) -> bool {
    for entry in WalkDir::new(dir)
        .follow_links(false)
        .into_iter()
        .filter_map(|e| e.ok())
    {
        let path = entry.path();
        if path.extension().map_or(false, |ext| ext == "swift") {
            return true;
        }
    }
    
    false
}

fn collect_swift_files(dir: &Path, file_paths: &mut Vec<PathBuf>) {
    for entry in WalkDir::new(dir)
        .follow_links(false)
        .into_iter()
        .filter_map(|e| e.ok())
    {
        let path = entry.path();
        if path.extension().map_or(false, |ext| ext == "swift") {
            file_paths.push(path.to_path_buf());
        }
    }
}

fn determine_best_glob_pattern(base_dir: &Path, file_paths: &[PathBuf]) -> String {
    // Check if all files are in the root directory
    let mut all_in_root = true;
    for path in file_paths {
        if path.parent().unwrap() != base_dir {
            all_in_root = false;
            break;
        }
    }
    
    if all_in_root {
        return "*.swift".to_string();
    }
    
    // Check if there's a Sources subdirectory
    let sources_dir = base_dir.join("Sources");
    if sources_dir.exists() && sources_dir.is_dir() {
        let mut all_in_sources = true;
        for path in file_paths {
            if !path.starts_with(&sources_dir) {
                all_in_sources = false;
                break;
            }
        }
        
        if all_in_sources {
            return "Sources/**/*.swift".to_string();
        }
    }
    
    // Default pattern for nested directories
    "**/*.swift".to_string()
}

fn glob_match(pattern: &str, path: &str) -> bool {
    // Simple glob matching implementation
    // This is a basic implementation and might need to be enhanced for real-world use
    
    // Convert the glob pattern to a regex pattern
    let mut regex_pattern = "^".to_string();
    
    let pattern_parts: Vec<&str> = pattern.split('/').collect();
    let _path_parts: Vec<&str> = path.split('/').collect();
    
    for (i, part) in pattern_parts.iter().enumerate() {
        if *part == "**" {
            regex_pattern.push_str(".*");
            // In the case of ** we might match zero or more segments
            continue;
        }
        
        if i > 0 {
            regex_pattern.push('/');
        }
        
        // Replace * with a regex that matches anything except slashes
        let part_regex = part.replace('*', "[^/]*");
        regex_pattern.push_str(&part_regex);
    }
    
    regex_pattern.push('$');
    
    // Create the regex and test it
    match Regex::new(&regex_pattern) {
        Ok(re) => re.is_match(path),
        Err(_) => false,
    }
}

fn fix_filegroup_equals_pattern(build_file: &Path, content: &str) -> Option<String> {
    let mut modified_content = content.to_string();
    let mut changes_made = false;
    
    // Fix filegroup with equals sign directly after bracket in glob pattern
    let re_filegroup_equals = match Regex::new(r#"(\),?\s*)=\s*(\["\S+"\])"#) {
        Ok(re) => re,
        Err(_) => return None,
    };
    
    if re_filegroup_equals.is_match(&modified_content) {
        modified_content = re_filegroup_equals.replace_all(&modified_content, r#"$1
    visibility = $2"#).to_string();
        changes_made = true;
        println!("  - FileGroupIssue: Fixed equals after closing parenthesis in {}", build_file.display());
    }
    
    if changes_made {
        Some(modified_content)
    } else {
        None
    }
}
