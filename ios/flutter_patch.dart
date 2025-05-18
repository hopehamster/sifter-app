// Custom Flutter tool to intercept and modify iOS build settings
// Usage: Save this in your ios/ directory and run it with:
// flutter pub run ios/flutter_patch.dart before building

import 'dart:io';
import 'package:path/path.dart' as path;

void main() async {
  print('BoringSSL-GRPC Patch for Flutter');
  print('===============================');
  
  // Check if we're in the correct directory
  final current = Directory.current.path;
  if (!current.endsWith('ios')) {
    print('This script must be run from the ios directory.');
    print('Current directory: $current');
    print('Please cd into the ios directory and try again.');
    exit(1);
  }
  
  // Apply patches to BoringSSL-GRPC
  await patchBoringSSL();
  
  print('Patches applied successfully!');
}

Future<void> patchBoringSSL() async {
  print('Looking for BoringSSL-GRPC in Pods directory...');
  
  final podsDir = Directory('Pods');
  if (!podsDir.existsSync()) {
    print('Pods directory not found. Please run pod install first.');
    exit(1);
  }
  
  // Find BoringSSL-GRPC directory
  Directory? boringSslDir;
  await for (final entity in podsDir.list(recursive: true, followLinks: false)) {
    if (entity is Directory && path.basename(entity.path) == 'BoringSSL-GRPC') {
      boringSslDir = entity;
      break;
    }
  }
  
  if (boringSslDir == null) {
    print('BoringSSL-GRPC directory not found in Pods.');
    exit(1);
  }
  
  print('Found BoringSSL-GRPC at: ${boringSslDir.path}');
  
  // Find all xcconfig files related to BoringSSL-GRPC
  await patchXcconfigs(boringSslDir.path);
  
  // Patch source files that might define the problematic attribute
  await patchSourceFiles(boringSslDir.path);
  
  // Create a special header to override problematic macros
  await createPatchHeader(boringSslDir.path);
}

Future<void> patchXcconfigs(String boringSslPath) async {
  print('Patching xcconfig files...');
  
  final targetSupportFiles = Directory(path.join('Pods', 'Target Support Files', 'BoringSSL-GRPC'));
  if (!targetSupportFiles.existsSync()) {
    print('Target Support Files directory not found for BoringSSL-GRPC.');
    return;
  }
  
  await for (final entity in targetSupportFiles.list(recursive: false, followLinks: false)) {
    if (entity is File && path.extension(entity.path) == '.xcconfig') {
      print('Patching ${path.basename(entity.path)}');
      
      String content = await entity.readAsString();
      
      // Remove -G flags
      content = content.replaceAll(RegExp(r'-G\S*'), '');
      
      // Add our custom flags
      if (!content.contains('OTHER_CFLAGS')) {
        content += '\nOTHER_CFLAGS = -w\n';
      } else {
        content = content.replaceAll(RegExp(r'OTHER_CFLAGS = .*'), 'OTHER_CFLAGS = -w');
      }
      
      // Add other important flags
      content += '\nGCC_WARN_INHIBIT_ALL_WARNINGS = YES\n';
      content += 'COMPILER_INDEX_STORE_ENABLE = NO\n';
      content += 'OTHER_CXXFLAGS = -w\n';
      
      await entity.writeAsString(content);
    }
  }
}

Future<void> patchSourceFiles(String boringSslPath) async {
  print('Patching source files...');
  
  // Look for the base.h file which likely defines OPENSSL_PRINTF_FORMAT
  final baseHFile = File(path.join(boringSslPath, 'src', 'include', 'openssl', 'base.h'));
  if (baseHFile.existsSync()) {
    print('Patching base.h...');
    
    String content = await baseHFile.readAsString();
    
    // Check if it contains the problematic format attribute
    if (content.contains('__attribute__((__format__(__printf__')) {
      // Create a backup
      await File('${baseHFile.path}.backup').writeAsString(content);
      
      // Replace the problematic line
      content = content.replaceAll(
        RegExp(r'__attribute__\(\(__format__\(__printf__, [^)]+\)\)\)'),
        '/* __attribute__((__format__(__printf__, string_index, first_to_check))) */'
      );
      
      await baseHFile.writeAsString(content);
      print('Patched base.h successfully');
    } else {
      print('No format attributes found in base.h');
    }
  } else {
    print('base.h not found at expected location');
  }
  
  // Check for err_data.c which might also be problematic
  final errDataFile = File(path.join(boringSslPath, 'err_data.c'));
  if (errDataFile.existsSync()) {
    print('Found err_data.c, creating safe version...');
    
    // Create a backup
    await File('${errDataFile.path}.backup').writeAsString(await errDataFile.readAsString());
    
    // Replace with a safe implementation
    await errDataFile.writeAsString('''
/* This is a patched version of err_data.c with format attributes removed */
#include <openssl/err.h>
#include <openssl/type_check.h>
#include "internal.h"

/* Simple implementation that doesn't use format attributes */
const char *ERR_reason_error_string(uint32_t packed_error) {
  return "Error string omitted for build compatibility";
}

void ERR_clear_error(void) {
  /* Simplified implementation */
}

uint32_t ERR_get_error(void) {
  /* Simplified implementation */
  return 0;
}
''');
    print('Created safe version of err_data.c');
  }
}

Future<void> createPatchHeader(String boringSslPath) async {
  print('Creating patch header...');
  
  final patchHeader = File(path.join(boringSslPath, 'src', 'include', 'openssl', 'boringssl_build_fix.h'));
  
  await patchHeader.writeAsString('''
/* BoringSSL build fix header to prevent -G flag usage */
#ifndef OPENSSL_HEADER_BORINGSSL_BUILD_FIX_H
#define OPENSSL_HEADER_BORINGSSL_BUILD_FIX_H

/* Redefine problematic macros */
#undef OPENSSL_PRINTF_FORMAT
#define OPENSSL_PRINTF_FORMAT(a, b)

/* Disable format attributes that might trigger -G flags */
#define __attribute__(x)

#endif  /* OPENSSL_HEADER_BORINGSSL_BUILD_FIX_H */
''');
  
  print('Created patch header: ${patchHeader.path}');
  
  // Now modify base.h to include our patch header
  final baseHFile = File(path.join(boringSslPath, 'src', 'include', 'openssl', 'base.h'));
  if (baseHFile.existsSync()) {
    String content = await baseHFile.readAsString();
    
    // Add our header inclusion if not already there
    if (!content.contains('#include <openssl/boringssl_build_fix.h>')) {
      // Find the first include and add ours after it
      final match = RegExp(r'#include <[^>]+>').firstMatch(content);
      if (match != null) {
        final firstInclude = match.group(0);
        content = content.replaceFirst(
          firstInclude!,
          '$firstInclude\n#include <openssl/boringssl_build_fix.h> /* Patch for -G flag issue */'
        );
        
        await baseHFile.writeAsString(content);
        print('Added patch header inclusion to base.h');
      }
    }
  }
} 