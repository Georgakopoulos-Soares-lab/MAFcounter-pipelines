#!/bin/bash
#SBATCH --job-name=meryl_benchmark
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
SLURM_MEM=64
WORKING_DIR="../working_dir"      # Working directory (preprocessed data)
INPUT_FILES="../input_files"
SCRIPTS_DIR="../scripts"

# Create needed directories
mkdir -p "${WORKING_DIR}/fastas"

# Accept parameters from the command line
FILE_NAME="$1"
KMER_SIZE="$2"

# Print them for logging clarity
echo "Running single-file meryl job with:"
echo "  - FILE_NAME: ${FILE_NAME}"
echo "  - KMER_SIZE: ${KMER_SIZE}"
echo "  - SLURM_CPUS: ${SLURM_CPUS}"
echo "  - SLURM_MEM: ${SLURM_MEM} GB"

run_meryl() {
    local file_name="$1"   # MAF file name
    local kmer_size="$2"   # k-mer size
    local cpus="$3"        # Number of CPUs
    local mem="$4"         # Memory in GB

    echo "Starting meryl benchmark for ${file_name} with k=${kmer_size}"
    
    # Convert MAF to FASTA
    echo "Running MAF to FASTA script..."
    python3 "${SCRIPTS_DIR}/maf_to_fasta.py" \
        "${INPUT_FILES}/${file_name}" \
        "${WORKING_DIR}/fastas"

    # Run meryl count-forward for each FASTA file
    echo "Running k-mer counting for each FASTA file in ${WORKING_DIR}/fastas"
    for fasta_file in "${WORKING_DIR}/fastas"/*.fasta; do
        [ -e "$fasta_file" ] || continue
        local fasta_basename
        fasta_basename=$(basename "$fasta_file" .fasta)
        
        local res_output="${WORKING_DIR}/meryl_${file_name}_${fasta_basename}_${kmer_size}mers.meryl_output"
        
        echo "Processing file: $fasta_file"
        meryl count-forward \
            k="${kmer_size}" \
            "$fasta_file" \
            output "${res_output}" \
            memory=${mem} \
            threads=${cpus}

        # Optionally, if meryl creates temporary files, clean them up here.
        # For example:
        # echo "Cleaning temporary files..."
        # rm ${WORKING_DIR}/meryl_temp*
    done

    echo "Completed meryl benchmark for ${file_name} with k=${kmer_size}"
}

# Run the function
run_meryl "${FILE_NAME}" "${KMER_SIZE}" "${SLURM_CPUS}" "${SLURM_MEM}"

echo "Job complete."
