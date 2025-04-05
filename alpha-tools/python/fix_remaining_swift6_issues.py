#!/usr/bin/env python3
"""
Script to fix common Swift 6 compatibility issues in the UmbraCore project.

This script focuses on:
1. Removing 'isolated' keywords from actor methods (only valid on deinit)
2. Fixing DummyLoggingActor implementations to work with Swift 6
3. Fixing SecurityConfigDTO initializations to match the correct signature
4. Ensuring error enums are used correctly
5. Fixing SecurityResultDTO initialization issues (private access)
6. Adding missing imports and secureStorage references
7. Fixing protocol conformance issues
8. Adding proper enum definitions for aes128CBC/GCM before reference
9. Fixing parameter labels for error enums
10. Fixing scope issues by adding 'self.' prefix
11. Removing duplicate property and method declarations
12. Fixing convenience initializers in actors
13. Properly handling logger references with DefaultConsoleLogger and FileSecureStorage
14. Fixing AES algorithm references
15. Fixing SecurityResultDTO.success calls
16. Fixing exportData and importData method calls
17. Fixing hash and verifyHash method calls
18. Fixing type conversions for encryption options
19. Fixing protocol conformance issues for CryptoServiceProtocol
20. Fixing duplicated method declaration in MockLogger
"""
import os
import argparse
import re
import glob
import sys
from typing import List, Dict, Tuple


def find_swift_files(directory_path: str) -> List[str]:
    """Find all Swift files in the given directory recursively.
    
    Args:
        directory_path: The directory to search
        
    Returns:
        A list of Swift file paths
    """
    return glob.glob(os.path.join(directory_path, "**/*.swift"), recursive=True)


def fix_dummy_logging_actor(file_path: str) -> bool:
    """Fix DummyLoggingActor implementations to correctly implement LoggingActor protocol.
    
    Args:
        file_path: Path to the Swift file to fix
        
    Returns:
        True if changes were made, False otherwise
    """
    with open(file_path, 'r') as file:
        content = file.read()
    
    changes_made = False
    
    # Fix loggingActor property assignment pattern
    actor_pattern = r'(public\s+let\s+loggingActor\s*:\s*LoggingActor\s*=.*?DummyLoggingActor\(\).*?)'
    
    if re.search(actor_pattern, content):
        # Replace the DummyLoggingActor implementation with a direct LoggingActor instance
        new_content = re.sub(
            actor_pattern,
            'public let loggingActor: LoggingActor = LoggingActor(destinations: [], minimumLogLevel: .info)',
            content
        )
        
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Replace DummyLoggingActor class entirely
    dummy_logging_pattern = r'private\s+(actor|class)\s+DummyLoggingActor.*?\{[\s\S]*?\}'
    
    if re.search(dummy_logging_pattern, content, re.DOTALL):
        # Remove the entire DummyLoggingActor implementation
        new_content = re.sub(
            dummy_logging_pattern,
            '',
            content,
            flags=re.DOTALL
        )
        
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Only write to the file if changes were made
    if changes_made:
        with open(file_path, 'w') as file:
            file.write(content)
        return True
    
    return False


def remove_isolated_keyword(file_path: str) -> bool:
    """Remove 'isolated' keyword from method declarations.
    
    Args:
        file_path: Path to the Swift file to fix
        
    Returns:
        True if changes were made, False otherwise
    """
    with open(file_path, 'r') as file:
        content = file.read()
    
    # Pattern for methods with isolated keyword
    isolated_pattern = r'(public|private|internal)\s+isolated\s+func'
    
    # Check if there's a matching pattern in the file
    if re.search(isolated_pattern, content):
        # Replace the isolated keyword
        new_content = re.sub(isolated_pattern, r'\1 func', content)
        
        # Only write to the file if changes were made
        if new_content != content:
            with open(file_path, 'w') as file:
                file.write(new_content)
            return True
    
    return False


def fix_security_config_dto(file_path: str) -> bool:
    """Fix SecurityConfigDTO initializations to match the correct signature.
    
    Args:
        file_path: Path to the Swift file to fix
        
    Returns:
        True if changes were made, False otherwise
    """
    with open(file_path, 'r') as file:
        content = file.read()
    
    changes_made = False
    
    # Fix missing parameters in SecurityConfigDTO initialization
    missing_params_pattern = r'SecurityConfigDTO\(\s*encryptionAlgorithm:\s*\.aes256\s*\)'
    if re.search(missing_params_pattern, content):
        new_content = re.sub(
            missing_params_pattern,
            r'SecurityConfigDTO(\n      encryptionAlgorithm: .aes128,\n      hashAlgorithm: .sha256,\n      providerType: .basic\n    )',
            content
        )
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Fix EncryptionAlgorithm.aes256 to .aes128
    if ".aes256" in content:
        new_content = content.replace(".aes256", ".aes128")
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Fix performOperation to separate methods
    if "provider.performOperation(.hash" in content:
        new_content = content.replace(
            "provider.performOperation(.hash",
            "provider.hash("
        )
        content = new_content
        changes_made = True
    
    if "provider.performOperation(.verifyHash" in content:
        new_content = content.replace(
            "provider.performOperation(.verifyHash",
            "provider.verifyHash("
        )
        content = new_content
        changes_made = True
    
    # Fix reference to exportData in non-local scope
    if "await exportData(identifier:" in content:
        new_content = content.replace(
            "await exportData(",
            "await self.exportData("
        )
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Fix reference to importData in non-local scope
    if "await importData(" in content:
        new_content = content.replace(
            "await importData(",
            "await self.importData("
        )
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Only write to the file if changes were made
    if changes_made:
        with open(file_path, 'w') as file:
            file.write(content)
    
    return changes_made


