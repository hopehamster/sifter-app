#!/bin/bash
# Launch Xcode with patched environment
export PATH="$(pwd)/bin:$PATH"
open Runner.xcworkspace
