import argparse
import csv
from datetime import timedelta

def add_seconds_to_elapsed(elapsed_str, seconds_to_add):
    """Add seconds to a HH:MM:SS string and return new HH:MM:SS."""
    h, m, s = map(int, elapsed_str.split(':'))
    total_seconds = h * 3600 + m * 60 + s + seconds_to_add
    new_h = total_seconds // 3600
    new_m = (total_seconds % 3600) // 60
    new_s = total_seconds % 60
    return f"{new_h:02d}:{new_m:02d}:{new_s:02d}"

def process_csv(input_path, output_path):
    with open(input_path, newline='') as infile, \
         open(output_path, 'w', newline='') as outfile:
        reader = csv.reader(infile)
        writer = csv.writer(outfile)
        
        # Read header
        header = next(reader)
        writer.writerow(header)
        
        for row in reader:
            filename = row[1]
            elapsed = row[6]
            
            if filename == "chm13_part1.maf":
                new_elapsed = add_seconds_to_elapsed(elapsed, 17)
            elif filename == "chm13_part1_through_10.maf":
                new_elapsed = add_seconds_to_elapsed(elapsed, 137)
            else:
                new_elapsed = elapsed
            
            row[6] = new_elapsed
            writer.writerow(row)

def main():
    parser = argparse.ArgumentParser(description="Adjust Elapsed times in CSV for specific filenames.")
    parser.add_argument("input_csv", help="Path to the input CSV file")
    parser.add_argument("output_csv", help="Path to write the modified CSV file")
    args = parser.parse_args()
    
    process_csv(args.input_csv, args.output_csv)
    print(f"Processed '{args.input_csv}' and wrote updated CSV to '{args.output_csv}'.")

if __name__ == "__main__":
    main()

