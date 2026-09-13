#!/bin/bash
set -e

# Build largely based on the AUR build for llama.cpp-hpp

pushd llama.cpp

# Build the UI
pushd tools/ui
npm ci
npm run build
popd
