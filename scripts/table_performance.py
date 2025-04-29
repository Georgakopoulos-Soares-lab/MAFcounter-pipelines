#!/usr/bin/env python3
import os
import pandas as pd

def elapsed_to_seconds(elapsed_str):
    # Convert "HH:MM:SS" into seconds.
    try:
        h, m, s = map(int, elapsed_str.split(':'))
        return h * 3600 + m * 60 + s
    except Exception:
        return 0

def parse_maxrss(maxrss_str):
    # Remove trailing K or M and convert to KB.
    try:
        if maxrss_str.endswith('K'):
            return int(maxrss_str[:-1])
        elif maxrss_str.endswith('M'):
            return int(float(maxrss_str[:-1]) * 1024)
        else:
            return int(maxrss_str)
    except Exception:
        return 0

def load_data(csv_path, target_file):
    df = pd.read_csv(csv_path)
    # Filter rows for the given MAF file.
    df = df[df['filename'] == target_file].copy()
    df['k'] = df['k'].astype(int)
    df['Elapsed_sec'] = df['Elapsed'].apply(elapsed_to_seconds)
    df['MaxRSS_KB'] = df['MaxRSS'].apply(parse_maxrss)
    return df.sort_values('k')

def collect_tool_data(base_dir, tools, target_file):
    data = {}
    for tool, rel_path in tools.items():
        csv_path = os.path.join(base_dir, rel_path)
        if os.path.exists(csv_path):
            df = load_data(csv_path, target_file)
            if not df.empty:
                data[tool] = df
            else:
                print(f"No data for {target_file} in {csv_path}. Filling with zeros.")
        else:
            print(f"CSV file not found: {csv_path}.")
    return data

def create_summary_table(data):
    # For each tool, create a dictionary with keys as (k, metric).
    summary = {}
    for tool, df in data.items():
        row = {}
        for k in [10, 20, 30]:
            sub = df[df['k'] == k]
            if not sub.empty:
                # Assume one row per k.
                time_val = sub['Elapsed_sec'].iloc[0]
                mem_val = sub['MaxRSS_KB'].iloc[0] / 1024.0  # convert KB to MB
            else:
                time_val = 0
                mem_val = 0
            row[(k, 'Memory (MB)')] = mem_val
            row[(k, 'Time (sec)')] = time_val
        summary[tool] = row
    # Create a DataFrame with a MultiIndex for columns
    columns = pd.MultiIndex.from_product([[10, 20, 30], ['Memory (MB)', 'Time (sec)']])
    df_summary = pd.DataFrame.from_dict(summary, orient='index', columns=columns)
    # Fill any remaining missing values with 0.
    df_summary = df_summary.fillna(0)
    return df_summary

def main():
    # Assume this script is inside pipelines/scripts; base directory is one level up.
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    
    # Define tool CSV relative paths.
    tools = {
        'jellyfish': 'jellyfish_benchmark/results/job_resources.csv',
        'kmc': 'kmc_benchmark/results/job_resources.csv',
        'gerbil': 'gerbil_benchmark/results/job_resources.csv',
        'meryl': 'meryl_benchmark/results/job_resources.csv',
        'kcoss': 'kcoss_benchmark/results/job_resources.csv',
        'maf_counter': 'maf_counter_benchmark/results/job_resources.csv'
    }
    
    # Define target files.
    small_file = "chm13_part1.maf"
    large_file = "chm13_part1_through_10.maf"
    
    # Collect data per tool for each target file.
    data_small = collect_tool_data(base_dir, tools, small_file)
    data_large = collect_tool_data(base_dir, tools, large_file)
    
    # Create summary tables.
    table_small = create_summary_table(data_small)
    table_large = create_summary_table(data_large)
    
    # Print the tables.
    print("Summary Table for Small File (chm13_part1.maf):")
    print(table_small.to_string())
    print("\nSummary Table for Large File (chm13_part1_through_10.maf):")
    print(table_large.to_string())

if __name__ == "__main__":
    main()
