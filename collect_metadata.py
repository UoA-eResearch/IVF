#!/usr/bin/env python3

from glob import glob
import sqlite3
import pandas as pd
from tqdm.auto import tqdm
import os
import re

files = glob("../embryo/**/*.pdb", recursive=True)
result_dfs = []
for f in tqdm(files):
    try:
        filename = os.path.basename(f)
        match = re.search(r'S(\d+)_I(\d+)', filename)
        slide, machine = match.groups()
        df = pd.read_sql_query("SELECT * from General WHERE Type='Description' AND Par LIKE 'Embryo%'", sqlite3.connect(f))
        df["Well"] = df.Par.str.replace("Embryo", "").astype(int)
        df["FileName"] = filename
        df["Location"] = f
        df["Dataset"] = ""
        df["Machine"] = int(machine)
        df["Slide"] = int(slide)
        df = df.sort_values(by="Well")
        df = df[["FileName", "Location", "Dataset", "Machine", "Slide", "Well"]]
        result_dfs.append(df)
    except Exception as e:
        print(df)
        print(f"ERROR: {e} for {f}")

result = pd.concat(result_dfs).reset_index(drop=True)
result.to_csv("../PDB_database_summary.csv", index_label="Index")
