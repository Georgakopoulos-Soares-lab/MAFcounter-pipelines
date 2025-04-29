#!/usr/bin/env python3
import os
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib as mpl

# Increase all font sizes by 1.35 times the default.
mpl.rcParams.update({'font.size': mpl.rcParams['font.size'] * 1.35})

def elapsed_to_seconds(elapsed_str):
    # Convert "HH:MM:SS" into seconds.
    h, m, s = map(int, elapsed_str.split(':'))
    return h * 3600 + m * 60 + s

def parse_maxrss(maxrss_str):
    # Remove trailing K or M and convert to KB.
    if maxrss_str.endswith('K'):
        return int(maxrss_str[:-1])
    elif maxrss_str.endswith('M'):
        return int(float(maxrss_str[:-1]) * 1024)
    else:
        return int(maxrss_str)

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
                print(f"No data for {target_file} in {csv_path}")
        else:
            print(f"CSV file not found: {csv_path}")
    return data

def plot_time(data, title, output_file):
    plt.figure(figsize=(10, 6))
    markers = ['o', 's', 'D', '^', 'v', 'P']
    linestyles = ['-', '--', '-.', ':', '-', '--']
    colors = plt.cm.tab10.colors

    for i, (tool, df) in enumerate(data.items()):
        ks = df['k'].values
        times = df['Elapsed_sec'].values
        plt.plot(ks, times, label=tool, marker=markers[i % len(markers)],
                 linestyle=linestyles[i % len(linestyles)], color=colors[i % len(colors)])
    
    plt.xlabel("k-mer size")
    plt.ylabel("Elapsed Time (sec)")
    plt.title(title)
    plt.xticks([10, 20, 30])
    plt.legend(loc="upper left")
    plt.tight_layout()
    plt.savefig(output_file)
    plt.close()
    print(f"Saved time plot: {output_file}")

def plot_memory(data, title, output_file):
    plt.figure(figsize=(10, 6))
    markers = ['o', 's', 'D', '^', 'v', 'P']
    linestyles = ['-', '--', '-.', ':', '-', '--']
    colors = plt.cm.tab10.colors

    for i, (tool, df) in enumerate(data.items()):
        ks = df['k'].values
        # Convert memory from KB to MB.
        mem = df['MaxRSS_KB'].values / 1024.0
        plt.plot(ks, mem, label=tool, marker=markers[i % len(markers)],
                 linestyle=linestyles[i % len(linestyles)], color=colors[i % len(colors)])
    
    plt.xlabel("k-mer size")
    plt.ylabel("Max RSS (MB)")
    plt.title(title)
    plt.xticks([10, 20, 30])
    plt.legend(loc="upper left")
    plt.tight_layout()
    plt.savefig(output_file)
    plt.close()
    print(f"Saved memory plot: {output_file}")

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
    
    # Plot separate graphs for execution time.
    plot_time(data_small, "Small File Benchmark - Execution Time (chm13_part1.maf)", "small_file_time.png")
    plot_time(data_large, "Large File Benchmark - Execution Time (chm13_part1_through_10.maf)", "large_file_time.png")
    
    # Plot separate graphs for memory usage.
    plot_memory(data_small, "Small File Benchmark - Memory Usage (chm13_part1.maf)", "small_file_memory.png")
    plot_memory(data_large, "Large File Benchmark - Memory Usage (chm13_part1_through_10.maf)", "large_file_memory.png")

if __name__ == "__main__":
    main()
