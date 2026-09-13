#!/usr/bin/env bash
set -e

usage() {
  cat >&2 <<EOF
Usage: $0 [options]

Ensures the ROCm llama.cpp Docker image exists (building it if necessary)
and prints the image reference to stdout.

Options:
  -h, --help    Show this help and exit.

Environment:
  AMD_GFX_TARGET    GPU target to build for (e.g. gfx1101). If unset, the
                    target is detected from 'rocminfo' on the local machine.
  LLAMACPP_TAG      llama.cpp build tag (defaults to whatever was latest on the last update of this script).

Output:
  The image reference 'zjstraus-rocm-<target>-<tag>' is written to stdout;
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
  LLAMACPP_TAG=b10936
fi
echo "Image will build llama.cpp $LLAMACPP_TAG" >&2

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

DOCKER_TAG="zjstraus-rocm-$AMD_GFX_TARGET-$LLAMACPP_TAG"
if docker image inspect "$DOCKER_TAG" &> /dev/null; then
  echo "Docker image $DOCKER_TAG already exists" >&2
else
  echo "Building docker image $DOCKER_TAG" >&2
  docker build --build-arg "AMDGPU_TARGET=$AMD_GFX_TARGET" --build-arg "LLAMACPP_BUILD=$LLAMACPP_TAG" -t "$DOCKER_TAG" -f "$SCRIPT_DIR/docker/Dockerfile" "$SCRIPT_DIR/docker/" >&2
fi

echo "$DOCKER_TAG"