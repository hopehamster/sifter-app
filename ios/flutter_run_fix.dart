// flutter_run_fix.dart
// Run with: flutter run -t ios/flutter_run_fix.dart
// This script integrates all BoringSSL-GRPC fixes directly into the Flutter build process

import 'dart:io';
import 'dart:async';

void main() async {
  print('🔄 BoringSSL-GRPC Flutter Fix Runner 🔄');
  print('======================================');

  // Detect if we're in the correct directory
  if (!await _isFlutterProject()) {
    print('❌ Error: This script must be run from a Flutter project root.');
    print('   Run: flutter run -t ios/flutter_run_fix.dart');
    exit(1);
  }

  print('✅ Flutter project detected');
  
  // Apply the fix and then run the app
  await _applyFix();
  
  // Run the app via Flutter
  print('\n🚀 Launching app with BoringSSL-GRPC fix applied...\n');
  await _runFlutterBuild();
}

Future<bool> _isFlutterProject() async {
  final pubspecFile = File('pubspec.yaml');
  if (!await pubspecFile.exists()) {
    return false;
  }
  
  final content = await pubspecFile.readAsString();
  return content.contains('flutter:');
}

Future<void> _applyFix() async {
  print('\n📝 Applying BoringSSL-GRPC fixes...');
  
  // Check for ios directory
  final iosDir = Directory('ios');
  if (!await iosDir.exists()) {
    print('❌ Error: ios directory not found. This is an iOS-specific fix.');
    exit(1);
  }
  
  // Check if fix script exists, if not create it
  final ultimateFixScript = File('ios/ultimate_boringssl_fix.sh');
  
  if (!await ultimateFixScript.exists()) {
    print('⚙️ Creating fix script...');
    await _createFixScript();
  }
  
  // Make it executable
  await Process.run('chmod', ['+x', 'ios/ultimate_boringssl_fix.sh']);
  
  // Run the script
  print('⚙️ Running fix script...');
  final result = await Process.run('./ios/ultimate_boringssl_fix.sh', [], 
      workingDirectory: 'ios', 
      runInShell: true);
  
  print(result.stdout);
  
  if (result.exitCode != 0) {
    print('⚠️ Warning: Fix script completed with non-zero exit code ${result.exitCode}');
    print('   Error output:');
    print(result.stderr);
  } else {
    print('✅ Fix applied successfully');
  }
}

