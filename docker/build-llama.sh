#!/bin/bash
set -e

# Build largely based on the AUR build for llama.cpp-hpp

pushd llama.cpp

HIP_PATH="$(hipconfig -R)"
HIPCXX="$(hipconfig -l)/clang"
HIP_PLATFORM=amd

export HIP_PATH
export HIPCXX
export HIP_PLATFORM

cmake_options=(
  -B build
  -DCMAKE_BUILD_TYPE=Release
  -DCMAKE_INSTALL_PREFIX='/usr'
  -DCMAKE_HIP_FLAGS="-mllvm --amdgpu-unroll-threshold-local=600"
  -DBUILD_SHARED_LIBS=ON
  -DLLAMA_BUILD_TESTS=OFF
  -DLLAMA_USE_SYSTEM_GGML=OFF
  -DLLAMA_BUILD_WEBUI=OFF
  -DGGML_ALL_WARNINGS=OFF
  -DGGML_ALL_WARNINGS_3RD_PARTY=OFF
  -DGGML_BUILD_EXAMPLES=OFF
  -DGGML_BUILD_TESTS=OFF
  -DGGML_LTO=ON
  -DGGML_RPC=ON
  -DGGML_HIP=ON
  -DGGML_HIP_GRAPHS=ON
  -DHIP_PLATFORM="$HIP_PLATFORM"
  -DGGML_NATIVE=ON
  -DAMDGPU_TARGETS="$AMDGPU_TARGET"
  -DGGML_CUDA_FA_ALL_QUANTS=ON
  -Wno-dev
)

cmake "${cmake_options[@]}"
cmake --build build -- -j 8
cmake --install build
