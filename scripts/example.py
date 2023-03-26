import cv2
import numpy as np
import insightface
from insightface.app import FaceAnalysis
from insightface.data import get_image as ins_get_image

app = FaceAnalysis(providers=['CUDAExecutionProvider', 'CPUExecutionProvider'])
app.prepare(ctx_id=0, det_size=(640, 640))
img = ins_get_image('t1')
faces = app.get(img)


print("-------")
print("-------")
print("-------")
print("-------")
print("-------")
print("-------")
print("-------")

print(len(faces))
cv2.imshow('img', img)

