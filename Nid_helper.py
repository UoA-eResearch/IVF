import cv2
import sqlite3


import numpy as np
from PIL import Image, ImageDraw


IMG_PATH = "C:\\Users\\ngow210\\Downloads\\index.jpg"

def circ_img_crop(IMG_SIZE, IMG_PATH, RESIZE):
    img=Image.open(IMG_PATH)

    if RESIZE == True:
        img = img.resize([IMG_SIZE, IMG_SIZE], 3)

    height,width = img.size

    lum_img = Image.new('L', [height,width] , 0)
    draw = ImageDraw.Draw(lum_img)
    draw.pieslice([(0,0), (height,width)], 0, 360, fill = 255, outline = "black")
    
    img_arr =np.array(img)
    lum_img_arr =np.array(lum_img)
    lum_img = Image.fromarray(lum_img_arr)

    final_cropped_img_arr = np.dstack((img_arr,lum_img_arr))
    cropped_image = Image.fromarray(final_cropped_img_arr)

    return cropped_image