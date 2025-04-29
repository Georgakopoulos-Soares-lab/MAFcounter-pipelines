#!/usr/bin/env python3
import os
import argparse
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib as mpl

# Increase all font sizes by 1.35× the default
mpl.rcParams.update({'font.size': mpl.rcParams['font.size'] * 1.35})

def elapsed_to_seconds(elapsed_str):
    """Convert "HH:MM:SS" into seconds."""
    h, m, s = map(int, elapsed_str.split(':'))
    return h * 3600 + m * 60 + s

def parse_maxrss(maxrss_str):
    """(Not used here, but could be useful for memory plots.)"""
    if maxrss_str.endswith('K'):
        return int(maxrss_str[:-1])
    elif maxrss_str.endswith('M'):
        return int(float(maxrss_str[:-1]) * 1024)
    else:
        return int(maxrss_str)

def load_tool_data(csv_path):
    """Load default+finetuned data, split program/tuning, compute elapsed_sec."""
    df = pd.read_csv(csv_path)
    df['Elapsed_sec'] = df['Elapsed'].apply(elapsed_to_seconds)
    # split off the tuning suffix
    df[['program','tuning']] = df['program'].str.rsplit(pat='_', n=1, expand=True)
    df['k'] = df['k'].astype(int)
    return df

def load_maf_data(csv_path):
    """Load MAF Counter data and compute elapsed_sec."""
    df = pd.read_csv(csv_path)
    df['Elapsed_sec'] = df['Elapsed'].apply(elapsed_to_seconds)
    df['k'] = df['k'].astype(int)
    return df

def plot_min_time(df_tools, df_maf, target_file, output_file, title):
    """
    For each tool in df_tools, pick the minimum elapsed among tunings per k,
    merge in the maf_counter, then plot k vs time.
    """
    # filter to this file
    tdf = df_tools[df_tools['filename'] == target_file]
    # group default+finetuned, take min elapsed per program,k
    best = (
        tdf
        .groupby(['program','k'], as_index=False)['Elapsed_sec']
        .min()
    )
    # pivot so each program is a column
    pivot = best.pivot(index='k', columns='program', values='Elapsed_sec')

    # load & filter maf counter
    mdf = df_maf[df_maf['filename'] == target_file][['k','Elapsed_sec']]
    mdf = mdf.set_index('k').rename(columns={'Elapsed_sec':'maf_counter'})
    # join maf_counter as its own "tool"
    pivot = pivot.join(mdf, how='left')

    # ensure our x-axis has the full list, even if some missing
    ks = [10, 20, 30, 55]
    pivot = pivot.reindex(ks)

    # plotting
    plt.figure(figsize=(10, 6))
    markers    = ['o', 's', 'D', '^', 'v', 'P']
    linestyles = ['-', '--', '-.', ':', '-', '--']
    colors     = plt.cm.tab10.colors

    for i, tool in enumerate(pivot.columns):
        plt.plot(
            pivot.index,
            pivot[tool],
            label=tool,
            marker=markers[i % len(markers)],
            linestyle=linestyles[i % len(linestyles)],
            color=colors[i % len(colors)],
        )

    plt.xlabel("k-mer size")
    plt.ylabel("Elapsed Time (sec)")
    plt.title(title)
    plt.xticks(ks)
    plt.legend(loc="upper left")
    plt.grid(True)  # Add grid to the plot
    plt.tight_layout()
    plt.savefig(output_file, dpi=600)
    plt.close()
    print(f"Saved time plot: {output_file}")

def main():
    p = argparse.ArgumentParser(
        description="Plot min(default,finetuned) time for each tool + maf_counter"
    )
    p.add_argument('data_csv', help="CSV with default/finetuned resource data")
    p.add_argument('maf_csv',  help="CSV with maf_counter resource data")
    p.add_argument('output_dir', help="Where to write the .png plots")
    args = p.parse_args()

    os.makedirs(args.output_dir, exist_ok=True)

    # load once
    df_tools = load_tool_data(args.data_csv)
    df_maf   = load_maf_data(args.maf_csv)

    # small vs large
    small_file = "chm13_part1.maf"
    large_file = "chm13_part1_through_10.maf"

    plot_min_time(
        df_tools, df_maf,
        small_file,
        os.path.join(args.output_dir, "small_file_time.png"),
        "Small File Benchmark – Elapsed Time (chm13_part1.maf)"
    )
    plot_min_time(
        df_tools, df_maf,
        large_file,
        os.path.join(args.output_dir, "large_file_time.png"),
        "Large File Benchmark – Elapsed Time (chm13_part1_through_10.maf)"
    )

if __name__ == "__main__":
    main()
