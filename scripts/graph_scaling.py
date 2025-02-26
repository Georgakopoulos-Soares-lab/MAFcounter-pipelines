#!/usr/bin/env python3
import os
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib as mpl

# Increase all font sizes by 1.35 times the default.
mpl.rcParams.update({'font.size': mpl.rcParams['font.size'] * 1.35})

def elapsed_to_seconds(elapsed_str):
    """Convert a HH:MM:SS string to total seconds."""
    try:
        h, m, s = map(int, elapsed_str.split(':'))
        return h * 3600 + m * 60 + s
    except Exception:
        return 0

def parse_maxrss(maxrss_str):
    """
    Convert memory string with suffix to MB.
    Assumes that a trailing 'K' means kilobytes and 'M' means megabytes.
    """
    try:
        if maxrss_str.endswith('K'):
            kb = int(maxrss_str[:-1])
            return kb / 1024.0
        elif maxrss_str.endswith('M'):
            return float(maxrss_str[:-1])
        else:
            # Assume the number is in KB
            return float(maxrss_str) / 1024.0
    except Exception:
        return 0.0

def load_data(csv_path):
    """Read CSV file and convert columns to proper numeric types."""
    df = pd.read_csv(csv_path)
    df['k'] = df['k'].astype(int)
    df['cores'] = df['cores'].astype(int)
    df['Elapsed_sec'] = df['Elapsed'].apply(elapsed_to_seconds)
    df['Memory_MB'] = df['MaxRSS'].apply(parse_maxrss)
    return df

def plot_scaling(df, filename, metric, ylabel, output_file):
    """
    Plot scaling data for a given metric (either 'Memory_MB' or 'Elapsed_sec')
    for a particular input file. The x-axis is the number of cores and each
    line represents a different k-mer size.
    """
    df_file = df[df['filename'] == filename]
    k_values = sorted(df_file['k'].unique())
    
    plt.figure(figsize=(10, 6))
    for k in k_values:
        df_k = df_file[df_file['k'] == k].sort_values('cores')
        plt.plot(df_k['cores'], df_k[metric], marker='o', label=f"k={k}")
    
    plt.xlabel("Cores")
    plt.ylabel(ylabel)
    plt.title(f"{filename} - {ylabel} Scaling")
    plt.xticks(sorted(df_file['cores'].unique()))
    plt.legend(loc="best")
    plt.tight_layout()
    plt.savefig(output_file)
    plt.close()
    print(f"Saved plot: {output_file}")

def main():
    # Path to the CSV file (adjust if needed)
    csv_path = "/storage/group/izg5139/default/multiple_alignment/maf_counter_migration/pipelines/maf_counter_benchmark/results_scaling/job_resources_scaling.csv"
    df = load_data(csv_path)
    
    # Get unique input filenames
    filenames = df['filename'].unique()
    
    # For each input file, generate two plots: memory and time scaling.
    for fname in filenames:
        # Memory plot
        output_mem = f"{fname.replace('.maf','')}_memory_scaling.png"
        plot_scaling(df, fname, 'Memory_MB', "Memory (MB)", output_mem)
        # Time plot
        output_time = f"{fname.replace('.maf','')}_time_scaling.png"
        plot_scaling(df, fname, 'Elapsed_sec', "Time (sec)", output_time)

if __name__ == "__main__":
    main()