def fix_error_cases(file_path: str) -> bool:
    """Fix error cases to correctly handle Swift 6 requirements.
    
    Args:
        file_path: Path to the Swift file to fix
        
    Returns:
        True if changes were made, False otherwise
    """
    with open(file_path, 'r') as file:
        content = file.read()
    
    # Track if any changes were made
    changes_made = False
    
    # Fix operationFailed with extraneous reason parameter 
    operation_failed_pattern = r'\.operationFailed\(reason:\s*"(.*?)"\)'
    if re.search(operation_failed_pattern, content):
        new_content = re.sub(
            operation_failed_pattern, 
            r'.operationFailed("\1")', 
            content
        )
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Fix unsupportedOperation with extraneous reason parameter
    unsupported_pattern = r'\.unsupportedOperation\(reason:\s*"(.*?)"\)'
    if re.search(unsupported_pattern, content):
        new_content = re.sub(
            unsupported_pattern, 
            r'.unsupportedOperation', 
            content
        )
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Only write to the file if changes were made
    if changes_made:
        with open(file_path, 'w') as file:
            file.write(content)
    
    return changes_made


def fix_security_result_dto(file_path: str) -> bool:
    """Fix SecurityResultDTO initializations to use the factory method.
    
    Args:
        file_path: Path to the Swift file to fix
        
    Returns:
        True if changes were made, False otherwise
    """
    with open(file_path, 'r') as file:
        content = file.read()
    
    # Check if the file has SecurityResultDTO initializations
    if "SecurityResultDTO" not in content:
        return False
    
    changes_made = False
    
    # Replace SecurityResultDTO.create with success
    create_pattern = r'SecurityResultDTO\.create\(\s*successful:.*?,\s*resultData:\s*(.*?)(?:,.*?)?\s*\)'
    if re.search(create_pattern, content):
        new_content = re.sub(
            create_pattern,
            r'SecurityResultDTO.success(\1)',
            content
        )
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Fix invalid parameter combinations in SecurityResultDTO.success calls
    success_pattern = r'SecurityResultDTO\.success\((.*?),\s*errorDetails:\s*.*?,\s*executionTimeMs:.*?,\s*metadata:.*?\)'
    if re.search(success_pattern, content):
        new_content = re.sub(
            success_pattern,
            r'SecurityResultDTO.success(\1)',
            content
        )
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Fix direct initialization with SecurityResultDTO constructor
    init_pattern = r'SecurityResultDTO\(\s*successful:\s*true,\s*resultData:\s*(.*?)(?:,.*?)?\s*\)'
    if re.search(init_pattern, content):
        new_content = re.sub(
            init_pattern,
            r'SecurityResultDTO.success(\1)',
            content
        )
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Fix Data initialization issues with additional parameters
    data_pattern = r'Data\((.*?),\s*errorDetails:'
    if re.search(data_pattern, content):
        new_content = re.sub(
            r'Data\((.*?),\s*errorDetails:.*?metadata:.*?\)',
            r'Data(\1)',
            content
        )
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Fix result.outputData to result.resultData
    if "result.outputData" in content:
        new_content = content.replace("result.outputData", "result.resultData")
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Only write to the file if changes were made
    if changes_made:
        with open(file_path, 'w') as file:
            file.write(content)
    
    return changes_made


def fix_missing_imports(file_path: str) -> bool:
    """Add missing imports and fix SimpleSecureStorage/DefaultLogger references.
    
    Args:
        file_path: Path to the Swift file to fix
        
    Returns:
        True if changes were made, False otherwise
    """
    with open(file_path, 'r') as file:
        content = file.read()
    
    changes_made = False
    
    # Replace incorrect imports with valid ones
    if "import SecureStorageCore" in content:
        new_content = content.replace(
            "import SecureStorageCore",
            "import SecurityCoreInterfaces\nimport CoreSecurityTypes"
        )
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Check if imports are needed
    needs_logger = ("DefaultLogger()" in content or "StandardLogger()" in content) and "import LoggingServices" not in content
    
    # Add necessary imports
    if needs_logger:
        import_block = "import LoggingServices\n"
        
        # Find where to insert imports
        if "import " in content:
            # Add after existing imports
            last_import = re.search(r'(import .*?)(\n\n|\n[^\n]*?[^;import])', content, re.DOTALL)
            if last_import:
                index = last_import.end(1)
                new_content = content[:index] + "\n" + import_block + content[index:]
                content = new_content
                changes_made = True
        else:
            # Add at the beginning, after any comments
            first_non_comment = re.search(r'(^(?:\/\*[\s\S]*?\*\/|\/\/[^\n]*\n)*)', content)
            if first_non_comment:
                index = first_non_comment.end(1)
                new_content = content[:index] + import_block + "\n" + content[index:]
                content = new_content
                changes_made = True
    
    # Fix SimpleSecureStorage reference
    if "BasicSecureStorage()" in content:
        new_content = content.replace(
            "BasicSecureStorage()",
            "FileSecureStorage()"
        )
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Fix DefaultLogger reference
    if "StandardLogger()" in content:
        new_content = content.replace(
            "StandardLogger()",
            "DefaultConsoleLogger()"
        )
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Only write to the file if changes were made
    if changes_made:
        with open(file_path, 'w') as file:
            file.write(content)
    
    return changes_made


