#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<EOF
Usage: $0 <mountpoint> <model>

Uses the dockerized llama.cpp build to download a HuggingFace model to the given docker mount reference (volume/bind)

Arguments:
  <mountpoint> Docker volume mount target

  <model>    HuggingFace repo reference, e.g.:
               ggml-org/gemma-3-4b-it-GGUF
               ggml-org/gemma-3-4b-it-GGUF:Q8_0

EOF
}

if [[ $# -ne 2 || -z "${1:-}" ]]; then
  usage
  exit 2
fi

mountpoint="$1"
model="$2"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# ensure-containers.sh prints the image reference to stdout; build/detection
# logs go to stderr, so capturing stdout yields just the tag. If it fails
# (e.g. no GPU detected and no AMD_GFX_TARGET), set -e aborts with its code.
image="$("$SCRIPT_DIR/ensure-containers.sh")"
if [[ -z "$image" ]]; then
  echo "error: ensure-containers.sh did not return an image reference"
  exit 1
fi

echo "Downloading '$model' -> '$mountpoint' (image: $image)"

docker run --rm \
  -v "$mountpoint:/mnt/hub" \
  "$image" \
  llama download --mtp -hf "$model"
