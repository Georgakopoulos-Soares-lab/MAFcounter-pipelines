#!/usr/bin/env python3
import os
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib as mpl

# (Optional) bump up all font sizes by ~1.25×
mpl.rcParams.update({'font.size': mpl.rcParams['font.size'] * 1.25})

def main():
    # path to your benchmark CSV
    csv_path = "../maf_counter_benchmark/results/query_benchmark.csv"
    df = pd.read_csv(csv_path)
    
    # ensure correct dtypes
    df['threads'] = df['threads'].astype(int)
    df['seconds'] = df['seconds'].astype(float)

    # plot
    plt.figure(figsize=(10, 6))
    plt.plot(df['threads'], df['seconds'], marker='o', linewidth=2)
    plt.xlabel("Threads")
    plt.ylabel("Time (sec)")
    plt.title("Query Benchmark: Time vs Threads")
    plt.xticks(df['threads'])
    plt.grid(True, linestyle='--', alpha=0.7)
    plt.tight_layout()

    # save
    output_file = "query_benchmark_time_scaling.png"
    plt.savefig(output_file, dpi=600)
    plt.close()
    print(f"Saved plot: {output_file}")

if __name__ == "__main__":
    main()
