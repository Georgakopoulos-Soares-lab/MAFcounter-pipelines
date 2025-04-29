#!/bin/bash

# Orchestrator script to run multiple Slurm jobs (jellyfish_benchmark_single.sh)
# with different parameters in a *serial* fashion. It waits for each job to
# complete before submitting the next one. Then it collects resource usage
# from sacct for each completed job, including State, MaxDiskWrite and WorkDirSizeKB.
# Before each submission, it clears WORKING_DIR.

SLURM_SCRIPT="jellyfish_benchmark_single.sh"
RESULTS_DIR="./results"
WORKING_DIR="/scratch/kap6605/jellyfish_bench"

mkdir -p "${RESULTS_DIR}"

# List of MAF files and K-mer sizes
# FILES=("chm13_part1.maf")
FILES=("chm13_part1.maf" "chm13_part1_through_10.maf")
K_VALUES=(10 20 30 55)

PARAMS="DEFAULT"  # or e.g. "default"

# choose suffix based on PARAMS
if [[ "${PARAMS}" == "DEFAULT" ]]; then
  suffix="_default"
else
  suffix="_finetuned"
fi

# CSV to store the mapping (filename, k, job_id)
JOB_INFO_FILE="${RESULTS_DIR}/job_info${suffix}.csv"
echo "filename,k,job_id" > "${JOB_INFO_FILE}"

# CSV to store resource usage (filename, k, job_id, State, MaxRSS, Elapsed, MaxDiskWrite, WorkDirSizeKB)
JOB_RESOURCES_FILE="${RESULTS_DIR}/job_resources${suffix}.csv"
echo "filename,k,job_id,State,MaxRSS,Elapsed,MaxDiskWrite,WorkDirSizeKB" > "${JOB_RESOURCES_FILE}"

echo "Submitting jobs serially (one by one) with PARAMS='${PARAMS}'..."
echo "  → job_info file:     ${JOB_INFO_FILE}"
echo "  → job_resources file: ${JOB_RESOURCES_FILE}"
echo

for FILE in "${FILES[@]}"; do
  for K in "${K_VALUES[@]}"; do

    # Clear working directory
    rm -rf "${WORKING_DIR}/"*

    # 1. Submit the job (capture job ID via --parsable)
    JOB_ID="$(sbatch --parsable "${SLURM_SCRIPT}" "$FILE" "$K" "$PARAMS")"
    echo "Submitted job ${JOB_ID} for ${FILE} with k=${K}"

    # 2. Record the parameters -> job_info.csv
    echo "${FILE},${K},${JOB_ID}" >> "${JOB_INFO_FILE}"

    # 3. Wait for the current job to finish before proceeding
    echo "Waiting for job ${JOB_ID} to finish..."
    while squeue -j "$JOB_ID" | grep -q "$JOB_ID"; do
      sleep 10
    done
    echo "Job ${JOB_ID} has completed."

    # 4. Once the job is done, collect resource usage using sacct
    echo "Collecting resource usage for job ${JOB_ID}..."
    sacct_line=$(sacct -j "${JOB_ID}" --format=JobID,State,MaxRSS,Elapsed,MaxDiskWrite -n -P | grep "\.batch")

    # Parse out State, MaxRSS, Elapsed and MaxDiskWrite from the '|' separated line
    state=$(echo "${sacct_line}" | awk -F'|' '{print $2}')
    max_rss=$(echo "${sacct_line}" | awk -F'|' '{print $3}')
    elapsed=$(echo "${sacct_line}" | awk -F'|' '{print $4}')
    max_disk_write=$(echo "${sacct_line}" | awk -F'|' '{print $5}')

    # 5. Compute working-dir size (KB)
    workdir_size_kb=$(du -sk "${WORKING_DIR}" | awk '{print $1}')

    # Record usage in job_resources.csv
    echo "${FILE},${K},${JOB_ID},${state},${max_rss},${elapsed},${max_disk_write},${workdir_size_kb}" \
      >> "${JOB_RESOURCES_FILE}"
    echo "  => State=${state}, MaxRSS=${max_rss}, Elapsed=${elapsed}, MaxDiskWrite=${max_disk_write}, WorkDirSizeKB=${workdir_size_kb}"

    echo "Done with ${FILE} (k=${K})."
    echo
  done
done

echo "All requested jobs have been run in series. Resource usage data in:"
echo "  - ${JOB_INFO_FILE}"
echo "  - ${JOB_RESOURCES_FILE}"