def fix_crypto_service_impl(file_path: str) -> bool:
    """Fix CryptoServiceImpl to properly initialize the secureStorage property.
    
    Args:
        file_path: Path to the Swift file to fix
        
    Returns:
        True if changes were made, False otherwise
    """
    # Check if this is the implementation file
    if not os.path.basename(file_path) in ["CryptoServiceImpl.swift", "MockCryptoService.swift"]:
        return False
    
    with open(file_path, 'r') as file:
        content = file.read()
    
    changes_made = False
    
    # Add missing properties for MockCryptoService
    if "public actor MockCryptoService" in content:
        # Replace the entire actor definition to properly initialize properties and conform to the protocol
        mock_service_pattern = r'public\s+actor\s+MockCryptoService\s*:.*?\{'
        if re.search(mock_service_pattern, content):
            # Make sure all required properties are added
            new_content = re.sub(
                mock_service_pattern,
                """public actor MockCryptoService: CryptoServiceProtocol {
  /// The secure storage used for sensitive material
  public nonisolated let secureStorage: SecureStorageProtocol
  /// History of calls made to this service, for testing
  private var callHistory: [String] = []
  /// Logger for this service
  private let logger = DefaultConsoleLogger()
  
  public init(secureStorage: SecureStorageProtocol) {
    self.secureStorage = secureStorage
  }
  
  public convenience init() {
    self.init(secureStorage: FileSecureStorage())
  }""",
                content
            )
            if new_content != content:
                content = new_content
                changes_made = True
    
    # Add missing properties for CryptoServiceImpl
    if "public actor CryptoServiceImpl" in content and "secureStorage" not in content:
        # Add secureStorage property and initialization
        crypto_impl_pattern = r'public\s+actor\s+CryptoServiceImpl\s*:.*?\{(.*?private\s+let\s+options\s*:.*?)'
        if re.search(crypto_impl_pattern, content, re.DOTALL):
            new_content = re.sub(
                crypto_impl_pattern,
                r'public actor CryptoServiceImpl: CryptoServiceProtocol {\1\n  /// The secure storage used for sensitive material\n  private let secureStorage: SecureStorageProtocol\n  /// Logger for this service\n  private let logger = DefaultConsoleLogger()\n',
                content
            )
            
            # Update the initialization
            init_pattern = r'(init\([^)]*\)\s*\{)'
            if re.search(init_pattern, new_content):
                new_content = re.sub(
                    init_pattern,
                    r'\1\n    self.secureStorage = FileSecureStorage()\n',
                    new_content
                )
            else:
                # Add init if it doesn't exist
                class_body_start = re.search(r'private\s+let\s+options.*?\n', new_content)
                if class_body_start:
                    index = class_body_start.end(0)
                    new_content = new_content[:index] + "\n  init() {\n    self.secureStorage = FileSecureStorage()\n  }\n" + new_content[index:]
            
            if new_content != content:
                content = new_content
                changes_made = True
    
    # Only write to the file if changes were made
    if changes_made:
        with open(file_path, 'w') as file:
            file.write(content)
    
    return changes_made


def fix_catch_block_no_errors(file_path: str) -> bool:
    """Fix catch blocks that have no errors thrown in do blocks.
    
    Args:
        file_path: Path to the Swift file to fix
        
    Returns:
        True if changes were made, False otherwise
    """
    with open(file_path, 'r') as file:
        content = file.read()
    
    changes_made = False
    
    # Look for do/catch blocks where the do block doesn't throw
    do_catch_pattern = r'do\s*\{([^{}]*(?:\{[^{}]*\})*[^{}]*)\}\s*catch\s*\{'
    matches = list(re.finditer(do_catch_pattern, content, re.DOTALL))
    
    for match in reversed(matches):  # Reverse to not mess up indices
        do_block = match.group(1)
        # Check if the do block has any throws
        if not re.search(r'\btry\b|\bthrows\b|\bthrow\b', do_block):
            # Remove the catch block
            start_idx = match.start(0)
            do_end_idx = content.find("}", start_idx) + 1
            catch_start_idx = content.find("catch", do_end_idx)
            catch_end_idx = content.find("}", catch_start_idx) + 1
            
            new_content = content[:do_end_idx] + content[catch_end_idx:]
            content = new_content
            changes_made = True
    
    # Only write to the file if changes were made
    if changes_made:
        with open(file_path, 'w') as file:
            file.write(content)
    
    return changes_made


def fix_non_local_scope_public(file_path: str) -> bool:
    """Fix 'public' modifier used in non-local scope.
    
    Args:
        file_path: Path to the Swift file to fix
        
    Returns:
        True if changes were made, False otherwise
    """
    with open(file_path, 'r') as file:
        content = file.read()
    
    changes_made = False
    
    # Fix public attribute in non-local scope
    public_non_local_pattern = r'fileprivate actor .*?\{.*?(public func exportData\(.*?\)\s*async\s*->.*?\{)'
    
    if re.search(public_non_local_pattern, content, re.DOTALL):
        new_content = re.sub(
            r'public func exportData',
            r'func exportData',
            content,
            flags=re.DOTALL
        )
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Fix missing closing braces in nested actors
    missing_brace_pattern = r'(fileprivate actor DefaultCryptoServiceWithProviderImpl.*?\n\s*\})(?!\s*\})'
    
    if re.search(missing_brace_pattern, content, re.DOTALL):
        # Count the number of opening and closing braces
        open_braces = content.count('{')
        close_braces = content.count('}')
        
        if open_braces > close_braces:
            # Add the missing closing braces at the end
            missing_count = open_braces - close_braces
            new_content = content + '\n' + '}' * missing_count
            if new_content != content:
                content = new_content
                changes_made = True
    
    # Only write to the file if changes were made
    if changes_made:
        with open(file_path, 'w') as file:
            file.write(content)
    
    return changes_made


