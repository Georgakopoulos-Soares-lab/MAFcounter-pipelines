#!/bin/bash

# Orchestrator script to run multiple Slurm jobs (maf_counter_benchmark_single.sh)
# serially. For each job it:
#  - submits the job and waits for it to finish
#  - collects MaxRSS, Elapsed, MaxDiskWrite
#  - computes WorkDirSizeKB 
#  - logs everything to CSVs

SLURM_SCRIPT="maf_counter_benchmark_single.sh"
RESULTS_DIR="./results"
WORKING_DIR="/scratch/kap6605/maf_counter"


mkdir -p "${RESULTS_DIR}"

# CSV to store the mapping (filename, k, job_id)
JOB_INFO_FILE="${RESULTS_DIR}/job_info.csv"
echo "filename,k,job_id" > "${JOB_INFO_FILE}"

# CSV to store resource usage 
# (filename, k, job_id, MaxRSS, Elapsed, MaxDiskWrite, WorkDirSizeKB)
JOB_RESOURCES_FILE="${RESULTS_DIR}/job_resources.csv"
echo "filename,k,job_id,MaxRSS,Elapsed,MaxDiskWrite,WorkDirSizeKB" > "${JOB_RESOURCES_FILE}"

# List of MAF files and K-mer sizes
FILES=("chm13_part1.maf" "chm13_part1_through_10.maf")
# FILES=("chm13_part1_through_10.maf")
# K_VALUES=(55)

K_VALUES=(10 20 30 55)

echo "Submitting jobs serially (one by one)..."

for FILE in "${FILES[@]}"; do
  for K in "${K_VALUES[@]}"; do


    rm -rf "${WORKING_DIR}"/*
    

    # 2. Submit the job (capture job ID via --parsable)
    JOB_ID="$(sbatch --parsable "${SLURM_SCRIPT}" "$FILE" "$K")"
    echo "Submitted job ${JOB_ID} for ${FILE} with k=${K}"

    # 3. Record the parameters
    echo "${FILE},${K},${JOB_ID}" >> "${JOB_INFO_FILE}"

    # 4. Wait for the current job to finish before proceeding
    echo "Waiting for job ${JOB_ID} to finish..."
    while squeue -j "$JOB_ID" | grep -q "$JOB_ID"; do
      sleep 5
    done
    echo "Job ${JOB_ID} has completed."

    # 5. Collect resource usage from sacct
    echo "Collecting resource usage for job ${JOB_ID}..."
    sacct_line=$(sacct -j "${JOB_ID}" \
      --format=JobID,MaxRSS,Elapsed,MaxDiskWrite -n -P \
      | grep "\.batch")

    max_rss=$(echo "${sacct_line}" | awk -F'|' '{print $2}')
    elapsed=$(echo "${sacct_line}" | awk -F'|' '{print $3}')
    max_disk_write=$(echo "${sacct_line}" | awk -F'|' '{print $4}')

    
    working_size_kb=$(du -sk "${WORKING_DIR}" | awk '{print $1}')


    # 7. Record usage in job_resources.csv
    echo "${FILE},${K},${JOB_ID},${max_rss},${elapsed},${max_disk_write},${working_size_kb}" \
      >> "${JOB_RESOURCES_FILE}"

    echo "  => MaxRSS=${max_rss}, Elapsed=${elapsed}, MaxDiskWrite=${max_disk_write}, WorkDirSizeKB=${working_size_kb}"
    echo "Done with ${FILE} (k=${K})."
    echo
  done
done

echo "All requested jobs have been run in series."
echo "  - Job mapping: ${JOB_INFO_FILE}"
echo "  - Resource usage: ${JOB_RESOURCES_FILE}"
