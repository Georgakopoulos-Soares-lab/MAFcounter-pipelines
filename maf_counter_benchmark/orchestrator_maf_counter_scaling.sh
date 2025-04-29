#!/bin/bash
# Orchestrator script to run maf_counter_scaling_job.sh serially over multiple parameters
# It runs for two input files (small and large), for k-mer sizes 10, 20, 30 and for CPU cores 5,10,15,20,25,30.
# For each scenario, it collects resource usage from sacct.

SLURM_SCRIPT="maf_counter_scaling_job.sh"
RESULTS_DIR="./results_scaling"
WORKING_DIR="../working_dir"  # Adjust this to your actual working directory if needed
mkdir -p "${RESULTS_DIR}"

# CSV file for job mapping: filename,k,cores,job_id
JOB_INFO_FILE="${RESULTS_DIR}/job_info_scaling.csv"
echo "filename,k,cores,job_id" > "${JOB_INFO_FILE}"

# CSV file for resource usage: filename,k,cores,job_id,MaxRSS,Elapsed,MaxDiskWrite,WorkDirSizeKB
JOB_RESOURCES_FILE="${RESULTS_DIR}/job_resources_scaling.csv"
echo "filename,k,cores,job_id,MaxRSS,Elapsed,MaxDiskWrite,WorkDirSizeKB" > "${JOB_RESOURCES_FILE}"

# Define the list of MAF files and k-mer sizes and CPU core counts
FILES=("chm13_part1.maf")

K_VALUES=(10 20 30)
CORES=(5 10 15 20 25 30)

echo "Submitting scaling jobs serially..."

for FILE in "${FILES[@]}"; do
  for K in "${K_VALUES[@]}"; do
    for TOTAL_CORES in "${CORES[@]}"; do
      
      # Submit the job; capture job ID via --parsable
      JOB_ID=$(sbatch --parsable "${SLURM_SCRIPT}" "$FILE" "$K" "$TOTAL_CORES")
      echo "Submitted job ${JOB_ID} for ${FILE} with k=${K} and cores=${TOTAL_CORES}"
      
      # Record the job parameters
      echo "${FILE},${K},${TOTAL_CORES},${JOB_ID}" >> "${JOB_INFO_FILE}"
      
      # Wait for the current job to finish before proceeding - improved method
      echo "Waiting for job ${JOB_ID} to finish..."
      while squeue -j "$JOB_ID" | grep -q "$JOB_ID"; do
        sleep 5
      done
      echo "Job ${JOB_ID} has completed."
      
      # Once the job is done, collect resource usage using sacct.
      # Parse the .batch step (adjust grep filter if needed).
      echo "Collecting resource usage for job ${JOB_ID}..."
      sacct_line=$(sacct -j "${JOB_ID}" --format=JobID,MaxRSS,Elapsed,MaxDiskWrite -n -P | grep ".batch")
      
      # Parse out resource metrics from the '|' separated line.
      max_rss=$(echo "${sacct_line}" | awk -F'|' '{print $2}')
      elapsed=$(echo "${sacct_line}" | awk -F'|' '{print $3}')
      max_disk_write=$(echo "${sacct_line}" | awk -F'|' '{print $4}')
      
      # Calculate working directory size excluding FASTA files
      workdir_ex_fastas_kb=$(du -sk "${WORKING_DIR}" --exclude="*.fa" --exclude="*.fasta" | awk '{print $1}')
      
      # Record all metrics
      echo "${FILE},${K},${TOTAL_CORES},${JOB_ID},${max_rss},${elapsed},${max_disk_write},${workdir_ex_fastas_kb}" >> "${JOB_RESOURCES_FILE}"
      echo "Recorded for job ${JOB_ID}: MaxRSS=${max_rss}, Elapsed=${elapsed}, MaxDiskWrite=${max_disk_write}, WorkDirSizeKB=${workdir_ex_fastas_kb}"
      
      # Clean up working directory
      echo "Cleaning up working directory..."
      rm -rf "${WORKING_DIR:?}"/*maf_counter*
      rm -rf "${WORKING_DIR:?}"/*metadata*
      
      echo "Done with ${FILE} (k=${K}, cores=${TOTAL_CORES})."
      echo
    done
  done
done

echo "All scaling jobs have been run in series."
echo "Job mapping file: ${JOB_INFO_FILE}"
echo "Resource usage file: ${JOB_RESOURCES_FILE}"