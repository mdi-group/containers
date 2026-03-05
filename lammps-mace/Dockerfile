# syntax=docker/dockerfile:1
FROM nvidia/cuda:12.4.1-devel-ubuntu22.04

LABEL org.opencontainers.image.authors="Bradley A. A. Martin" \
      org.opencontainers.image.title="LAMMPS + KOKKOS(CUDA) + ML-IAP + MACE (UCX/OpenMPI) for Slurm srun" \
      org.opencontainers.image.description="LAMMPS (stable_22Jul2025) + KOKKOS CUDA (sm80/A100) + ML-IAP + MACE + cuEquivariance + UCX + OpenMPI (PMIx-capable) with an srun-friendly wrapper." \
      org.opencontainers.image.source="https://github.com/mdi-group/containers"

ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-lc"]

# ---- Versions (easy to override at build time)
ARG UCX_VERSION=1.16.0
ARG OMPI_VERSION=4.1.6
ARG LAMMPS_REF=stable_22Jul2025
ARG TORCH_SPEC="torch==2.6.0+cu124 torchvision==0.21.0+cu124 torchaudio==2.6.0+cu124"
ARG MACE_VERSION=0.3.14
ARG CUEQ_VERSION=0.7.0

# ---- Prefixes
ENV UCX_PREFIX=/opt/ucx \
    OMPI_PREFIX=/opt/openmpi \
    LAMMPS_PREFIX=/opt/lammps

# ---- Environment (mirrors your %environment)
ENV PATH=${LAMMPS_PREFIX}/bin:${OMPI_PREFIX}/bin:${UCX_PREFIX}/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    LD_LIBRARY_PATH=/.singularity.d/libs:${LAMMPS_PREFIX}/lib:${OMPI_PREFIX}/lib:${UCX_PREFIX}/lib:/usr/local/cuda/lib64 \
    OMP_NUM_THREADS=1 \
    PYTHONUNBUFFERED=1 \
    OMPI_MCA_pml=ucx \
    OMPI_MCA_osc=ucx \
    OMPI_MCA_btl=^smcuda \
    UCX_WARN_UNUSED_ENV_VARS=n

