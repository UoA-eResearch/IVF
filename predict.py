#!/usr/bin/env python3

import silence_tensorflow.auto
from tensorflow import keras
import sys
import numpy as np

image = keras.utils.load_img(sys.argv[1], target_size=(299,299))
input_arr = keras.preprocessing.image.img_to_array(image)
input_arr = input_arr / 255
input_arr = np.array([input_arr])  # Convert single image to a batch.

model = keras.models.load_model('models/empty_or_not.h5')
print(model.predict(input_arr).argmax(axis=1)[0])