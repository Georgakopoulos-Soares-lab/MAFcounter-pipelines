import sys
from Bio import AlignIO
from Bio.SeqRecord import SeqRecord
from Bio.Seq import Seq
from Bio.SeqIO import FastaIO
import os
# Check for correct usage
if len(sys.argv) != 3:
    print("Usage: python extract_fasta_from_maf.py <input.maf> <output_dir>")
    sys.exit(1)

# Get the MAF file from command-line arguments
maf_file = sys.argv[1]
output_dir = sys.argv[2]

# Dictionary to hold sequences by genome
species_dict = {}

# Load the MAF file with AlignIO.parse() to handle multiple alignment blocks
with open(maf_file, "r") as handle:
    for msa in AlignIO.parse(handle, "maf"):
        for record in msa:
            # Extract the species name, assuming 'genome.chromosome' format for species name
            species_name = record.id.split(".")[0]
            if species_name not in species_dict:
                species_dict[species_name] = []  # Create a list for each species
            # Append the record sequence for each genome as a new SeqRecord
            species_dict[species_name].append(SeqRecord(Seq(str(record.seq.replace('-',''))), id=record.id, description=""))

# Write each genome's sequences into a separate FASTA file
# Create output directory if it doesn't exist
os.makedirs(output_dir, exist_ok=True)

for species_name, records in species_dict.items():
    output_filename = f"{species_name}.fasta"
    with open(os.path.join(output_dir, output_filename), "w") as output_handle:
        fasta_writer = FastaIO.FastaWriter(output_handle, wrap=None)
        fasta_writer.write_file(records)
    print(f"Saved {species_name} sequences to {output_filename}")