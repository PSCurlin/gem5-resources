# Start from Ubuntu 24.04 base image
FROM ubuntu:24.04 AS stage1

# Install necessary packages for kernel and module build
RUN apt update && apt install -y \
    build-essential \
    libncurses-dev \
    bison \
    flex \
    libssl-dev \
    libelf-dev \
    bc \
    wget \
    git \
    kmod


RUN sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/ubuntu.sources
RUN apt update
RUN mkdir /workspaces 
RUN cd /workspaces && git clone --depth 1 --branch v6.19 https://github.com/torvalds/linux.git linux-6.19.0

COPY .config.arm64.6.8 /workspaces/linux-6.19.0/.config

RUN cd /workspaces/linux-6.19.0 && \
    make olddefconfig && \
    make -j $(nproc) ARCH=arm64 && \
    make INSTALL_MOD_PATH=/workspaces/output modules_install

RUN git clone https://github.com/gem5/gem5.git --depth=1 --filter=blob:none --no-checkout --sparse --single-branch --branch=stable && \
    cd gem5 && \
    git sparse-checkout add util/m5 && \
    git sparse-checkout add util/gem5_bridge && \
    git sparse-checkout add include && \
    git checkout

RUN cd gem5/util/gem5_bridge && \
    make KMAKEDIR=/workspaces/linux-6.8.0 INSTALL_MOD_PATH=/workspaces/output build install

RUN cd /workspaces/output/lib/modules/* && \
    rm -rf build

FROM scratch AS export-stage
COPY --from=stage1 /workspaces/output/lib/modules .
COPY --from=stage1 /workspaces/linux-6.8.0/vmlinux .
