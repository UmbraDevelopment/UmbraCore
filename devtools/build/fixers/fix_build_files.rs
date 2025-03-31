use std::fs;
use std::io::{self, Read, Write};
use std::path::{Path, PathBuf};
use std::process::Command;
use regex::{Regex, Captures};

fn main() -> io::Result<()> {
    // Get the root directory of the UmbraCore project
    let project_root = Path::new("/Users/mpy/CascadeProjects/UmbraCore");
    
    // Find all BUILD.bazel files
    let build_files = find_build_files(project_root)?;
    println!("Found {} BUILD.bazel files", build_files.len());
    
    // Process each BUILD.bazel file
    let mut modified_files = 0;
    for file_path in build_files {
        if fix_build_file(&file_path)? {
            modified_files += 1;
        }
    }
    
    println!("Successfully modified {} BUILD.bazel files", modified_files);
    Ok(())
}

// Find all BUILD.bazel files in the project
fn find_build_files(project_root: &Path) -> io::Result<Vec<PathBuf>> {
    let output = Command::new("find")
        .arg(project_root)
        .arg("-name")
        .arg("BUILD.bazel")
        .output()?;
    
    if !output.status.success() {
        let error = String::from_utf8_lossy(&output.stderr);
        return Err(io::Error::new(io::ErrorKind::Other, format!("Failed to find BUILD.bazel files: {}", error)));
    }
    
    let files = String::from_utf8_lossy(&output.stdout)
        .lines()
        .map(|line| PathBuf::from(line))
        .collect();
    
    Ok(files)
}

// Fix a single BUILD.bazel file
fn fix_build_file(file_path: &Path) -> io::Result<bool> {
    // Read the file content
    let mut file = fs::File::open(file_path)?;
    let mut content = String::new();
    file.read_to_string(&mut content)?;
    
    // Apply fixes
    let mut modified = false;
    let new_content = apply_fixes(&content, &mut modified);
    
    // Write back if modified
    if modified {
        println!("Modifying: {}", file_path.display());
        let mut file = fs::File::create(file_path)?;
        file.write_all(new_content.as_bytes())?;
    }
    
    Ok(modified)
}

// Apply all fixes to the content
fn apply_fixes(content: &str, modified: &mut bool) -> String {
    // First ensure swift_library is loaded if it's used in the file
    let content = ensure_swift_library_load(content, modified);
    
    // Convert umbra_swift_library to swift_library
    let content = convert_custom_library(&content, modified);
    
    // Remove exports attribute
    let content = remove_exports_attribute(&content, modified);
    
    // Fix glob patterns to set allow_empty=True
    let content = fix_glob_patterns(&content, modified);
    
    // Ensure swift_library has valid srcs
    let content = ensure_valid_srcs(&content, modified);
    
    content
}

// Ensure swift_library is properly loaded at the top of the file
fn ensure_swift_library_load(content: &str, modified: &mut bool) -> String {
    // Create a regex to detect swift_library in any format
    let swift_lib_re = Regex::new(r"\bswift_library\s*\(").unwrap();

    // Check if the file contains swift_library
    if swift_lib_re.is_match(content) {
        // Check if the swift library load statement is already present
        let swift_load = r#"load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")"#;
        if !content.contains(swift_load) {
            // Add the load statement at the top of the file
            let new_content = format!("{}\n\n{}", swift_load, content);
            *modified = true;
            return new_content;
        }
    }
    
    content.to_string()
}

// Convert umbra_swift_library to swift_library
fn convert_custom_library(content: &str, modified: &mut bool) -> String {
    let load_re = Regex::new(r#"load\(\s*"//:swift_rules\.bzl"\s*,\s*"umbra_swift_library"\s*\)"#).unwrap();
    let library_re = Regex::new(r#"umbra_swift_library\s*\("#).unwrap();
    
    let new_content = load_re.replace_all(content, 
        r#"load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")"#);
    
    if new_content != content {
        *modified = true;
    }
    
    let new_content = library_re.replace_all(&new_content, "swift_library(");
    
    if new_content != content {
        *modified = true;
    }
    
    new_content.to_string()
}

// Remove unsupported exports attribute
fn remove_exports_attribute(content: &str, modified: &mut bool) -> String {
    // This regex matches the exports attribute and its array of values
    let re = Regex::new(r#"(?s)exports\s*=\s*\[(.*?),?\s*\],"#).unwrap();
    
    let new_content = re.replace_all(content, |_: &Captures| {
        *modified = true;
        ""
    });
    
    new_content.to_string()
}

// Fix glob patterns to set allow_empty=True
fn fix_glob_patterns(content: &str, modified: &mut bool) -> String {
    // First fix patterns with allow_empty=False
    let false_re = Regex::new(r"allow_empty\s*=\s*False").unwrap();
    let new_content = false_re.replace_all(content, |_: &Captures| {
        *modified = true;
        "allow_empty = True"
    });
    
    // Then add allow_empty=True to patterns that don't have it
    let glob_re = Regex::new(r"glob\s*\(\s*\[(.*?)\]\s*\)").unwrap();
    
    let new_content = glob_re.replace_all(&new_content, |caps: &Captures| {
        // Only replace if it doesn't already have allow_empty
        if !caps[0].contains("allow_empty") {
            *modified = true;
            format!("glob(\n        [{}],\n        allow_empty = True\n    )", &caps[1])
        } else {
            // Return the original match
            caps[0].to_string()
        }
    });
    
    new_content.to_string()
}

// Ensure swift_library has valid srcs
fn ensure_valid_srcs(content: &str, modified: &mut bool) -> String {
    // Find swift_library blocks
    let lib_re = Regex::new(r#"swift_library\s*\(\s*name\s*=\s*"[^"]+"#).unwrap();
    
    // Process the content for each swift_library
    let mut new_content = content.to_string();
    for lib_match in lib_re.find_iter(content) {
        let lib_start = lib_match.start();
        
        // Check if there's a srcs attribute in the following text
        let has_srcs = content[lib_start..].contains("srcs");
        
        if !has_srcs {
            // Find the position after name =
            if let Some(pos) = content[lib_start..].find(',') {
                let insert_pos = lib_start + pos + 1;
                
                // Insert srcs attribute with proper string termination
                let srcs_attr = r#"
    srcs = glob(
        ["*.swift"],
        allow_empty = True,
    ),"#;
                
                new_content.insert_str(insert_pos, srcs_attr);
                *modified = true;
            }
        }
    }
    
    new_content
}
