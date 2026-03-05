#!/bin/bash
#SBATCH --job-name=lammps_young_mn
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=8
#SBATCH --cpus-per-task=8
#SBATCH --gres=gpu:8,tmpfs:50G
#SBATCH --mem-per-cpu=8G
#SBATCH --time=02:00:00
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err

module purge 2>/dev/null || true

IMAGE=/path/to/mace-lammps-young.sif
INPUT=/path/to/in.lammps

export APPTAINER_BINDPATH="${PWD}"
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}

# Recommended GPU binding: keep 1 task pinned to 1 GPU
# If your Slurm supports it, this keeps CUDA_VISIBLE_DEVICES sane.
SRUN_GPU_BIND="--gpu-bind=closest"

srun --mpi=pmix ${SRUN_GPU_BIND} \
  apptainer exec --cleanenv --nv "${IMAGE}" \
  lmp_srun -in "${INPUT}"
