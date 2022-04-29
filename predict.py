#!/usr/bin/env python3

import silence_tensorflow.auto
from tensorflow import keras
import sys
import numpy as np

code2class = {
 0: '2 Cell',
 1: '4 Cell',
 2: 'Blastocyst',
 3: 'Compacting 8 cell',
 4: 'Empty',
 5: 'Morula'
}

image = keras.utils.load_img(sys.argv[1], target_size=(299,299))
input_arr = keras.preprocessing.image.img_to_array(image)
input_arr = input_arr / 255
input_arr = np.array([input_arr])  # Convert single image to a batch.

model = keras.models.load_model('models/6_class.h5')

prediction = model.predict(input_arr).argmax(axis=1)[0]
print(code2class[prediction])
