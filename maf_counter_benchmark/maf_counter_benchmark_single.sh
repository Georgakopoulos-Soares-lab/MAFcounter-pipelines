#!/bin/bash
#SBATCH --job-name=maf_counter_benchmark
#SBATCH --time=24:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=24
#SBATCH --output=./logs/%x_%j.log
#SBATCH --error=./logs/%x_%j.err
#SBATCH --partition=sla-prio
#SBATCH --account=izg5139_hc

# Add the relative binaries directory to PATH
export PATH="../binaries:$PATH"

# Set variables
SLURM_CPUS=24
WORKING_DIR="../working_dir"      # Working directory (for intermediate and output files)
INPUT_FILES="../input_files"       # Directory containing input MAF files

# Accept parameters from the command line:
#  $1: input MAF file name (located in INPUT_FILES)
#  $2: k-mer size
FILE_NAME="$1"
KMER_SIZE="$2"

# Print parameters for logging
echo "Running single-file maf_counter_count8 job with:"
echo "  - FILE_NAME: ${FILE_NAME}"
echo "  - KMER_SIZE: ${KMER_SIZE}"
echo "  - Using 16 reader threads and 8 package manager threads"

run_maf_counter() {
    local file_name="$1"   # Input MAF file name
    local kmer_size="$2"   # k-mer size

    echo "Starting maf_counter_count8 benchmark for ${file_name} with k=${kmer_size}"
    
    # Construct the output file name using the base name of the input file and k-mer info.
    local base_name
    base_name=$(basename "$file_name")
    local mc_output="${WORKING_DIR}/maf_counter_${base_name}_${kmer_size}mers.out"
    
    echo "Processing MAF file: ${file_name}"
    
    # Record start time in seconds
    start_time=$(date +%s)
    
    # Run maf_counter_count with the specified parameters:
    #  --binary_file_output: sets the output file name.
    #  --k: required k-mer length.
    #  --reader_threads and --package_manager_threads: specify thread numbers.
    #  --temp_files_dir: directory for intermediate files.
    #  --output_directory: directory for final output files.
    maf_counter_count --binary_file_output "${mc_output}" \
                       --k "${kmer_size}" \
                       --reader_threads 16 \
                       --package_manager_threads 8 \
                       --temp_files_dir "${WORKING_DIR}" \
                       --output_directory "${WORKING_DIR}" \
                       "${INPUT_FILES}/${file_name}"
    
    # Record end time in seconds
    end_time=$(date +%s)
    
    # Calculate elapsed time in seconds
    elapsed_time=$(( end_time - start_time ))
    
    echo "maf_counter_count8 for ${file_name} took ${elapsed_time} seconds."
    echo "Output written to ${mc_output}"
}

# Run the function with the given input file and k-mer size.
run_maf_counter "${FILE_NAME}" "${KMER_SIZE}"

echo "Job complete."
