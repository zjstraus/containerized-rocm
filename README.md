# Containerized ROCm llama.cpp

Build definitions and helpers for llama.cpp -> on rocm -> in docker for running LLMs on a local workstation.

## Scripts
* `ensure-containers.sh` - Builds the docker image if needed, outputs the reference on STDOUT
* `download-hf.sh` - Runs the image to pre-download an image from HuggingFace

## Requirements

- A machine with an AMD GPU that is supported by ROCm.
- The ROCm drivers and `rocminfo` installed on the host (used for auto-detection).
- Docker installed and runnable.

## Notes
- The image makes no attempt to be small, but is split into a multistage build to cache better if you're churning llama versions
- The image is per-GPU-target, and assumes there's only one flavor of hardware present