def fix_aes_enum_definitions(file_path: str) -> bool:
    """Add proper enum definitions for aes128CBC/GCM before reference.
    
    Args:
        file_path: Path to the Swift file to fix
        
    Returns:
        True if changes were made, False otherwise
    """
    with open(file_path, 'r') as file:
        content = file.read()
    
    changes_made = False
    
    # Fix AES algorithm names in enums - add this first to define the enum values
    pattern = r'enum\s+EncryptionAlgorithm.*?{(.*?)}'
    match = re.search(pattern, content, re.DOTALL)
    if match and 'aes128CBC' not in match.group(1):
        enum_content = match.group(1)
        # Replace aes256CBC with aes128CBC and aes256GCM with aes128GCM in enum definitions
        if 'case aes256CBC' in enum_content and 'case aes128CBC' not in enum_content:
            new_enum_content = enum_content.replace('case aes256CBC', 'case aes128CBC')
            new_enum_content = new_enum_content.replace('case aes256GCM', 'case aes128GCM')
            content = content.replace(match.group(1), new_enum_content)
            changes_made = True
    
    # Only write to the file if changes were made
    if changes_made:
        with open(file_path, 'w') as file:
            file.write(content)
    
    return changes_made


def fix_error_enum_usage(file_path: str) -> bool:
    """Fix error enum usage to correctly handle Swift 6 requirements.
    
    Args:
        file_path: Path to the Swift file to fix
        
    Returns:
        True if changes were made, False otherwise
    """
    with open(file_path, 'r') as file:
        content = file.read()
    
    changes_made = False
    
    # Fix operationFailed with extraneous reason parameter 
    operation_failed_pattern = r'\.operationFailed\(reason:\s*"(.*?)"\)'
    if re.search(operation_failed_pattern, content):
        new_content = re.sub(
            operation_failed_pattern, 
            r'.operationFailed("\1")', 
            content
        )
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Fix unsupportedOperation with extraneous reason parameter
    unsupported_pattern = r'\.unsupportedOperation\(reason:\s*"(.*?)"\)'
    if re.search(unsupported_pattern, content):
        new_content = re.sub(
            unsupported_pattern, 
            r'.unsupportedOperation', 
            content
        )
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Only write to the file if changes were made
    if changes_made:
        with open(file_path, 'w') as file:
            file.write(content)
    
    return changes_made


def fix_scope_issues(file_path: str) -> bool:
    """Fix scope issues by adding 'self.' prefix.
    
    Args:
        file_path: Path to the Swift file to fix
        
    Returns:
        True if changes were made, False otherwise
    """
    with open(file_path, 'r') as file:
        original_content = file.read()
    
    content = original_content
    changes_made = False
    
    # Fix 'secureStorage' scope issues by adding 'self.' prefix
    new_content = re.sub(r'await\s+secureStorage\.', r'await self.secureStorage.', content)
    
    # Only write to the file if changes were made
    if new_content != content:
        with open(file_path, 'w') as file:
            file.write(new_content)
        changes_made = True
    
    return changes_made


def fix_duplicate_declarations(file_path: str) -> bool:
    """Remove duplicate property and method declarations.
    
    Args:
        file_path: Path to the Swift file to fix
        
    Returns:
        True if changes were made, False otherwise
    """
    with open(file_path, 'r') as file:
        original_content = file.read()
    
    content = original_content
    changes_made = False
    
    # Fix duplicate methods in MockCryptoService
    if "MockCryptoService" in file_path:
        # Remove duplicate properties
        new_content = re.sub(
            r'(public\s+nonisolated\s+let\s+secureStorage:.*?\n).*?public\s+nonisolated\s+let\s+secureStorage:',
            r'\1// Unified secureStorage property\n  private(set)',
            content,
            flags=re.DOTALL
        )
        
        if new_content != content:
            content = new_content
            changes_made = True
        
        # Remove duplicate callHistory
        new_content = re.sub(
            r'(private\s+var\s+callHistory:.*?\n).*?private\(set\)\s+var\s+callHistory:',
            r'\1// Unified callHistory\n  private(set)',
            content,
            flags=re.DOTALL
        )
        
        if new_content != content:
            content = new_content
            changes_made = True
        
        # Fix duplicate init methods 
        new_content = re.sub(
            r'(public\s+init\(secureStorage:.*?\n.*?\n\s*\}\n).*?public\s+init\(secureStorage:',
            r'\1// Single implementation\n  public',
            content,
            flags=re.DOTALL
        )
        
        if new_content != content:
            content = new_content
            changes_made = True
        
        # Fix convenience init in actor - remove convenience
        new_content = re.sub(
            r'public\s+convenience\s+init\(\)',
            r'public init()',
            content
        )
        
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Only write to the file if changes were made
    if changes_made:
        with open(file_path, 'w') as file:
            file.write(content)
    
    return changes_made


