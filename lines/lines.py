#!/usr/bin/env python
import numpy as np
import cv2
import os
import random

output_dir = 'output1' #output0
size = 300
num = 1000 #5000

if not os.path.isdir(output_dir):
    os.mkdir(output_dir)

for i in range(num):
    img = np.zeros((size, size, 4), dtype=np.uint8)
    for j in range(random.randint(0, 10)): #(0, 50)
        r1 = random.randint(0, size)
        r2 = random.randint(0, size)
        c1 = random.randint(0, size)
        c2 = random.randint(0, size)
        b = random.randint(0, 255)
        g = random.randint(0, 255)
        r = random.randint(0, 255)
        thickness = random.randint(1, 3) #(1, 5)
        cv2.line(img, (r1, c1), (r2, c2), (b, g, r, 255), thickness)
        cv2.imwrite(os.path.join(output_dir, str(i) + '.png'), img)
