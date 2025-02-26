#!/bin/bash

# Orchestrator script to run multiple Slurm jobs (maf_counter_benchmark_single.sh)
# with different parameters in a *serial* fashion. It waits for each job to
# complete before submitting the next one. Then it collects resource usage
# from sacct for each completed job.

SLURM_SCRIPT="maf_counter_benchmark_single.sh"
RESULTS_DIR="./results"
mkdir -p "${RESULTS_DIR}"

# CSV to store the mapping (filename, k, job_id)
JOB_INFO_FILE="${RESULTS_DIR}/scaling_job_info.csv"
echo "filename,k,job_id" > "${JOB_INFO_FILE}"

# CSV to store resource usage (filename, k, job_id, MaxRSS, Elapsed)
JOB_RESOURCES_FILE="${RESULTS_DIR}/scaling_job_resources.csv"
echo "filename,k,job_id,MaxRSS,Elapsed" > "${JOB_RESOURCES_FILE}"

# List of MAF files and K-mer sizes
FILES=("chm13_part1.maf" "chm13_part1_through_10.maf")

K_VALUES=(10 20 30)

echo "Submitting jobs serially (one by one)..."

for FILE in "${FILES[@]}"; do
  for K in "${K_VALUES[@]}"; do
    
    # 1. Submit the job (capture job ID via --parsable)
    JOB_ID="$(sbatch --parsable "${SLURM_SCRIPT}" "$FILE" "$K")"
    echo "Submitted job ${JOB_ID} for ${FILE} with k=${K}"
    
    # 2. Record the parameters -> job_info.csv
    echo "${FILE},${K},${JOB_ID}" >> "${JOB_INFO_FILE}"

    # 3. Wait for the current job to finish before proceeding
    echo "Waiting for job ${JOB_ID} to finish..."
    while true; do
      # If job is found in squeue, it's still running or pending
      squeue -j "$JOB_ID" | grep $JOB_ID &> /dev/null
      if [ $? -ne 0 ]; then
        # Not found => job finished
        echo "Job ${JOB_ID} has completed."
        break
      fi
      8
    done

    # 4. Once the job is done, collect resource usage using sacct
    #    - We'll parse out the .batch step. Adjust as needed for your site.
    echo "Collecting resource usage for job ${JOB_ID}..."
    sacct_line=$(sacct -j "${JOB_ID}" --format=JobID,MaxRSS,Elapsed -n -P | grep ".batch")

    # Parse out MaxRSS and Elapsed from the '|' separated line
    max_rss=$(echo "${sacct_line}" | awk -F'|' '{print $2}')
    elapsed=$(echo "${sacct_line}" | awk -F'|' '{print $3}')

    # Record usage in job_resources.csv
    echo "${FILE},${K},${JOB_ID},${max_rss},${elapsed}" >> "${JOB_RESOURCES_FILE}"
    echo "  => MaxRSS=${max_rss}, Elapsed=${elapsed}"

    echo "Done with ${FILE} (k=${K})."
    echo
  done
done

echo "All requested jobs have been run in series. Resource usage data in:"
echo "  - ${JOB_INFO_FILE}"
echo "  - ${JOB_RESOURCES_FILE}"
