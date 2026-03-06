# mdi-group containers

This repository is the source-of-truth for **container recipes** used by mdi-group (Docker + Apptainer/Singularity).
Images are published to **GitHub Container Registry (GHCR)** under `ghcr.io/mdi-group/...`.

## Images

| Image | GHCR | Notes |
|------:|------|------|
| lammps-mace | `ghcr.io/mdi-group/lammps-mace` | LAMMPS + KOKKOS(CUDA) + ML-IAP + MACE (A100/sm80) |
| lammps-macefield | `ghcr.io/mdi-group/lammps-macefield` | LAMMPS + KOKKOS(CUDA) + ML-IAP + MACE-Field (A100/sm80, Slurm/Young-friendly) |

Each image lives in its own folder with:
- a `Dockerfile`
- a per-image `README.md`
- optional `examples/` (Slurm scripts, test inputs, etc.)

## Pulling images

Docker:
```bash
docker pull ghcr.io/mdi-group/<image>:<tag>
```

Apptainer/Singularity (common on HPC):
```bash
apptainer pull <image>.sif docker://ghcr.io/mdi-group/<image>:<tag>
```

## Building locally (developer workflow)

From the repo root:

```bash
docker build -t <image>:dev ./<image>
```

Examples:
```bash
docker build -t lammps-mace:dev ./lammps-mace
docker build -t lammps-macefield:dev ./lammps-macefield
```

## Publishing (recommended)

Publishing is handled by GitHub Actions workflows in `.github/workflows/`.
Pushing to `main` (or tags, depending on workflow) builds and pushes to GHCR.

Why CI publish?
- The GHCR package gets **linked to this repository** automatically.
- You get consistent labels/tags and a single place for provenance.

## Conventions

- Folder name == image name (e.g. `lammps-mace/` → `ghcr.io/mdi-group/lammps-mace`)
- Prefer explicit, informative tags (CUDA + upstream versions), and keep `latest` for default-branch builds only.
- Include `org.opencontainers.image.source` label in Dockerfiles:
  - `https://github.com/mdi-group/containers`

## Support / contributions

- Open issues/PRs in this repo.
- Include reproducible build/run instructions in the image README.
