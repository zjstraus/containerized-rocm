#!/usr/bin/env bash
set -e

usage() {
  cat >&2 <<EOF
Usage: $0 [options]

Ensures the ROCm llama.cpp and ComfyUI Docker images exist (building if necessary)
and prints the image references to stdout.

Options:
  -h, --help    Show this help and exit.

Environment:
  AMD_GFX_TARGET    GPU target to build for (e.g. gfx1101). If unset, the
                    target is detected from 'rocminfo' on the local machine.
  LLAMACPP_TAG      llama.cpp build tag (defaults to whatever was latest on the last update of this script).
  COMFYUI_TAG       ComfyUI build tag (defaults to whatever was latest on the last update of this script).

Output:
  The image reference 'zjstraus-rocm-<target>-<program>-<tag>' is written to stdout;
  all diagnostics and build logs go to stderr.
EOF
}

case "${1:-}" in
  -h|--help|help)
    usage
    exit 0
    ;;
  "")
    : ;;
  *)
    echo "error: unexpected argument: $1" >&2
    usage
    exit 2
    ;;
esac

if [[ -z "$AMD_GFX_TARGET" ]]; then
  if rocinfo_output=$(rocminfo 2>/dev/null); then
    echo "Using rocminfo to detect local hardware" >&2

    regex="Name:[[:blank:]]+(gfx[[:digit:]]+)"
    if [[ "$rocinfo_output" =~ $regex ]]; then
      AMD_GFX_TARGET="${BASH_REMATCH[1]}"
    else
      echo "could not parse rocminfo output for a 'Name: gfxXXXX' line" >&2
      exit 1
    fi
  else
     echo "rocminfo not found, cannot detect GPU model" >&2
     echo "Manually override by setting AMD_GFX_TARGET" >&2
     exit 1
  fi
else
  echo "using external AMD_GFX_TARGET" >&2
fi
echo "Image will target $AMD_GFX_TARGET" >&2

if [[ -z "$LLAMACPP_TAG" ]]; then
  LLAMACPP_TAG=b11071
fi
echo "Image will build llama.cpp $LLAMACPP_TAG" >&2

if [[ -z "$COMFYUI_TAG" ]]; then
  COMFYUI_TAG=v0.37.0
fi
echo "Image will build comfyui $COMFYUI_TAG" >&2

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

ROOT_IMAGE="zjstraus-rocm-$AMD_GFX_TARGET"
if docker image inspect "$ROOT_IMAGE" &> /dev/null; then
  echo "Docker image $ROOT_IMAGE already exists" >&2
else
  echo "Building docker image $ROOT_IMAGE" >&2
  docker build --build-arg "AMDGPU_TARGET=$AMD_GFX_TARGET" -t "$ROOT_IMAGE" -f "$SCRIPT_DIR/docker/Dockerfile.rocmbase" "$SCRIPT_DIR/docker/" >&2
fi

COMFYUI_IMAGE="zjstraus-rocm-$AMD_GFX_TARGET-comfyui-$COMFYUI_TAG"
if docker image inspect "$COMFYUI_IMAGE" &> /dev/null; then
  echo "Docker image $COMFYUI_IMAGE already exists" >&2
else
  echo "Building docker image $COMFYUI_IMAGE" >&2
  docker build --build-arg "ROCM_BASE_IMAGE=${ROOT_IMAGE}" --build-arg "AMDGPU_TARGET=$AMD_GFX_TARGET" --build-arg "COMFYUI_BUILD=$COMFYUI_TAG" -t "$COMFYUI_IMAGE" -f "$SCRIPT_DIR/docker/Dockerfile.comfyui" "$SCRIPT_DIR/docker/" >&2
fi

LLAMACPP_IMAGE="zjstraus-rocm-$AMD_GFX_TARGET-llamacpp-$LLAMACPP_TAG"
if docker image inspect "$LLAMACPP_IMAGE" &> /dev/null; then
  echo "Docker image $LLAMACPP_IMAGE already exists" >&2
else
  echo "Building docker image $LLAMACPP_IMAGE" >&2
  docker build --build-arg "ROCM_BASE_IMAGE=${ROOT_IMAGE}" --build-arg "AMDGPU_TARGET=$AMD_GFX_TARGET" --build-arg "LLAMACPP_BUILD=$LLAMACPP_TAG" -t "$LLAMACPP_IMAGE" -f "$SCRIPT_DIR/docker/Dockerfile.llamacpp" "$SCRIPT_DIR/docker/" >&2
fi

echo "$COMFYUI_IMAGE"
echo "$LLAMACPP_IMAGE"