Future<void> _createFixScript() async {
  final script = File('ios/ultimate_boringssl_fix.sh');
  
  // Create script content (simplified version)
  await script.writeAsString('''
#!/bin/bash

# Quick BoringSSL-GRPC fix script for Flutter integration
echo "🔄 Applying BoringSSL-GRPC fix from Flutter..."

# Ensure we're in the ios directory
if [ ! -f "Podfile" ]; then
  echo "❌ Error: This script must be run from the ios directory"
  exit 1
fi

# Clean pods if needed
if [ -d "Pods" ]; then
  echo "🧹 Cleaning existing Pods..."
  rm -rf Pods
  rm -f Podfile.lock
fi

# Apply permanent fix with CocoaPods patch
mkdir -p ~/.cocoapods/patches/BoringSSL-GRPC
cat > ~/.cocoapods/patches/BoringSSL-GRPC/remove_G_flag.patch << 'EOL'
diff --git a/src/include/openssl/base.h b/src/include/openssl/base.h
--- a/src/include/openssl/base.h
+++ b/src/include/openssl/base.h
@@ -103,7 +103,7 @@
 #if defined(__GNUC__) || defined(__clang__)
 // "printf" format attributes are supported on gcc/clang
 #define OPENSSL_PRINTF_FORMAT(string_index, first_to_check) \\
-    __attribute__((__format__(__printf__, string_index, first_to_check)))
+    /* __attribute__((__format__(__printf__, string_index, first_to_check))) */
 #else
 #define OPENSSL_PRINTF_FORMAT(string_index, first_to_check)
 #endif
EOL

# Patch Podfile
echo "📝 Patching Podfile..."
# Create backup
cp Podfile Podfile.backup

# Check if we need to add post_install hook
if ! grep -q "post_install" Podfile; then
  # Add post_install hook
  cat >> Podfile << 'EOL'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    if target.name == "BoringSSL-GRPC"
      target.build_configurations.each do |config|
        # Fix the -G flag issue
        config.build_settings['OTHER_CFLAGS'] = '-w'
        config.build_settings['OTHER_CXXFLAGS'] = '-w'
        config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
        config.build_settings['COMPILER_INDEX_STORE_ENABLE'] = 'NO'
      end
    end
  end
end
EOL
elif ! grep -q "BoringSSL-GRPC" Podfile; then
  # Find the post_install block
  POST_INSTALL_LINE=$(grep -n "post_install" Podfile | cut -d: -f1)
  if [ -n "$POST_INSTALL_LINE" ]; then
    # Add our BoringSSL-GRPC patch
    sed -i '' "${POST_INSTALL_LINE}a\\
  installer.pods_project.targets.each do |target|\\
    if target.name == \\"BoringSSL-GRPC\\"\\
      target.build_configurations.each do |config|\\
        # Fix the -G flag issue\\
        config.build_settings['OTHER_CFLAGS'] = '-w'\\
        config.build_settings['OTHER_CXXFLAGS'] = '-w'\\
        config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'\\
        config.build_settings['COMPILER_INDEX_STORE_ENABLE'] = 'NO'\\
      end\\
    end\\
  end" Podfile
  fi
fi

# Install pods
echo "📦 Installing pods..."
pod install

# Create wrapper script for build
echo "🔧 Creating build wrapper..."
cat > clang_wrapper.sh << 'EOL'
#!/bin/bash
# Wrapper script for clang to filter out -G flags
REAL_CLANG="$(xcrun -f clang)"
# Filter arguments
ARGS=()
for arg in "$@"; do
  if [[ "$arg" != -G* ]]; then
    ARGS+=("$arg")
  fi
done
# Execute real clang with filtered arguments
exec "$REAL_CLANG" "${ARGS[@]}"
EOL

chmod +x clang_wrapper.sh
mkdir -p bin
ln -sf "$(pwd)/clang_wrapper.sh" "bin/clang"
ln -sf "$(pwd)/clang_wrapper.sh" "bin/clang++"

echo "✅ BoringSSL-GRPC fix applied successfully"
''');

  await Process.run('chmod', ['+x', 'ios/ultimate_boringssl_fix.sh']);
  print('✅ Created fix script at ios/ultimate_boringssl_fix.sh');
}

Future<void> _runFlutterBuild() async {
  print('⚙️ Running flutter build with BoringSSL fix...');
  
  // Set the PATH to include our compiler wrapper
  final envVars = Map<String, String>.from(Platform.environment);
  final iosDir = Directory.current.path + '/ios';
  final binDir = '$iosDir/bin';
  
  if (await Directory(binDir).exists()) {
    final currentPath = envVars['PATH'] ?? '';
    envVars['PATH'] = '$binDir:$currentPath';
    print('✅ Added compiler wrapper to PATH');
  }
  
  // Run flutter build
  final process = await Process.start(
    'flutter',
    ['build', 'ios', '--no-codesign'],
    environment: envVars,
    mode: ProcessStartMode.inheritStdio, // Show output in real-time
  );
  
  final exitCode = await process.exitCode;
  
  if (exitCode != 0) {
    print('\n❌ Flutter build failed with exit code $exitCode');
    print('   Try running the fix script manually: cd ios && ./ultimate_boringssl_fix.sh');
  } else {
    print('\n✅ Flutter build completed successfully!');
    print('   You can now run the app from Xcode or with:');
    print('   flutter run');
  }
} 