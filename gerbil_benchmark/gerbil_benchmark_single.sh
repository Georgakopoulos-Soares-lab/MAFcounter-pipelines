#!/bin/bash
#SBATCH --job-name=gerbil_benchmark
#SBATCH --time=24:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=24
#SBATCH --output=./logs/%x_%j.log
#SBATCH --error=./logs/%x_%j.err
#SBATCH --partition=himem
#SBATCH --account=izg5139_cr_default

# Add the relative binaries directory to PATH
export PATH="../binaries:$PATH"

# Set variables
SLURM_CPUS=24
SLURM_MEM=64
WORKING_DIR="/scratch/kap6605/gerbil_bench"      # Working directory (preprocessed data)
INPUT_FILES="../input_files"
SCRIPTS_DIR="../scripts"

# Accept parameters from the command line
FILE_NAME="$1"
KMER_SIZE="$2"
PARAMS="$3"

# Determine which FASTA directory to use based on the input MAF
if [[ "${FILE_NAME}" == "chm13_part1.maf" ]]; then
    FASTA_DIR="small_fastas"
elif [[ "${FILE_NAME}" == "chm13_part1_through_10.maf" ]]; then
    FASTA_DIR="large_fastas"
else
    echo "Error: unrecognized file_name '${FILE_NAME}'" >&2
    exit 1
fi

# Print parameters for logging clarity
echo "Running single-file gerbil job with:"
echo "  - FILE_NAME: ${FILE_NAME}"
echo "  - KMER_SIZE: ${KMER_SIZE}"
echo "  - PARAMS: ${PARAMS}"
echo "  - SLURM_CPUS: ${SLURM_CPUS}"
echo "  - SLURM_MEM: ${SLURM_MEM} GB"

run_gerbil() {
    local file_name="$1"    # MAF file name
    local kmer_size="$2"    # k-mer size
    local cpus="$3"         # Number of CPUs
    local mem="$4"          # Memory in GB

    echo "Starting gerbil benchmark for ${file_name} with k=${kmer_size}"


    # Run Gerbil for each FASTA file
    echo "Running k-mer counting in ${WORKING_DIR}/${FASTA_DIR}"
    for fasta_file in "${INPUT_FILES}/${FASTA_DIR}"/*.fasta; do
        [ -e "$fasta_file" ] || continue
        fasta_basename=$(basename "$fasta_file" .fasta)
        res_output="${WORKING_DIR}/gerbil_${file_name}_${fasta_basename}_${kmer_size}mers"

        if [[ "${PARAMS}" == "DEFAULT" ]]; then
            echo "Processing (default params): $fasta_file"
            gerbil \
                -k "${kmer_size}" \
                -l 1 \
                "$fasta_file" \
                "${WORKING_DIR}" \
                "${res_output}"
        else
            echo "Processing (optimized params): $fasta_file"
            gerbil \
                -k "${kmer_size}" \
                -l 1 \
                -e "${mem}GB" \
                -t "${cpus}" \
                "$fasta_file" \
                "${WORKING_DIR}" \
                "${res_output}"
        fi
    done

    echo "Completed gerbil benchmark for ${file_name} with k=${kmer_size}"
}

# Run the function
run_gerbil "${FILE_NAME}" "${KMER_SIZE}" "${SLURM_CPUS}" "${SLURM_MEM}"

echo "Job complete."