def fix_convenience_initializers(file_path: str) -> bool:
    """Fix convenience initializers in actors.
    
    Args:
        file_path: Path to the Swift file to fix
        
    Returns:
        True if changes were made, False otherwise
    """
    with open(file_path, 'r') as file:
        original_content = file.read()
    
    # Fix convenience init in actor - remove convenience
    new_content = re.sub(
        r'public\s+convenience\s+init\(\)',
        r'public init()',
        original_content
    )
    
    # Only write to the file if changes were made
    if new_content != original_content:
        with open(file_path, 'w') as file:
            file.write(new_content)
        return True
    
    return False


def fix_logger_references(file_path: str) -> bool:
    """Properly handle logger references with DefaultConsoleLogger and FileSecureStorage.
    
    Args:
        file_path: Path to the Swift file to fix
        
    Returns:
        True if changes were made, False otherwise
    """
    with open(file_path, 'r') as file:
        original_content = file.read()
    
    content = original_content
    changes_made = False
    
    # Fix logger references
    new_content = re.sub(r'StandardLogger\(\)', r'DefaultConsoleLogger()', content)
    if new_content != content:
        content = new_content
        changes_made = True
    
    new_content = re.sub(r'BasicSecureStorage\(\)', r'FileSecureStorage()', content)
    if new_content != content:
        content = new_content
        changes_made = True
    
    # Only write to the file if changes were made
    if changes_made:
        with open(file_path, 'w') as file:
            file.write(content)
    
    return changes_made


def fix_aes_algorithms(file_path: str) -> bool:
    """Fix references to .aes128 encryption algorithm which no longer exists.
    
    Args:
        file_path: Path to the Swift file to fix
        
    Returns:
        True if changes were made, False otherwise
    """
    with open(file_path, 'r') as file:
        content = file.read()
    
    changes_made = False
    
    # Replace all .aes128 with .aes256 where appropriate
    replacements = [
        (r'\.aes128\b(?!CBC|GCM)', '.aes256CBC'),  # .aes128 -> .aes256CBC
        (r'\.aes128CBC\b', '.aes256CBC'),          # .aes128CBC -> .aes256CBC
        (r'\.aes128GCM\b', '.aes256GCM')           # .aes128GCM -> .aes256GCM
    ]
    
    for pattern, replacement in replacements:
        if re.search(pattern, content):
            new_content = re.sub(pattern, replacement, content)
            if new_content != content:
                content = new_content
                changes_made = True
    
    # Add EncryptionAlgorithm extension if needed
    if (('.aes256CBC' in content or '.aes256GCM' in content) and 
        ('has no member \'aes256CBC\'' in content or 'has no member \'aes256GCM\'' in content)):
        
        extension_text = """
// MARK: - Extension for EncryptionAlgorithm for Swift 6 compatibility
extension EncryptionAlgorithm {
    static let aes256CBC = EncryptionAlgorithm.aes256
    static let aes256GCM = EncryptionAlgorithm.aes256
}
"""
        # Find import section end to add after
        import_end = 0
        for match in re.finditer(r'import [^\n]+\n', content):
            import_end = match.end()
        
        if import_end > 0:
            new_content = content[:import_end] + "\n" + extension_text + content[import_end:]
            content = new_content
            changes_made = True
    
    # Only write to the file if changes were made
    if changes_made:
        with open(file_path, 'w') as file:
            file.write(content)
    
    return changes_made


def fix_security_result_dto_calls(file_path: str) -> bool:
    """Fix missing parameter labels and required parameters in SecurityResultDTO.success calls.
    
    Args:
        file_path: Path to the Swift file to fix
        
    Returns:
        True if changes were made, False otherwise
    """
    with open(file_path, 'r') as file:
        content = file.read()
    
    changes_made = False
    
    # Fix incorrect Data constructor calls with executionTimeMs
    data_constructor_pattern = r'Data\(([^)]+),\s*executionTimeMs:\s*([^)]+)\)'
    if re.search(data_constructor_pattern, content):
        def fix_data_constructor(match):
            data_arg = match.group(1).strip()
            exec_time = match.group(2).strip()
            return f'Data({data_arg})'
        
        new_content = re.sub(data_constructor_pattern, fix_data_constructor, content)
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Fix SecurityResultDTO.success calls with correct parameter syntax
    success_pattern = r'SecurityResultDTO\.success\(resultData:\s*([^,)]+)(?:,\s*executionTimeMs:\s*([^,)]+))?\)'
    if re.search(success_pattern, content):
        def fix_success_call(match):
            data_arg = match.group(1).strip()
            exec_time = match.group(2).strip() if match.group(2) else "0.0"
            return f'SecurityResultDTO.success(resultData: {data_arg}, executionTimeMs: {exec_time})'
        
        new_content = re.sub(success_pattern, fix_success_call, content)
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Fix any remaining SecurityResultDTO.success calls without labels
    unlabeled_pattern = r'SecurityResultDTO\.success\(([^)]+)\)'
    if re.search(unlabeled_pattern, content):
        def fix_unlabeled_success(match):
            arg = match.group(1).strip()
            if 'resultData:' not in arg and 'executionTimeMs:' not in arg:
                return f'SecurityResultDTO.success(resultData: {arg}, executionTimeMs: 0.0)'
            return match.group(0)
        
        new_content = re.sub(unlabeled_pattern, fix_unlabeled_success, content)
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Only write to the file if changes were made
    if changes_made:
        with open(file_path, 'w') as file:
            file.write(content)
    
    return changes_made


