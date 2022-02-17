#!/usr/bin/env python3

import sqlite3 # Reading sqlite database files
import pandas as pd # Tabular data
from tqdm.auto import tqdm # Progress bars
import argparse # Parsing command line arguments
import os # OS file operations
import re # Regular expressions
from PIL import Image, ImageFile # Image manipulation
ImageFile.LOAD_TRUNCATED_IMAGES = True
import io

parser = argparse.ArgumentParser(description="PDB image extractor", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-input_file', '-i', help='Input file', required=True)
parser.add_argument('-focal', '-f', help='Focal plane', type=int, default=0, choices=range(-45, 46, 15))
parser.add_argument('-output_dir', '-o', help='Output directory', default="./")
parser.add_argument('-min_interval', '-m', help='Only extract images that are at least this far apart, in minutes', type=int, default=60)
args = parser.parse_args()

filename = os.path.basename(args.input_file)
match = re.search(r'S(\d+)_I(\d+)', filename)
slide, machine = match.groups()

con = sqlite3.connect(args.input_file)

cur = con.cursor()
cur.execute("SELECT Val FROM GENERAL WHERE Par = 'Fertilization'")
# Fertilisation time. Time appears to be represented as fractional days since Jan 1, 1900
fert = float(cur.fetchone()[0])

df = pd.read_sql_query(f"SELECT * from IMAGES WHERE Focal={args.focal}", con)
df["time_since_fert_minutes"] = (df.Time - fert) * 24 * 60
print(df)
print(df.describe())

for well in tqdm(df.Well.unique()):
    df_for_well = df[df.Well == well]
    last_time = float("-inf")
    for i, row in tqdm(df_for_well.iterrows()):
        dt = row.time_since_fert_minutes - last_time
        if dt > args.min_interval:
            last_time = row.time_since_fert_minutes
            filename = f"M{machine}_S{slide}_W{well}_F{args.focal}_{round(row.time_since_fert_minutes)}.jpg"
            filename = os.path.join(args.output_dir, filename)
            Image.open(io.BytesIO(row.Image)).save(filename,quality=100, subsampling=-1)