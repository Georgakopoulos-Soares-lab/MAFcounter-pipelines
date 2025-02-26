#!/bin/bash
#SBATCH --job-name=maf_counter_scaling
#SBATCH --time=24:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=30
#SBATCH --output=./logs/%x_%j.log
#SBATCH --error=./logs/%x_%j.err
#SBATCH --partition=sla-prio
#SBATCH --account=izg5139_hc

# Set directories (adjust as needed)
WORKING_DIR="../working_dir"      # For intermediate and output files
INPUT_FILES="../input_files"       # Directory containing input MAF files
export PATH="../binaries:$PATH"

# Accept parameters:
#   $1: input MAF file name (located in INPUT_FILES)
#   $2: k-mer size
#   $3: total number of CPU cores (to be passed as --threads)
FILE_NAME="$1"
KMER_SIZE="$2"
TOTAL_CORES="$3"

echo "Running maf_counter_count scaling job with:"
echo "  - FILE_NAME: ${FILE_NAME}"
echo "  - KMER_SIZE: ${KMER_SIZE}"
echo "  - TOTAL_CORES: ${TOTAL_CORES}"

run_maf_counter() {
    local file_name="$1"
    local kmer_size="$2"
    local total_cores="$3"

    echo "Starting maf_counter_count for ${file_name} with k=${kmer_size} using ${total_cores} cores"
    
    # Construct output file name (e.g., maf_counter_chm13_part1.maf_10mers_10cores.out)
    local base_name
    base_name=$(basename "$file_name")
    local output_file="${WORKING_DIR}/maf_counter_${base_name}_${kmer_size}mers_${total_cores}cores.out"
    
    start_time=$(date +%s)
    
    maf_counter_count --binary_file_output "${output_file}" \
                       --k "${kmer_size}" \
                       --threads "${total_cores}" \
                       --temp_files_dir "${WORKING_DIR}" \
                       --output_directory "${WORKING_DIR}" \
                       "${INPUT_FILES}/${file_name}"
    
    end_time=$(date +%s)
    elapsed_time=$(( end_time - start_time ))
    
    echo "maf_counter_count for ${file_name} with ${total_cores} cores took ${elapsed_time} seconds."
    echo "Output written to ${output_file}"
}

# Run the job
run_maf_counter "${FILE_NAME}" "${KMER_SIZE}" "${TOTAL_CORES}"
echo "Job complete."
