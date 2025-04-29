#!/bin/bash
#SBATCH --job-name=kcoss_benchmark
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
WORKING_DIR="/scratch/kap6605/kcoss_bench"      # Working directory (preprocessed data)
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
echo "Running single-file kcoss job with:"
echo "  - FILE_NAME: ${FILE_NAME}"
echo "  - KMER_SIZE: ${KMER_SIZE}"
echo "  - SLURM_CPUS: ${SLURM_CPUS}"
echo "  - SLURM_MEM: ${SLURM_MEM} GB"

run_kcoss() {
    local file_name="$1"   # MAF file name
    local kmer_size="$2"   # k-mer size
    local cpus="$3"        # Number of CPUs
    local mem="$4"         # Memory in GB

    echo "Starting kcoss benchmark for ${file_name} with k=${kmer_size}"

    

    # Run kcoss count for each FASTA file
    echo "Running k-mer counting for each FASTA file in ${INPUT_FILES}/${FASTA_DIR}"
    for fasta_file in "${INPUT_FILES}/${FASTA_DIR}"/*.fasta; do
        [ -e "$fasta_file" ] || continue
        local fasta_basename
        fasta_basename=$(basename "$fasta_file" .fasta)

        local res_output="${WORKING_DIR}/kcoss_${file_name}_${fasta_basename}_${kmer_size}mers.out"

        if [[ "${PARAMS}" == "DEFAULT" ]]; then
            echo "Processing file with default params: $fasta_file"
             kcoss \
                -k "${kmer_size}" \
                -i "${fasta_file}" \
                -t "${cpus}" \
                -m 360 \
                -o "${res_output}" \
                -n 3000000000 \
                -d 268697600
        else
            echo "Processing file with optimized params: $fasta_file"
            kcoss \
                -k "${kmer_size}" \
                -i "${fasta_file}" \
                -t "${cpus}" \
                -m 720 \
                -o "${res_output}" \
                -n 6000000000 \
                -d 268697600
        fi
        
          
    done

    echo "Completed kcoss benchmark for ${file_name} with k=${kmer_size}"
}

# Run the function
run_kcoss "${FILE_NAME}" "${KMER_SIZE}" "${SLURM_CPUS}" "${SLURM_MEM}"

echo "Job complete."
