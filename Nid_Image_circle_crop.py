import cv2
import sqlite3


import numpy as np
from PIL import Image, ImageDraw


IMG_PATH = "C:\\Users\\ngow210\\Downloads\\index.jpg"
IMG_SIZE = 299

'''
# creating file path
dbfile = 'C:\\Users\\ngow210\\Source\\Repos\\UoA-eResearch\\IVF\\PDBextract.db'
# Create a SQL connection to our SQLite database
con = sqlite3.connect(dbfile)

# creating cursor
cur = con.cursor()

# reading all table names
table_list = [a for a in cur.execute("SELECT name FROM sqlite_master WHERE type = 'table'")]
# here is you table list
print(table_list)

input()

cur.close()
'''
  
img=Image.open(IMG_PATH)
#img.show()

img = img.resize([IMG_SIZE, IMG_SIZE], 3)

#resized_img.show()
#img.show()
  
height,width = img.size
lum_img = Image.new('L', [height,width] , 0)
  
draw = ImageDraw.Draw(lum_img)
draw.pieslice([(0,0), (height,width)], 0, 360, fill = 255, outline = "black")
img_arr =np.array(img)
lum_img_arr =np.array(lum_img)
lum_img = Image.fromarray(lum_img_arr)

final_img_arr = np.dstack((img_arr,lum_img_arr))
final_img = Image.fromarray(final_img_arr)

height,width = final_img.size

final_img.save("C:\\Users\\ngow210\\Downloads\\index2.png")

lum_img.show()
final_img.show()

input()

