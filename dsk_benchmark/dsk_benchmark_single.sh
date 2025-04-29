#!/bin/bash
#SBATCH --job-name=dsk_benchmark
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
WORKING_DIR="/scratch/kap6605/dsk_bench"      # Working directory (preprocessed data)
INPUT_FILES="../input_files"
SCRIPTS_DIR="../scripts"

# Create needed directories


# Accept parameters from the command line
FILE_NAME="$1"
KMER_SIZE="$2"
PARAMS="$3"

if [[ "${FILE_NAME}" == "chm13_part1.maf" ]]; then
            FASTA_DIR="small_fastas"
elif [[ "${FILE_NAME}" == "chm13_part1_through_10.maf" ]]; then
    FASTA_DIR="large_fastas"
else
    echo "Error: unrecognized file_name '${file_name}'" >&2
    exit 1
fi

# Print them for logging clarity
echo "Running single-file dsk job with:"
echo "  - FILE_NAME: ${FILE_NAME}"
echo "  - KMER_SIZE: ${KMER_SIZE}"
echo "  - SLURM_CPUS: ${SLURM_CPUS}"
echo "  - SLURM_MEM: ${SLURM_MEM} GB"

run_dsk() {
    local file_name="$1"   # MAF file name
    local kmer_size="$2"   # k-mer size
    local cpus="$3"        # Number of CPUs
    local mem="$4"         # Memory in GB

    echo "Starting dsk benchmark for ${file_name} with k=${kmer_size}"

    

    # Run dsk count for each FASTA file
    echo "Running k-mer counting for each FASTA file in ${INPUT_FILES}/${FASTA_DIR}"
    for fasta_file in "${INPUT_FILES}/${FASTA_DIR}"/*.fasta; do
        [ -e "$fasta_file" ] || continue
        local fasta_basename
        fasta_basename=$(basename "$fasta_file" .fasta)

        local res_output="dsk_${file_name}_${fasta_basename}_${kmer_size}mers"

        if [[ "${PARAMS}" == "DEFAULT" ]]; then
            echo "Processing file with default params: $fasta_file"
            dsk \
                -kmer-size "${kmer_size}" \
                -file "${fasta_file}" \
                -out-dir "${WORKING_DIR}" \
                -out-tmp "${WORKING_DIR}" \
                -out "${WORKING_DIR}/${res_output}"
        else
            echo "Processing file with optimized params: $fasta_file"
            dsk \
                -kmer-size "${kmer_size}" \
                -abundance-min 1 \
                -max-memory 64000 \
                -nb-cores "${cpus}" \
                -file "${fasta_file}" \
                -out-dir "${WORKING_DIR}" \
                -out-tmp "${WORKING_DIR}" \
                -out "${WORKING_DIR}/${res_output}"
        fi
        
          
    done

    echo "Completed dsk benchmark for ${file_name} with k=${kmer_size}"
}

# Run the function
run_dsk "${FILE_NAME}" "${KMER_SIZE}" "${SLURM_CPUS}" "${SLURM_MEM}"

echo "Job complete."