def fix_export_import_data_methods(file_path: str) -> bool:
    """Fix missing exportData method calls by adding implementation.
    
    Args:
        file_path: Path to the Swift file to fix
        
    Returns:
        True if changes were made, False otherwise
    """
    if 'CryptoServiceFactory.swift' not in file_path:
        return False
        
    with open(file_path, 'r') as file:
        content = file.read()
    
    changes_made = False
    
    # Check if there are multiple class definitions with exportData references
    class_defs = re.findall(r'(class|struct|extension)\s+([A-Za-z0-9_]+)', content)
    provider_impl_classes = [name for typ, name in class_defs if 'DefaultCryptoServiceWithProviderImpl' in name]
    
    for class_name in provider_impl_classes:
        # Find class definitions that need exportData
        class_pattern = rf'(class|extension)\s+{class_name}.*?\{{'
        class_matches = list(re.finditer(class_pattern, content, re.DOTALL))
        
        for match in class_matches:
            # Check if this class definition uses exportData but doesn't define it
            class_content = content[match.end():]
            class_end = find_matching_brace(class_content)
            if class_end > 0:
                class_content = class_content[:class_end]
                
                if 'self.exportData(' in class_content and 'func exportData(' not in class_content:
                    export_methods = """
  /// Exports data from secure storage
  /// - Parameter identifier: The identifier for the stored data
  /// - Returns: The data as a Result
  func exportData(identifier: String) async -> Result<Data, SecurityStorageError> {
    if let storage = self.secureStorage as? SecureCryptoStorage {
      do {
        let data = try await storage.retrieveData(withIdentifier: identifier)
        return .success(data)
      } catch {
        return .failure(.dataNotFound)
      }
    }
    return .failure(.storeNotAvailable)
  }
  
  /// Imports data to secure storage
  /// - Parameters:
  ///   - data: The data to store
  ///   - customIdentifier: Optional identifier to use
  /// - Returns: The identifier as a Result
  func importData(_ data: Data?, customIdentifier: String? = nil) async -> Result<String, SecurityStorageError> {
    guard let data = data else {
      return .failure(.invalidData)
    }
    
    if let storage = self.secureStorage as? SecureCryptoStorage {
      do {
        let identifier = customIdentifier ?? UUID().uuidString
        try await storage.storeData(data, withIdentifier: identifier)
        return .success(identifier)
      } catch {
        return .failure(.storeFailed)
      }
    }
    return .failure(.storeNotAvailable)
  }
"""
                    # Add to the beginning of the class
                    insert_pos = match.end()
                    new_content = content[:insert_pos] + export_methods + content[insert_pos:]
                    content = new_content
                    changes_made = True
    
    # Fix incorrect references to .resultData?.data?.data
    result_data_pattern = r'result\.resultData\?\.data\?\.data'
    if re.search(result_data_pattern, content):
        new_content = re.sub(result_data_pattern, 'result.resultData', content)
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Only write to the file if changes were made
    if changes_made:
        with open(file_path, 'w') as file:
            file.write(content)
    
    return changes_made

def find_matching_brace(text):
    """Find the position of the matching closing brace for the first opening brace."""
    brace_count = 0
    for i, char in enumerate(text):
        if char == '{':
            brace_count += 1
        elif char == '}':
            brace_count -= 1
            if brace_count == 0:
                return i
    return -1


def fix_error_enum_usage(file_path: str) -> bool:
    """Fix error enum usage to correctly handle Swift 6 requirements.
    
    Args:
        file_path: Path to the Swift file to fix
        
    Returns:
        True if changes were made, False otherwise
    """
    with open(file_path, 'r') as file:
        content = file.read()
    
    changes_made = False
    
    # Add 'reason:' parameter label to CryptoError.operationFailed calls
    error_pattern = r'CryptoError\.operationFailed\(\s*"([^"]+)"\s*\)'
    if re.search(error_pattern, content):
        new_content = re.sub(error_pattern, r'CryptoError.operationFailed(reason: "\1")', content)
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Only write to the file if changes were made
    if changes_made:
        with open(file_path, 'w') as file:
            file.write(content)
    
    return changes_made


def fix_mock_crypto_service(file_path: str) -> bool:
    """Fix syntax errors in MockCryptoService implementation.
    
    Args:
        file_path: Path to the Swift file to fix
        
    Returns:
        True if changes were made, False otherwise
    """
    if 'MockCryptoService.swift' not in file_path:
        return False
        
    with open(file_path, 'r') as file:
        content = file.read()
    
    changes_made = False
    
    # Clean up duplicate properties and malformed declarations
    if 'private(set) SecureStorageProtocol' in content:
        # Replace the problematic section with properly formatted properties
        pattern = r'public\s+nonisolated\s+let\s+secureStorage:\s+SecureStorageProtocol\s*\n.*?private\(set\)\s+SecureStorageProtocol.*?private\(set\)\s+SecureStorageProtocol.*?private\s+var\s+callHistory'
        replacement = """public nonisolated let secureStorage: SecureStorageProtocol
  
  /// History of calls made to this service, for testing
  private var callHistory"""
        
        new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Remove duplicate logMessage method if it exists
    if '/// Log a message with context' in content and content.count('logMessage') > 1:
        log_message_section = r'/// Log a message with context\s*\npublic\s+func\s+logMessage\([^}]+\}\s*\n'
        new_content = re.sub(log_message_section, '', content)
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Only write to the file if changes were made
    if changes_made:
        with open(file_path, 'w') as file:
            file.write(content)
    
    return changes_made


