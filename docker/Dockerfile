# SemiTO-V Verification Task Force: development and CI image (AETHER 2.0)
#
# One image for every laptop (via VS Code Dev Containers) and for CI.
# Every tool version is pinned below. To upgrade a tool, change its ARG,
# rebuild, run `check-tools` and the hello test, then merge.
#
# Builds for linux/amd64 and linux/arm64 (Apple Silicon).

ARG BASE_IMAGE=ubuntu:24.04

# ---------------------------------------------------------------------------
# Stage 1: Spike (lowRISC co-simulation fork), built from source
# ---------------------------------------------------------------------------
FROM ${BASE_IMAGE} AS spike-build

# Head of lowRISC's "ibex_cosim" branch: the Spike that Ibex's co-sim uses.
ARG SPIKE_REPO=https://github.com/lowRISC/riscv-isa-sim.git
ARG SPIKE_COMMIT=aadf648d742de54f0a50eec01ceffd13ed12a1d1

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      build-essential ca-certificates device-tree-compiler git \
 && rm -rf /var/lib/apt/lists/*

RUN git init -q /src/spike && cd /src/spike \
 && git fetch -q --depth 1 "${SPIKE_REPO}" "${SPIKE_COMMIT}" \
 && git checkout -q FETCH_HEAD \
 && mkdir build && cd build \
 && ../configure --prefix=/opt/spike --enable-commitlog --enable-misaligned --without-boost \
 && make -j"$(nproc)" \
 && make install \
 && { find /opt/spike -type f \( -name '*.a' -o -name '*.so*' -o -perm -u+x \) \
        -exec strip --strip-debug {} + 2>/dev/null || true; }

# ---------------------------------------------------------------------------
# Stage 2: riscv-tests for RV32 (self-checking ISA tests)
# ---------------------------------------------------------------------------
FROM ${BASE_IMAGE} AS riscv-tests-build

ARG RISCV_TESTS_REPO=https://github.com/riscv-software-src/riscv-tests.git
ARG RISCV_TESTS_COMMIT=3df703cd52d5f0d8224e3c50bf03c6cb70efff98

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates gcc-riscv64-unknown-elf git make \
 && rm -rf /var/lib/apt/lists/*

# Only the suites that match a bare-metal RV32I core: user-level integer
# (rv32ui) and machine-mode (rv32mi), in the physical-memory (-p) environment.
# The -v variants need virtual memory and a C library, so they are skipped.
RUN git clone "${RISCV_TESTS_REPO}" /src/riscv-tests \
 && cd /src/riscv-tests \
 && git checkout "${RISCV_TESTS_COMMIT}" \
 && git submodule update --init --depth 1 env \
 && printf 'p-only: $(rv32ui_p_tests) $(rv32mi_p_tests)\n' > /tmp/p-only.mk \
 && make -C isa -f Makefile -f /tmp/p-only.mk XLEN=32 RISCV_PREFIX=riscv64-unknown-elf- -j"$(nproc)" p-only \
 && mkdir -p /opt/riscv-tests/isa \
 && find isa -maxdepth 1 -type f -name 'rv32*-p-*' -exec cp {} /opt/riscv-tests/isa/ \;

# ---------------------------------------------------------------------------
# Stage 3: the image people actually use
# ---------------------------------------------------------------------------
FROM ${BASE_IMAGE}

ARG TARGETARCH
ARG OSS_CAD_SUITE_DATE=2026-11-17
ARG RISCV_FORMAL_REPO=https://github.com/YosysHQ/riscv-formal.git
ARG RISCV_FORMAL_COMMIT=c992aa61fdfe0846c5ed90324c596202a1c69b76
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

LABEL org.opencontainers.image.title="semitov-verif" \
      org.opencontainers.image.description="SemiTO-V verification environment: Verilator, cocotb, pyuvm, SymbiYosys, riscv-formal, Spike"

# System packages:
#  - build-essential, ccache: compile the C++ that Verilator generates (ccache speeds rebuilds)
#  - liblz4-dev, zlib1g-dev: Verilator's FST waveform writer
#  - python3-dev, python3-venv: cocotb loads into the simulator through libpython
#  - gcc-riscv64-unknown-elf: bare-metal RV32 test programs (freestanding, no C library;
#    the Compiler team's custom toolchain brings its own when the firmware needs one)
#  - device-tree-compiler: needed by Spike at run time
#  - iproute2: create the TAP interface (Step 6)
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      build-essential ccache ca-certificates curl device-tree-compiler git \
      gcc-riscv64-unknown-elf \
      iproute2 iputils-ping less liblz4-dev make nano perl zlib1g-dev \
      python3 python3-dev python3-venv sudo xz-utils \
 && rm -rf /var/lib/apt/lists/*

# OSS CAD Suite: Verilator, Yosys, SymbiYosys, SMT solvers and more,
# prebuilt by YosysHQ. Pinned to one dated release.
RUN case "${TARGETARCH:-amd64}" in \
      amd64) OCS_ARCH=x64 ;; \
      arm64) OCS_ARCH=arm64 ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
 && curl -fsSL "https://github.com/YosysHQ/oss-cad-suite-build/releases/download/${OSS_CAD_SUITE_DATE}/oss-cad-suite-linux-${OCS_ARCH}-$(echo ${OSS_CAD_SUITE_DATE} | tr -d -).tgz" \
    | tar -xz -C /opt

# Spike and riscv-tests from the build stages
COPY --from=spike-build /opt/spike /opt/spike
COPY --from=riscv-tests-build /opt/riscv-tests /opt/riscv-tests
RUN echo /opt/spike/lib > /etc/ld.so.conf.d/spike.conf && ldconfig

# riscv-formal: a framework of checker files, not a binary
RUN git clone "${RISCV_FORMAL_REPO}" /opt/riscv-formal \
 && git -C /opt/riscv-formal checkout "${RISCV_FORMAL_COMMIT}" \
 && rm -rf /opt/riscv-formal/.git

# Python packages in a virtual environment, pinned in requirements.txt
COPY requirements.txt /tmp/requirements.txt
RUN python3 -m venv /opt/venv \
 && /opt/venv/bin/pip install --no-cache-dir --upgrade pip \
 && /opt/venv/bin/pip install --no-cache-dir -r /tmp/requirements.txt \
 && rm /tmp/requirements.txt

# PATH order matters: the venv's python3 comes before the one bundled in
# OSS CAD Suite, so cocotb, pyuvm and friends are always the pinned ones.
ENV PATH=/opt/venv/bin:/opt/spike/bin:/opt/oss-cad-suite/bin:${PATH} \
    VIRTUAL_ENV=/opt/venv \
    RISCV_FORMAL=/opt/riscv-formal \
    RISCV_TESTS=/opt/riscv-tests \
    PKG_CONFIG_PATH=/opt/spike/lib/pkgconfig \
    CCACHE_DIR=/home/${USERNAME}/.cache/ccache \
    LANG=C.UTF-8

# Helper scripts
COPY check-tools.sh /usr/local/bin/check-tools
COPY tap-up.sh /usr/local/bin/tap-up
RUN chmod 755 /usr/local/bin/check-tools /usr/local/bin/tap-up

# Non-root user with passwordless sudo (sudo is only needed for tap-up).
# The official ubuntu:24.04 image ships a user "ubuntu" with UID 1000: remove it.
RUN (userdel -r ubuntu 2>/dev/null || true) \
 && groupadd --gid "${USER_GID}" "${USERNAME}" \
 && useradd --uid "${USER_UID}" --gid "${USER_GID}" --create-home --shell /bin/bash "${USERNAME}" \
 && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}" \
 && chmod 0440 "/etc/sudoers.d/${USERNAME}" \
 && mkdir -p "/home/${USERNAME}/.cache/ccache" \
 && chown -R "${USER_UID}:${USER_GID}" "/home/${USERNAME}"

USER ${USERNAME}
WORKDIR /home/${USERNAME}
CMD ["/bin/bash"]