RUN echo "=== [Base] System deps ===" && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 python3-pip python3-dev python3-venv python3-setuptools python3-wheel python3-distutils \
        build-essential git cmake ninja-build pkg-config \
        wget curl ca-certificates \
        m4 autoconf automake libtool flex bison make \
        libfftw3-dev libssl-dev zlib1g-dev libffi-dev \
        libblas-dev liblapack-dev gfortran \
        libjpeg-dev libpng-dev \
        libreadline-dev \
        openssh-client \
        vim less \
        libhwloc-dev libevent-dev libnuma-dev \
        uidmap \
        libibverbs-dev librdmacm-dev \
        libpmix-dev \
        libucx0 ucx-utils libucx-dev \
        pybind11-dev && \
    rm -rf /var/lib/apt/lists/* && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3 10

RUN echo "=== [Python] Upgrade pip and basic tools ===" && \
    python -m pip install --upgrade --no-cache-dir pip wheel setuptools

RUN echo "=== [Torch] Install PyTorch (CUDA 12.4 wheels) ===" && \
    python -m pip install --no-cache-dir \
        ${TORCH_SPEC} \
        --index-url https://download.pytorch.org/whl/cu124

RUN echo "=== [MACE stack] Install mace-torch, mace-models, deps ===" && \
    python -m pip install --no-cache-dir \
        cython \
        numpy \
        scipy \
        ase \
        h5py \
        matplotlib \
        pyfftw \
        cupy-cuda12x \
        e3nn \
        mace-torch==${MACE_VERSION} \
        mace-models

RUN echo "=== [PIP] Install cuEquivariance (base + torch + ops-cu12) ===" && \
    python -m pip install --no-cache-dir \
        cuequivariance==${CUEQ_VERSION} \
        cuequivariance-torch==${CUEQ_VERSION} \
        cuequivariance-ops-torch-cu12==${CUEQ_VERSION}

RUN echo "=== [UCX] Build UCX with CUDA support ===" && \
    cd /tmp && \
    wget -q https://github.com/openucx/ucx/releases/download/v${UCX_VERSION}/ucx-${UCX_VERSION}.tar.gz && \
    tar -xf ucx-${UCX_VERSION}.tar.gz && \
    cd ucx-${UCX_VERSION} && \
    ./configure \
        --prefix=${UCX_PREFIX} \
        --with-cuda=/usr/local/cuda \
        --with-verbs \
        --enable-mt && \
    make -j"$(nproc)" && \
    make install && \
    cd / && rm -rf /tmp/ucx*

RUN echo "=== [OpenMPI] Build CUDA + UCX aware OpenMPI (PMIx-capable) ===" && \
    cd /tmp && \
    wget -q https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-${OMPI_VERSION}.tar.gz && \
    tar -xf openmpi-${OMPI_VERSION}.tar.gz && \
    cd openmpi-${OMPI_VERSION} && \
    ./configure \
        --prefix=${OMPI_PREFIX} \
        --with-cuda=/usr/local/cuda \
        --with-ucx=${UCX_PREFIX} \
        --enable-mpi-cxx \
        --disable-static \
        --enable-shared \
        --with-pmix=external && \
    make -j"$(nproc)" && \
    make install && \
    ln -sf ${OMPI_PREFIX}/bin/mpirun     /usr/bin/mpirun && \
    ln -sf ${OMPI_PREFIX}/bin/mpiexec    /usr/bin/mpiexec && \
    ln -sf ${OMPI_PREFIX}/bin/ompi_info  /usr/bin/ompi_info && \
    cd / && rm -rf /tmp/openmpi*

RUN echo "=== [mpi4py] Build against our OpenMPI ===" && \
    export PATH=${OMPI_PREFIX}/bin:${PATH} && \
    export LD_LIBRARY_PATH=${OMPI_PREFIX}/lib:${LD_LIBRARY_PATH} && \
    MPICC=${OMPI_PREFIX}/bin/mpicc python -m pip install --no-cache-dir mpi4py

RUN echo "=== [LAMMPS] Clone ${LAMMPS_REF} and build with KOKKOS(CUDA sm80) + ML-IAP ===" && \
    mkdir -p "${LAMMPS_PREFIX}" && \
    cd /tmp && rm -rf /tmp/lammps && \
    git clone https://github.com/lammps/lammps.git && \
    cd lammps && \
    git checkout ${LAMMPS_REF} && \
    mkdir -p build && cd build && \
    export MPI_HOME=${OMPI_PREFIX} && \
    export PATH=${MPI_HOME}/bin:${PATH} && \
    export LD_LIBRARY_PATH=${MPI_HOME}/lib:${LD_LIBRARY_PATH} && \
    export CC=mpicc && export CXX=mpicxx && \
    echo "=== [CUDA driver stubs] Make libcuda visible at build/link time ===" && \
    export CUDA_HOME=/usr/local/cuda && \
    export CUDA_STUBS=${CUDA_HOME}/lib64/stubs && \
    ln -sf ${CUDA_STUBS}/libcuda.so ${CUDA_STUBS}/libcuda.so.1 && \
    export LIBRARY_PATH=${CUDA_STUBS}:${LIBRARY_PATH:-} && \
    cp ../cmake/presets/kokkos-cuda.cmake ./ && \
    cmake -C kokkos-cuda.cmake \
        -S ../cmake -B . \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_INSTALL_PREFIX=${LAMMPS_PREFIX} \
        -D BUILD_MPI=ON \
        -D BUILD_SHARED_LIBS=ON \
        -D PKG_ML-IAP=ON \
        -D PKG_ML-SNAP=ON \
        -D MLIAP_ENABLE_PYTHON=ON \
        -D PKG_PYTHON=ON \
        -D Kokkos_ARCH_AMPERE80=ON \
        -D CMAKE_CUDA_ARCHITECTURES=80-real \
        -D CMAKE_SHARED_LINKER_FLAGS="-Wl,-rpath-link,${CUDA_STUBS} -L${CUDA_STUBS}" \
        -D CMAKE_EXE_LINKER_FLAGS="-Wl,-rpath-link,${CUDA_STUBS} -L${CUDA_STUBS}" \
        -D CMAKE_INSTALL_RPATH="${LAMMPS_PREFIX}/lib;${OMPI_PREFIX}/lib;${UCX_PREFIX}/lib;/usr/local/cuda/lib64" \
        -D CMAKE_BUILD_WITH_INSTALL_RPATH=ON && \
    cmake --build . -j"$(nproc)" && \
    cmake --install . && \
    cmake --build . --target install-python && \
    ln -sf ${LAMMPS_PREFIX}/bin/lmp /usr/bin/lmp && \
    cd / && rm -rf /tmp/lammps

RUN echo "=== [Wrapper] Slurm srun-friendly launcher ===" && \
    cat >/usr/local/bin/lmp_srun <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Always use the container LAMMPS binary (never PATH-dependent)
LMP=/opt/lammps/bin/lmp

# If Slurm has already set CUDA_VISIBLE_DEVICES (e.g. via --gpus-per-task or --gpu-bind), keep it.
# Otherwise map 1 GPU per local rank.
if [[ -z "${CUDA_VISIBLE_DEVICES:-}" ]]; then
  export CUDA_VISIBLE_DEVICES="${SLURM_LOCALID:-0}"
fi

# Respect Slurm CPU settings if present
if [[ -z "${OMP_NUM_THREADS:-}" ]]; then
  export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK:-1}"
fi

# Default Kokkos flags (user can override by passing their own args)
DEFAULT_ARGS=(-k on g 1 -sf kk -pk kokkos gpu/aware on neigh half newton on)

exec "${LMP}" "${DEFAULT_ARGS[@]}" "$@"
EOF

RUN chmod +x /usr/local/bin/lmp_srun && \
    ln -sf /usr/local/bin/lmp_srun /usr/bin/lmp_srun

CMD ["bash"]