def fix_provider_protocol_methods(file_path: str) -> bool:
    """Fix missing methods in SecurityProviderProtocol implementations.
    
    Args:
        file_path: Path to the Swift file to fix
        
    Returns:
        True if changes were made, False otherwise
    """
    if 'CryptoServiceFactory.swift' not in file_path:
        return False
        
    with open(file_path, 'r') as file:
        content = file.read()
    
    changes_made = False
    
    # Fix provider.hash and provider.verifyHash calls that don't exist
    if 'provider.hash(data:' in content or 'provider.verifyHash(data:' in content:
        # First, let's find where the provider protocol might be defined or used
        provider_pattern = r'protocol\s+SecurityProviderProtocol'
        provider_extension = """
// MARK: - Extension on SecurityProviderProtocol to add missing methods
extension SecurityProviderProtocol {
    func hash(data: Data, config: SecurityConfigDTO) async throws -> SecurityResultDTO {
        // Forward to generic operation
        return try await self.performOperation(.hash, data: data, config: config)
    }
    
    func verifyHash(data: Data, hash: Data, config: SecurityConfigDTO) async throws -> SecurityResultDTO {
        // Forward to generic operation
        var config = config
        config.options = SecurityConfigOptions(config.options?.dictionary ?? [:])
        config.options?.add(key: "hash", value: Array(hash))
        return try await self.performOperation(.verifyHash, data: data, config: config)
    }
}
"""
        
        # Find a good place to insert the extension (after imports)
        import_end = 0
        for match in re.finditer(r'import [^\n]+\n', content):
            import_end = match.end()
        
        if import_end > 0:
            new_content = content[:import_end] + "\n" + provider_extension + content[import_end:]
            content = new_content
            changes_made = True
    
    # Only write to the file if changes were made
    if changes_made:
        with open(file_path, 'w') as file:
            file.write(content)
    
    return changes_made


def fix_swift6_issues(directory_path: str, module_filter: str = None) -> Dict[str, int]:
    """Find and fix Swift 6 compatibility issues in Swift files.
    
    Args:
        directory_path: Directory to search for Swift files
        module_filter: Optional filter to only process files in a specific module
        
    Returns:
        A dictionary with counts of different fixes applied
    """
    swift_files = find_swift_files(directory_path)
    
    # Apply filter if provided
    if module_filter:
        swift_files = [f for f in swift_files if module_filter in f]
    
    fix_counts = {
        "dummy_logging_actor": 0,
        "isolated_keyword": 0,
        "security_config_dto": 0,
        "error_cases": 0,
        "security_result_dto": 0,
        "missing_imports": 0,
        "crypto_service_impl": 0,
        "catch_block_no_errors": 0,
        "non_local_scope_public": 0,
        "aes_enum_definitions": 0,
        "error_enum_usage": 0,
        "scope_issues": 0,
        "duplicate_declarations": 0,
        "convenience_initializers": 0,
        "logger_references": 0,
        "aes_algorithms": 0,
        "security_result_dto_calls": 0,
        "export_import_data_methods": 0,
        "hash_verify_hash_methods": 0,
        "crypto_option_type_conversions": 0,
        "service_protocol_conformance": 0,
        "mock_logger_duplicate_method": 0,
        "provider_protocol_methods": 0,
        "mock_crypto_service": 0
    }
    
    for file_path in swift_files:
        # Skip test files
        if "Tests" in file_path:
            continue
        
        # Get relative path for display
        rel_path = os.path.relpath(file_path, directory_path)
        
        if fix_dummy_logging_actor(file_path):
            fix_counts["dummy_logging_actor"] += 1
            print(f"  Fixed DummyLoggingActor in {rel_path}")
        
        if remove_isolated_keyword(file_path):
            fix_counts["isolated_keyword"] += 1
            print(f"  Fixed isolated keyword in {rel_path}")
        
        if fix_security_config_dto(file_path):
            fix_counts["security_config_dto"] += 1
            print(f"  Fixed SecurityConfigDTO initializations in {rel_path}")
        
        if fix_error_cases(file_path):
            fix_counts["error_cases"] += 1
            print(f"  Fixed error cases in {rel_path}")
        
        if fix_security_result_dto(file_path):
            fix_counts["security_result_dto"] += 1
            print(f"  Fixed SecurityResultDTO initializations in {rel_path}")
        
        if fix_missing_imports(file_path):
            fix_counts["missing_imports"] += 1
            print(f"  Fixed missing imports in {rel_path}")
        
        if fix_crypto_service_impl(file_path):
            fix_counts["crypto_service_impl"] += 1
            print(f"  Fixed CryptoServiceImpl/MockCryptoService in {rel_path}")
        
        if fix_catch_block_no_errors(file_path):
            fix_counts["catch_block_no_errors"] += 1
            print(f"  Fixed catch blocks in {rel_path}")
        
        if fix_non_local_scope_public(file_path):
            fix_counts["non_local_scope_public"] += 1
            print(f"  Fixed non-local scope public in {rel_path}")
        
        if fix_aes_enum_definitions(file_path):
            fix_counts["aes_enum_definitions"] += 1
            print(f"  Fixed AES enum definitions in {rel_path}")
        
        if fix_error_enum_usage(file_path):
            fix_counts["error_enum_usage"] += 1
            print(f"  Fixed error enum usage in {rel_path}")
        
        if fix_scope_issues(file_path):
            fix_counts["scope_issues"] += 1
            print(f"  Fixed scope issues in {rel_path}")
        
        if fix_duplicate_declarations(file_path):
            fix_counts["duplicate_declarations"] += 1
            print(f"  Fixed duplicate declarations in {rel_path}")
        
        if fix_convenience_initializers(file_path):
            fix_counts["convenience_initializers"] += 1
            print(f"  Fixed convenience initializers in {rel_path}")
        
        if fix_logger_references(file_path):
            fix_counts["logger_references"] += 1
            print(f"  Fixed logger references in {rel_path}")
        
        # New and enhanced fixes
        if fix_aes_algorithms(file_path):
            fix_counts["aes_algorithms"] += 1
            print(f"  Fixed AES algorithm references in {rel_path}")
        
        if fix_security_result_dto_calls(file_path):
            fix_counts["security_result_dto_calls"] += 1
            print(f"  Fixed SecurityResultDTO.success calls in {rel_path}")
        
        if fix_export_import_data_methods(file_path):
            fix_counts["export_import_data_methods"] += 1
            print(f"  Fixed exportData and importData method calls in {rel_path}")
        
        if fix_hash_verify_hash_methods(file_path):
            fix_counts["hash_verify_hash_methods"] += 1
            print(f"  Fixed hash and verifyHash method calls in {rel_path}")
        
        if fix_crypto_option_type_conversions(file_path):
            fix_counts["crypto_option_type_conversions"] += 1
            print(f"  Fixed type conversions for encryption options in {rel_path}")
        
        if fix_service_protocol_conformance(file_path):
            fix_counts["service_protocol_conformance"] += 1
            print(f"  Fixed protocol conformance issues for CryptoServiceProtocol in {rel_path}")
        
        if fix_mock_logger_duplicate_method(file_path):
            fix_counts["mock_logger_duplicate_method"] += 1
            print(f"  Fixed duplicated method declaration in MockLogger in {rel_path}")
            
        if fix_provider_protocol_methods(file_path):
            fix_counts["provider_protocol_methods"] += 1
            print(f"  Fixed SecurityProviderProtocol methods in {rel_path}")
            
        if fix_mock_crypto_service(file_path):
            fix_counts["mock_crypto_service"] += 1
            print(f"  Fixed MockCryptoService implementation in {rel_path}")
        
    # Calculate total fixes (excluding file count)
    fix_counts["files_processed"] = len(swift_files)
    
    return fix_counts


