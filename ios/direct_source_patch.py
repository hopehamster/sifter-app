#!/usr/bin/env python3
"""
BoringSSL-GRPC Direct Source Patcher

This Python script directly patches the source files in BoringSSL-GRPC to fix the
'-G' flag issue on iOS builds. This can be used in environments where shell scripts
might not be ideal, or when a more portable solution is needed.

Usage:
  python3 direct_source_patch.py [--pod-dir PATH]

Options:
  --pod-dir PATH    Path to the Pods directory [default: ./Pods]
"""

import os
import sys
import re
import glob
import shutil
import argparse
from pathlib import Path

# ANSI color codes for terminal output
class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    END = '\033[0m'

def print_header(title):
    """Print a formatted header"""
    print(f"{Colors.BLUE}{Colors.BOLD}{'=' * 60}{Colors.END}")
    print(f"{Colors.BLUE}{Colors.BOLD}{title.center(60)}{Colors.END}")
    print(f"{Colors.BLUE}{Colors.BOLD}{'=' * 60}{Colors.END}")

def print_success(message):
    """Print a success message"""
    print(f"{Colors.GREEN}✓ {message}{Colors.END}")

def print_warning(message):
    """Print a warning message"""
    print(f"{Colors.YELLOW}⚠ {message}{Colors.END}")

def print_error(message):
    """Print an error message"""
    print(f"{Colors.RED}✗ {message}{Colors.END}")

def print_info(message):
    """Print an info message"""
    print(f"ℹ {message}")

def find_boringssl_dir(pods_dir):
    """Find the BoringSSL-GRPC directory in Pods"""
    boringssl_dirs = list(Path(pods_dir).glob("**/BoringSSL-GRPC"))
    
    if not boringssl_dirs:
        # Try a direct path in case it's a flat structure
        direct_path = Path(pods_dir) / "BoringSSL-GRPC"
        if direct_path.exists() and direct_path.is_dir():
            return direct_path
        
        print_error(f"BoringSSL-GRPC directory not found in {pods_dir}")
        return None
    
    return boringssl_dirs[0]

def patch_base_h(boringssl_dir):
    """Patch the base.h file to fix format attributes"""
    base_h_path = boringssl_dir / "src" / "include" / "openssl" / "base.h"
    
    if not base_h_path.exists():
        print_warning(f"base.h not found at {base_h_path}")
        return False
    
    print_info(f"Found base.h at {base_h_path}")
    
    # Read the file content
    with open(base_h_path, 'r') as f:
        content = f.read()
    
    # Make a backup
    backup_path = base_h_path.with_suffix(base_h_path.suffix + '.backup')
    if not backup_path.exists():
        shutil.copy(base_h_path, backup_path)
        print_info(f"Created backup at {backup_path}")
    
    # Replace format attributes
    pattern = r'__attribute__\(\(__format__\(__printf__, ([^)]*)\)\)\)'
    replacement = r'/* __attribute__((__format__(__printf__, \1))) */'
    
    new_content = re.sub(pattern, replacement, content)
    
    if new_content != content:
        with open(base_h_path, 'w') as f:
            f.write(new_content)
        print_success("Replaced format attributes in base.h")
    else:
        print_info("No format attributes found in base.h or already patched")
    
    # Create and insert patch header
    create_patch_header(boringssl_dir / "src" / "include" / "openssl")
    include_patch_header(base_h_path)
    
    return True

def create_patch_header(include_dir):
    """Create a special header to define our patched macros"""
    patch_header = include_dir / "boringssl_build_fix.h"
    
    patch_content = """/* BoringSSL build fix header to prevent -G flag usage */
#ifndef OPENSSL_HEADER_BORINGSSL_BUILD_FIX_H
#define OPENSSL_HEADER_BORINGSSL_BUILD_FIX_H

/* Redefine problematic macros */
#undef OPENSSL_PRINTF_FORMAT
#define OPENSSL_PRINTF_FORMAT(a, b)

/* Disable format attributes that might trigger -G flags */
#define __attribute__(x)

#endif  /* OPENSSL_HEADER_BORINGSSL_BUILD_FIX_H */
"""
    
    with open(patch_header, 'w') as f:
        f.write(patch_content)
    
    print_success(f"Created patch header at {patch_header}")
    return patch_header

def include_patch_header(base_h_path):
    """Include our patch header in base.h"""
    with open(base_h_path, 'r') as f:
        content = f.read()
    
    # Check if already included
    if "boringssl_build_fix.h" in content:
        print_info("Patch header already included in base.h")
        return True
    
    # Find the first include
    include_match = re.search(r'#include\s+<[^>]+>', content)
    if not include_match:
        print_warning("Could not find include pattern in base.h")
        return False
    
    # Insert our include after the first one
    first_include = include_match.group(0)
    include_patch = f'{first_include}\n#include <openssl/boringssl_build_fix.h> /* Patch for -G flag issue */'
    new_content = content.replace(first_include, include_patch)
    
    with open(base_h_path, 'w') as f:
        f.write(new_content)
    
    print_success("Added patch header include to base.h")
    return True

