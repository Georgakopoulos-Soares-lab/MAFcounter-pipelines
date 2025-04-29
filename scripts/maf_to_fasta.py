import sys
from Bio import AlignIO
import os

# Check for correct usage
if len(sys.argv) != 3:
    print("Usage: python extract_fasta_from_maf.py <input.maf> <output_dir>")
    sys.exit(1)

maf_file, output_dir = sys.argv[1], sys.argv[2]
os.makedirs(output_dir, exist_ok=True)

# Dictionary to hold open file handles per species
species_handles = {}

with open(maf_file, "r") as handle:
    for msa in AlignIO.parse(handle, "maf"):
        for record in msa:
            species = record.id.split(".", 1)[0]
            if species not in species_handles:
                path = os.path.join(output_dir, f"{species}.fasta")
                species_handles[species] = open(path, "w")
            fh = species_handles[species]
            seq_str = str(record.seq).replace("-", "")
            fh.write(f">{record.id}\n{seq_str}\n")

for species, fh in species_handles.items():
    fh.close()
    print(f"Saved {species} sequences to {species}.fasta")