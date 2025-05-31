#!/bin/bash

# Find all Dart files and replace sifter with sifter_app in imports
find . -type f -name "*.dart" -exec sed -i '' 's/package:sifter\//package:sifter_app\//g' {} +

echo "Updated package imports from sifter to sifter_app" 