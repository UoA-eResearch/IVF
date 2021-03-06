#!/usr/bin/env python3

import silence_tensorflow.auto

# Don't use all of the GPU RAM
import tensorflow as tf
gpus = tf.config.experimental.list_physical_devices('GPU')
for gpu in gpus:
  tf.config.experimental.set_memory_growth(gpu, True)

from tensorflow import keras
import sys
import numpy as np
import pandas as pd
import argparse
import os
from tqdm.auto import tqdm
import shutil

parser = argparse.ArgumentParser(description="Apply model to unclassified images", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-input_directory', '-i', help='Input directory', required=True)
parser.add_argument('-classes', '-c', help='Classes to export')
parser.add_argument('-output_dir', '-o', help='Output directory', default="./predictions")
parser.add_argument('-remove', '-rm', '-mv', help='Use move instead of copy', action="store_true")
parser.add_argument('-model', '-m', help='Location of h5 model file to use', default="/mnt/data/IVF/models/12_class.h5")
parser.add_argument('-threshold', '-t', help='Cutoff threshold for confidence', type=float, default=.95)
parser.add_argument('-all_pred', '-a', help='Whether to output a CSV of all predictions with probabilites for each class', action="store_true")
args = parser.parse_args()

test = tf.keras.utils.image_dataset_from_directory(
    args.input_directory,
    image_size = (299,299),
    batch_size = 512,
    labels = None,
    shuffle = False
)

base_model = keras.models.load_model("/mnt/data/IVF/models/xception.h5")
model = keras.models.load_model(args.model)

classes = list(pd.read_csv(args.model + "_classes.txt", header=None)[0])
print(f"Loaded {args.model}. Classes known by this model:\n{classes}")

if args.classes:
  classes_to_export = args.classes.split(",")
else:
  classes_to_export = classes

extracted_features = base_model.predict(test)

fert_minutes = pd.Series(test.file_paths).apply(lambda s: s.replace(".jpg", "").split("_")[-1]).astype(int)
extracted_features_with_fert = np.hstack([extracted_features, fert_minutes.to_numpy()[:, None]])

probabilites = model.predict(extracted_features_with_fert)

df = pd.DataFrame()
df["filename"] = test.file_paths
df["class"] = [classes[c] for c in probabilites.argmax(axis=1)]
df["confidence"] = probabilites.max(axis=1)

os.makedirs(args.output_dir, exist_ok=True)


for i, row in tqdm(df.iterrows(), total=len(df)):
  if row["class"] in classes_to_export:
    if row["confidence"] > args.threshold:
      folder = os.path.join(args.output_dir, row["class"])
    else:
      folder = os.path.join(args.output_dir, "low_confidence")
    os.makedirs(folder, exist_ok=True)
    if args.remove:
      shutil.move(row.filename, folder)
    else:
      shutil.copy2(row.filename, folder)

if args.all_pred:
  all_pred = pd.concat([df, pd.DataFrame(probabilites, columns=classes)], axis="columns")
  all_pred.to_csv(os.path.join(args.output_dir, "all_predictions.csv"), index=False, float_format="%f")