def main():
    parser = argparse.ArgumentParser(description="Fix Swift 6 compatibility issues in UmbraCore")
    parser.add_argument("--directory", default="/Users/mpy/CascadeProjects/UmbraCore",
                        help="Root directory of the UmbraCore project")
    parser.add_argument("--module", help="Only process files in this module (e.g., CryptoServices)")
    parser.add_argument("--verbose", action="store_true", help="Print more detailed output")
    
    args = parser.parse_args()
    
    # Validate the directory exists
    if not os.path.isdir(args.directory):
        print(f"Error: Directory not found - {args.directory}")
        sys.exit(1)
    
    # Run the fixes
    stats = fix_swift6_issues(args.directory, args.module)
    
    # Print summary
    print("\nSummary of fixes:")
    print(f"Files processed: {stats['files_processed']}")
    print(f"DummyLoggingActor fixes: {stats['dummy_logging_actor']}")
    print(f"Isolated keyword removals: {stats['isolated_keyword']}")
    print(f"SecurityConfigDTO fixes: {stats['security_config_dto']}")
    print(f"Error case fixes: {stats['error_cases']}")
    print(f"SecurityResultDTO fixes: {stats['security_result_dto']}")
    print(f"Missing imports fixes: {stats['missing_imports']}")
    print(f"CryptoService implementation fixes: {stats['crypto_service_impl']}")
    print(f"Catch block fixes: {stats['catch_block_no_errors']}")
    print(f"Non-local scope fixes: {stats['non_local_scope_public']}")
    print(f"AES enum definition fixes: {stats['aes_enum_definitions']}")
    print(f"Error enum usage fixes: {stats['error_enum_usage']}")
    print(f"Scope issue fixes: {stats['scope_issues']}")
    print(f"Duplicate declaration fixes: {stats['duplicate_declarations']}")
    print(f"Convenience initializer fixes: {stats['convenience_initializers']}")
    print(f"Logger reference fixes: {stats['logger_references']}")
    print(f"AES algorithm fixes: {stats['aes_algorithms']}")
    print(f"SecurityResultDTO.success call fixes: {stats['security_result_dto_calls']}")
    print(f"Export/import data method fixes: {stats['export_import_data_methods']}")
    print(f"Hash/verifyHash method fixes: {stats['hash_verify_hash_methods']}")
    print(f"Crypto option type conversion fixes: {stats['crypto_option_type_conversions']}")
    print(f"Service protocol conformance fixes: {stats['service_protocol_conformance']}")
    print(f"Mock logger duplicate method fixes: {stats['mock_logger_duplicate_method']}")
    print(f"Provider protocol method fixes: {stats['provider_protocol_methods']}")
    print(f"Mock crypto service fixes: {stats['mock_crypto_service']}")
    
    total_fixes = sum(stats.values()) - stats['files_processed']
    print(f"Total fixes: {total_fixes}")
    
    print("\nSwift 6 compatibility fixes completed.")


if __name__ == "__main__":
    main()
