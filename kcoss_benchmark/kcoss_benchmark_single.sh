#!/bin/bash
#SBATCH --job-name=kcoss_benchmark
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

# Print parameters for logging clarity
echo "Running single-file kcoss job with:"
echo "  - FILE_NAME: ${FILE_NAME}"
echo "  - KMER_SIZE: ${KMER_SIZE}"
echo "  - SLURM_CPUS: ${SLURM_CPUS}"
echo "  - SLURM_MEM: ${SLURM_MEM} GB"

run_kcoss() {
    local file_name="$1"   # MAF file name
    local kmer_size="$2"   # k-mer size
    local cpus="$3"        # Number of CPUs
    local mem="$4"         # Memory in GB (unused by kcoss parameters here)
    
    echo "Starting kcoss benchmark for ${file_name} with k=${kmer_size}"
    
    # Convert MAF to FASTA
    echo "Running MAF to FASTA conversion..."
    python3 "${SCRIPTS_DIR}/maf_to_fasta.py" \
            "${INPUT_FILES}/${file_name}" \
            "${WORKING_DIR}/fastas"
    
    # Run kcoss count for each FASTA file
    echo "Running k-mer counting for each FASTA file in ${WORKING_DIR}/fastas"
    for fasta_file in "${WORKING_DIR}/fastas"/*.fasta; do
        [ -e "$fasta_file" ] || continue
        local fasta_basename
        fasta_basename=$(basename "$fasta_file" .fasta)
        
        local kcoss_output="${WORKING_DIR}/kcoss_${file_name}_${fasta_basename}_${kmer_size}mers.out"
        
        echo "Processing file: $fasta_file"
        
        # Record start time in seconds
        start_time=$(date +%s)
        
        # Run kcoss with specified parameters:
        # -k: k-mer length (from parameter)
        # -i: input file (FASTA)
        # -t: number of threads (from SLURM_CPUS)
        # -m: block size (here fixed to 360)
        # -o: output file path (with kcoss_ prefix)
        # -n: size of bloomfilter (set to 3000000000)
        # -d: size of hash table (set to 268697600)
        kcoss \
            -k "${kmer_size}" \
            -i "${fasta_file}" \
            -t "${cpus}" \
            -m 360 \
            -o "${kcoss_output}" \
            -n 3000000000 \
            -d 268697600
        
        # Record end time in seconds
        end_time=$(date +%s)
        
        # Calculate elapsed time
        elapsed_time=$(( end_time - start_time ))
        
        echo "kcoss count for ${fasta_file} took ${elapsed_time} seconds."
    done
    
    echo "Completed kcoss benchmark for ${file_name} with k=${kmer_size}"
}

# Run the function
run_kcoss "${FILE_NAME}" "${KMER_SIZE}" "${SLURM_CPUS}" "${SLURM_MEM}"

echo "Job complete."
