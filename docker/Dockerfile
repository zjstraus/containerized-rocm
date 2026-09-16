FROM ubuntu:26.04 AS initial_os

RUN apt-get update && apt-get install -y \
  build-essential \
  cmake \
  curl \
  git \
  gpg \
  libatomic1 \
  libquadmath0 \
  npm \
  perl \
  wget

FROM initial_os AS rocm

ADD rocm-apt.gpg /etc/apt/keyrings/amdrocm.gpg
ADD rocm-apt.sources /etc/apt/sources.list.d/amdrocm-stable.sources

ARG AMDGPU_TARGET

RUN apt-get update && apt-get -y install \
  amdrocm10.0-$AMDGPU_TARGET \
  amdrocm-core-sdk10.0-$AMDGPU_TARGET

ADD rocm.ld.conf /etc/ld.so.conf.d/rocm.conf
RUN ldconfig

FROM rocm AS llama_dl

ARG LLAMACPP_BUILD

ADD --unpack=true https://github.com/ggml-org/llama.cpp/archive/refs/tags/$LLAMACPP_BUILD.tar.gz /usr/src/
RUN mv /usr/src/llama.cpp-$LLAMACPP_BUILD /usr/src/llama.cpp

FROM llama_dl AS llama_build

ENV AMDGPU_TARGET=${AMDGPU_TARGET}

ADD build-llama.sh /usr/src/
RUN /bin/bash -c "cd /usr/src; ./build-llama.sh"

FROM llama_build AS llama
ENV HF_HUB_CACHE=/mnt/hub
RUN mkdir /mnt/hub