def patch_xcconfig_files(boringssl_dir):
    """Patch xcconfig files to remove -G flags and add our specific flags"""
    # Find xcconfig files, both in BoringSSL-GRPC and in Target Support Files
    xcconfig_files = list(Path(boringssl_dir).glob("**/*.xcconfig"))
    
    # Add Target Support Files path
    target_support_path = Path(boringssl_dir).parent / "Target Support Files" / "BoringSSL-GRPC"
    if target_support_path.exists():
        xcconfig_files.extend(target_support_path.glob("*.xcconfig"))
    
    if not xcconfig_files:
        print_warning("No xcconfig files found for BoringSSL-GRPC")
        return False
    
    for xcconfig in xcconfig_files:
        print_info(f"Patching {xcconfig}")
        
        # Read the content
        with open(xcconfig, 'r') as f:
            content = f.read()
        
        # Remove -G flags
        g_pattern = r'-G\S*'
        content = re.sub(g_pattern, '', content)
        
        # Update or add our flags
        if 'OTHER_CFLAGS' in content:
            content = re.sub(r'OTHER_CFLAGS\s*=\s*.*', 'OTHER_CFLAGS = -w', content)
        else:
            content += '\nOTHER_CFLAGS = -w'
        
        if 'OTHER_CXXFLAGS' in content:
            content = re.sub(r'OTHER_CXXFLAGS\s*=\s*.*', 'OTHER_CXXFLAGS = -w', content)
        else:
            content += '\nOTHER_CXXFLAGS = -w'
        
        if 'GCC_WARN_INHIBIT_ALL_WARNINGS' not in content:
            content += '\nGCC_WARN_INHIBIT_ALL_WARNINGS = YES'
        
        if 'COMPILER_INDEX_STORE_ENABLE' not in content:
            content += '\nCOMPILER_INDEX_STORE_ENABLE = NO'
        
        # Write back the content
        with open(xcconfig, 'w') as f:
            f.write(content)
        
        print_success(f"Patched {xcconfig.name}")
    
    return True

def create_compiler_wrapper(script_dir):
    """Create a clang compiler wrapper script to filter out -G flags"""
    wrapper_dir = script_dir / "bin"
    wrapper_dir.mkdir(exist_ok=True)
    
    wrapper_path = wrapper_dir / "clang_wrapper.sh"
    
    wrapper_content = """#!/bin/bash
# Wrapper script for clang to filter out -G flags

# Get the original clang compiler
REAL_CLANG=$(xcrun -f clang)

# Process all arguments and filter out -G flags
FILTERED_ARGS=()
for arg in "$@"; do
  if [[ "$arg" != -G* ]]; then
    FILTERED_ARGS+=("$arg")
  fi
done

# Execute the real clang with filtered arguments
exec "${REAL_CLANG}" "${FILTERED_ARGS[@]}"
"""
    
    with open(wrapper_path, 'w') as f:
        f.write(wrapper_content)
    
    # Make it executable
    os.chmod(wrapper_path, 0o755)
    
    # Create symlinks
    clang_link = wrapper_dir / "clang"
    clangpp_link = wrapper_dir / "clang++"
    
    if os.path.exists(clang_link) and os.path.islink(clang_link):
        os.unlink(clang_link)
    if os.path.exists(clangpp_link) and os.path.islink(clangpp_link):
        os.unlink(clangpp_link)
    
    os.symlink(wrapper_path, clang_link)
    os.symlink(wrapper_path, clangpp_link)
    
    print_success(f"Created compiler wrapper at {wrapper_path}")
    print_info(f"Symlinks created in {wrapper_dir}")
    
    return wrapper_dir

def create_patch_info(script_dir):
    """Create a file with information about the patch"""
    info_file = script_dir / "boringssl_patch_info.md"
    
    info_content = f"""# BoringSSL-GRPC Patch Information

This directory contains patches applied to fix the '-G' flag issue with BoringSSL-GRPC.

## Applied Fixes

1. **Format Attributes**: Commented out `__attribute__((__format__(__printf__, ...)))` in base.h
2. **Custom Header**: Created a header to override problematic macros
3. **Build Settings**: Updated xcconfig files to:
   - Remove -G flags
   - Set OTHER_CFLAGS = -w
   - Set OTHER_CXXFLAGS = -w
   - Set GCC_WARN_INHIBIT_ALL_WARNINGS = YES
   - Set COMPILER_INDEX_STORE_ENABLE = NO
4. **Compiler Wrapper**: Created a wrapper script to filter out -G flags at build time

## Using the Patch

To build with this patch applied:

```bash
# Add bin directory to PATH to use our clang wrapper
export PATH="{script_dir}/bin:$PATH"

# Build normally with flutter or xcodebuild
flutter build ios
```

Patch applied: {os.path.basename(__file__)} on {os.popen('date').read().strip()}
"""
    
    with open(info_file, 'w') as f:
        f.write(info_content)
    
    print_success(f"Created patch information file at {info_file}")

def main():
    parser = argparse.ArgumentParser(description="Patch BoringSSL-GRPC to fix the -G flag issue")
    parser.add_argument("--pod-dir", default="./Pods", help="Path to the Pods directory")
    args = parser.parse_args()
    
    # Current script directory for outputs
    script_dir = Path(__file__).parent.absolute()
    patch_dir = script_dir / "boringssl-patch"
    patch_dir.mkdir(exist_ok=True)
    
    print_header("BoringSSL-GRPC Direct Source Patcher")
    
    # Find the BoringSSL-GRPC directory
    boringssl_dir = find_boringssl_dir(args.pod_dir)
    if not boringssl_dir:
        sys.exit(1)
    
    print_success(f"Found BoringSSL-GRPC at {boringssl_dir}")
    
    # Patch base.h file
    patch_base_h(boringssl_dir)
    
    # Patch xcconfig files
    patch_xcconfig_files(boringssl_dir)
    
    # Create compiler wrapper
    create_compiler_wrapper(patch_dir)
    
    # Create patch info file
    create_patch_info(patch_dir)
    
    print_header("Patching Completed")
    print_success("All BoringSSL-GRPC sources have been patched")
    print_info(f"To use the compiler wrapper, add to your PATH: {patch_dir}/bin")
    print_info("You can now build your iOS project without the -G flag issue")

if __name__ == "__main__":
    main() 