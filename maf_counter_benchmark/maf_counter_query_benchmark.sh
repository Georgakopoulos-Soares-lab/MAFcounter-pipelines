#!/bin/bash
#SBATCH --job-name=query_benchmark
#SBATCH --time=24:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=16
#SBATCH --output=./logs/%x_%j.log
#SBATCH --error=./logs/%x_%j.err
#SBATCH --partition=himem
#SBATCH --account=izg5139_cr_default


# make sure your binaries are on PATH
export PATH="../binaries:$PATH"

# inputs
INPUT_DATABASE="/scratch/kap6605/maf_counter/maf_counter_chm13_part1_through_10.maf_55mers.out"
METADATA_FILE="/scratch/kap6605/maf_counter/final.metadata"
KMER_FILE="../input_files/input_kmers.txt"

# results dir & CSV
RESULTS_DIR="./results"
mkdir -p "$RESULTS_DIR"
CSV_FILE="$RESULTS_DIR/query_benchmark.csv"

# header
echo "threads,seconds" > "$CSV_FILE"

# list of thread‐counts to try
THREAD_LIST=(1 2 4 6 8 10 12 14 16)

# loop, time each, append to CSV
for T in "${THREAD_LIST[@]}"; do
  echo "=== Running with $T threads ==="
  START=$(date +%s.%N)
  maf_counter_tools \
    --query "@${KMER_FILE}" \
    --threads "$T" \
    --binary_database "${INPUT_DATABASE}" \
    --metadata_file "${METADATA_FILE}"
  END=$(date +%s.%N)
  ELAPSED=$(echo "$END - $START" | bc -l)
  printf "%d,%.3f\n" "$T" "$ELAPSED" >> "$CSV_FILE"
done

echo "Benchmark complete – results in $CSV_FILE"
