# lammps-macefield (CUDA 12.4 / A100 sm80)

Container image providing:

-   **Base**: `nvidia/cuda:12.4.1-devel-ubuntu22.04`
-   **LAMMPS**: `stable_22Jul2025`
-   **KOKKOS CUDA**: built for **A100 (sm80)**
    (`CMAKE_CUDA_ARCHITECTURES=80-real`)
-   **LAMMPS packages**: `ML-IAP`, `ML-SNAP`, `PYTHON` (+ python install
    target)
-   **PyTorch**: `2.6.0+cu124` (cu124 wheels)
-   **MACE-Field**: `mdi-group/mace-field` (installed from GitHub,
    editable install)
-   **mace-models**: installed from PyPI
-   **cuEquivariance**: `0.7.0` (base + torch + ops-cu12)
-   **UCX**: `1.16.0` (CUDA-enabled build)
-   **OpenMPI**: `4.1.6` (CUDA + UCX aware; PMIx-capable)
-   **mpi4py** built against the bundled OpenMPI
-   Wrapper: **`lmp_srun`** for Slurm-friendly GPU/CPU env defaults

> Targeted at UCL Young A100 nodes and similar systems. Single-node GPU
> runs are the "most portable".\
> Multi-node MPI portability depends on the site's Slurm/PMIx/MPI stack.

------------------------------------------------------------------------

# Pull

``` bash
docker pull ghcr.io/mdi-group/lammps-macefield:<tag>
```

Suggested tag style (example):

    cuda12.4.1-lammps-stable_22Jul2025-macefield

------------------------------------------------------------------------

# Quick sanity checks

Check LAMMPS:

``` bash
docker run --rm --gpus all ghcr.io/mdi-group/lammps-macefield:<tag> lmp -h
```

Check PyTorch:

``` bash
docker run --rm --gpus all ghcr.io/mdi-group/lammps-macefield:<tag>   python -c "import torch; print(torch.__version__, torch.cuda.is_available())"
```

Check MACE-Field import:

``` bash
docker run --rm ghcr.io/mdi-group/lammps-macefield:<tag>   python -c "import mace; import mace.calculators.lammps_mliap_mace as m; print(mace.__file__); print(m.__file__)"
```

------------------------------------------------------------------------

# Run LAMMPS (Docker)

From a directory containing `in.lmp`:

``` bash
docker run --rm --gpus all -v "$PWD:/work" -w /work   ghcr.io/mdi-group/lammps-macefield:<tag>   lmp -in in.lmp
```

------------------------------------------------------------------------

# Slurm wrapper: `lmp_srun`

`lmp_srun` is designed to work nicely under Slurm:

-   If `CUDA_VISIBLE_DEVICES` is already set by Slurm
    (`--gpus-per-task`, `--gpu-bind`), it is respected.
-   Otherwise it maps **1 GPU per local rank** using `SLURM_LOCALID`.
-   If `OMP_NUM_THREADS` is unset, it uses `SLURM_CPUS_PER_TASK` (or
    `1`).

Default KOKKOS flags:

    -k on g 1 -sf kk -pk kokkos gpu/aware on neigh half newton on

Example:

``` bash
lmp_srun -in in.lmp
```

------------------------------------------------------------------------

# HPC usage (Apptainer/Singularity)

Pull a `.sif` from GHCR:

``` bash
apptainer pull lammps-macefield.sif docker://ghcr.io/mdi-group/lammps-macefield:<tag>
```

Run with NVIDIA GPU support:

``` bash
apptainer exec --nv lammps-macefield.sif lmp -h
```

Example Slurm pattern:

``` bash
srun --gpus-per-task=1 --cpus-per-task=1 -n 4   apptainer exec --nv lammps-macefield.sif lmp_srun -in in.lmp
```

------------------------------------------------------------------------

# GPU architecture note

This image is compiled for **sm80 (A100)** only (`80-real`).

It will not run on:

-   V100 (sm70)
-   H100 (sm90)

unless rebuilt.

Examples:

-   V100: `70-real`
-   H100: `90-real`
-   Multi-arch: `"80-real;90-real"`

------------------------------------------------------------------------

# Build locally

From the `containers/` repo root:

``` bash
docker build -t lammps-macefield:dev ./lammps-macefield
```

------------------------------------------------------------------------

# What's inside

-   LAMMPS: `/opt/lammps`
-   UCX: `/opt/ucx`
-   OpenMPI: `/opt/openmpi`
-   MACE-Field source: `/opt/mace-field`
-   Wrapper: `/usr/local/bin/lmp_srun`

Environment defaults:

    OMPI_MCA_pml=ucx
    OMPI_MCA_osc=ucx
    OMPI_MCA_btl=^smcuda
    OMP_NUM_THREADS=1

------------------------------------------------------------------------

# Licensing

This image bundles multiple upstream projects (LAMMPS, OpenMPI, UCX,
PyTorch, MACE-Field, etc.).

Consult each upstream project for license terms.
