#!/usr/bin/env python3
import argparse
import csv
import os

def parse_size_to_mb(size_str):
    if size_str.endswith('G'):
        return float(size_str[:-1]) * 1024
    if size_str.endswith('M'):
        return float(size_str[:-1])
    if size_str.endswith('K'):
        return float(size_str[:-1]) / 1024
    return float(size_str) / 1024

def parse_elapsed_to_seconds(elapsed_str):
    h, m, s = map(int, elapsed_str.split(':'))
    return h*3600 + m*60 + s

def read_data(csv_path):
    data = {}
    with open(csv_path, newline='') as f:
        rdr = csv.DictReader(f)
        for r in rdr:
            fn = r['filename']
            prog_full = r['program']
            if '_' in prog_full:
                prog, tuning = prog_full.rsplit('_', 1)
            else:
                prog, tuning = prog_full, 'default'
            k = int(r['k'])
            rec = {
                'elapsed': parse_elapsed_to_seconds(r['Elapsed']),
                'rss':     int(parse_size_to_mb(r.get('MaxRSS', '0'))),
                'disk':    int(parse_size_to_mb(r['MaxDiskWrite']))
            }
            data.setdefault(fn, {}) \
                .setdefault(prog, {}) \
                .setdefault(tuning, {})[k] = rec
    return data

def read_maf_data(csv_path):
    maf = {}
    with open(csv_path, newline='') as f:
        rdr = csv.DictReader(f)
        for r in rdr:
            fn = r['filename']
            k  = int(r['k'])
            rec = {
                'elapsed': parse_elapsed_to_seconds(r['Elapsed']),
                'rss':     int(parse_size_to_mb(r.get('MaxRSS', '0'))),
                'disk':    int(parse_size_to_mb(r['MaxDiskWrite']))
            }
            maf.setdefault(fn, {})[k] = rec
    return maf

def make_table(prog_data, maf_rec, ks):
    """
    Build a LaTeX table with zero left padding (@{}), minimal inner padding,
    renamed headers, centered values, and auto-fit to page via adjustbox.
    Reports only Time, RAM and Disk.
    """
    # 1 Program col + 3 columns per K (Time, RAM, Disk)
    n_cols = 1 + 3 * len(ks)
    col_spec = '@{}|' + '|'.join(['c'] * n_cols) + '|'
    lines = [
        r'\noindent',
        r'\setlength{\tabcolsep}{1pt}',  # minimal inner padding
        r'\scriptsize',
        r'\begin{adjustbox}{max width=\textwidth, max totalheight=\textheight, keepaspectratio}',
        r'\begin{tabular}{' + col_spec + r'}',
        r'\hline',
    ]

    # Header row 1
    hdr1 = [r'\textbf{Program}'] + [
        r'\multicolumn{3}{c|}{\textbf{K=%d}}' % k for k in ks
    ]
    lines += [' & '.join(hdr1) + r' \\', r'\hline']

    # Header row 2 (renamed, with small space)
    space = r'\hspace{2pt}'
    hdr2 = ['']
    for _ in ks:
        hdr2 += [
            rf'\textbf{{{space}Time{space}}}',
            rf'\textbf{{{space}RAM{space}}}',
            rf'\textbf{{{space}Disk{space}}}'
        ]
    lines += [' & '.join(hdr2) + r' \\', r'\hline']

    # MAFCounter row
    row = [r'\textit{MAFCounter}']
    for k in ks:
        rec = maf_rec.get(k, {})
        if rec:
            row += [
                f"{rec['elapsed']:,}",
                f"{rec['rss']:,}",
                f"{rec['disk']:,}"
            ]
        else:
            row += ['-'] * 3
    lines += [' & '.join(row) + r' \\', r'\hline']

    # Program rows
    for prog in sorted(prog_data):
        tbl = prog_data[prog]
        cells = [r'\textit{%s}' % prog]
        for k in ks:
            rec = tbl.get(k, {})
            if rec:
                cells += [
                    f"{rec['elapsed']:,}",
                    f"{rec['rss']:,}",
                    f"{rec['disk']:,}"
                ]
            else:
                cells += ['-'] * 3
        lines += [' & '.join(cells) + r' \\', r'\hline']

    lines += [
        r'\end{tabular}',
        r'\end{adjustbox}'
    ]
    return '\n'.join(lines)

def main():
    p = argparse.ArgumentParser(
        description="CSV → four LaTeX files with left-flush, auto-fitting tables"
    )
    p.add_argument('data_csv',   help="CSV with default/finetuned data")
    p.add_argument('maf_csv',    help="MAFCounter CSV")
    p.add_argument('output_dir', help="Directory to write .tex files")
    args = p.parse_args()

    os.makedirs(args.output_dir, exist_ok=True)
    data     = read_data(args.data_csv)
    maf_data = read_maf_data(args.maf_csv)

    files = [
        ('chm13_part1.maf',            'chm13_part1'),
        ('chm13_part1_through_10.maf', 'chm13_part1_through_10')
    ]
    ks = [10, 20, 30, 55]

    for fn, base in files:
        file_data = data.get(fn, {})
        file_maf  = maf_data.get(fn, {})

        for tuning in ['default', 'finetuned']:
            subset = {
                prog: file_data[prog][tuning]
                for prog in file_data
                if tuning in file_data[prog]
            }
            out_path = os.path.join(args.output_dir, f"{base}_{tuning}.tex")
            with open(out_path, 'w') as out:
                out.write(r'\documentclass{article}' + "\n")
                out.write(r'\usepackage[margin=1in]{geometry}' + "\n")
                out.write(r'\usepackage{adjustbox}' + "\n")
                out.write(r'\begin{document}' + "\n\n")
                out.write(make_table(subset, file_maf, ks) + "\n\n")
                out.write(r'\end{document}' + "\n")
            print(f"Wrote {out_path}")

if __name__ == '__main__':
    main()
