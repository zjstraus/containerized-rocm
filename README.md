# Containerized ROCm llama.cpp

Build definitions and helpers for:
 * llama.cpp -> [with community RDNA patches](https://github.com/stew675/llama-cpp-rdna-boosts.git) -> on ROCm -> in docker 
 * ComfyUI -> on ROCm -> in docker

for running on a local workstation.

## Scripts
* `ensure-containers.sh` - Builds the docker images if needed, outputs the references on STDOUT
* `download-hf.sh` - Runs the llamacpp image to pre-download an image from HuggingFace

## Requirements

- A machine with an AMD GPU that is supported by ROCm.
- The ROCm drivers and `rocminfo` installed on the host (used for auto-detection).
- Docker installed and runnable.

## Notes
- The image makes no attempt to be small, but is split into a multistage build to cache better if you're churning versions
- The images are per-GPU-target, and assumes there's only one flavor of hardware present
