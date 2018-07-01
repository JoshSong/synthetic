import math
import matplotlib.pyplot as plt
import numpy as np
import csv
import json
from numpy import linspace, meshgrid
import matplotlib
from matplotlib.mlab import griddata
from mpl_toolkits.mplot3d import Axes3D
from matplotlib.widgets import Slider

def grid(x, y, z, resX=100, resY=100):
    "Convert 3 column data to matplotlib grid"
    xi = linspace(min(x), max(x), resX)
    yi = linspace(min(y), max(y), resY)
    Z = griddata(x, y, z, xi, yi, interp='linear')
    X, Y = meshgrid(xi, yi)
    return X, Y, Z

def reject_outliers(data, m=2):
    return data[abs(data - np.mean(data)) < m * np.std(data)]

xs = []
ys = []
zs = []
corrects = []
xsc = []
ysc = []
zsc = []

data = {}
with open('hypo_0/correct_by_image_key.json', 'rb') as fp:
    temp = json.load(fp)
    print 'Loaded ' + str(len(temp)) + ' data points'
    for fname, val in temp.iteritems():
        id = int(fname.split('/')[-1].split('.')[0])
        if id >= 7600: # The full 8000 images was not generated, so don't use past i0 = 19
            continue

        # Hack to get params for hypo_0
        i0 = id / 400
        i1 = (id % 400) / 20
        i2 = id % 20
        minDist = 20
        maxDist = 200
        minTheta = -60
        maxTheta = 60
        minIntensity =  10
        maxIntensity = 2000
        dist = (maxDist - minDist)*(i0/20.0)+minDist
        theta = (maxTheta - minTheta)*(i1/20.0)+minTheta
        intensity = (maxIntensity - minIntensity)*(i2/20.0)+minIntensity
        correct = val[1] == 1
        corrects.append(correct)

        xs.append(dist)
        ys.append(theta)
        zs.append(intensity)

        if correct:
            xsc.append(dist)
            ysc.append(theta)
            zsc.append(intensity)


plt.hist(np.array(xsc), bins=20)
plt.show()
plt.hist(np.array(ysc), bins=20)
plt.show()
plt.hist(np.array(zsc), bins=20)
plt.show()

"""
fig = plt.figure()
ax = fig.add_subplot(111)
ax.set_xlabel('X')
ax.set_ylabel('Y')
ax.scatter(xs, ys, c='b')
plt.show()
"""

"""
kin_x2 = [x for x in kin_x]
kin_y2 = [y for y in kin_y]

fig = plt.figure()

ax_xoff = fig.add_axes([0.2, 0.02, 0.65, 0.03])
ax_yoff = fig.add_axes([0.2, 0.06, 0.65, 0.03])
s_xoff = Slider(ax_xoff, 'X offset (cm)', -4, 4, valinit=0)
s_yoff = Slider(ax_yoff, 'Y offset (cm)', -4, 4, valinit=0)

fig.subplots_adjust(bottom=0.2)
ax = fig.add_subplot(111)
ax.set_xlabel('X')
ax.set_ylabel('Y')
ax.scatter(opti_x, opti_y, c='b')
ax.scatter(kin_x2, kin_y2, c='r')

def update(val):
    xoff = s_xoff.val / 100.0
    yoff = s_yoff.val / 100.0
    kin_x2 = [x + xoff for x in kin_x]
    kin_y2 = [y + yoff for y in kin_y]
    ax.clear()
    ax.scatter(opti_x, opti_y, c='b')
    ax.scatter(kin_x2, kin_y2, c='r')
    fig.canvas.draw()

s_xoff.on_changed(update)
s_yoff.on_changed(update)


plt.show()
"""

fig = plt.figure()
ax = fig.add_subplot(111, projection='3d')
ax.set_xlabel('Dist')
ax.set_ylabel('Theta')
ax.set_zlabel('Intensity')
ax.scatter(xsc, ysc, zsc)
plt.show()

temp = {}
for i in range(len(corrects)):
    xy = (xs[i], ys[i])
    #xy = (xs[i], zs[i])
    temp[xy] = temp.get(xy, 0) + corrects[i]

xs2 = []
ys2 = []
zs2 = []
for i in sorted(temp):
    xs2.append(i[0])
    ys2.append(i[1])
    zs2.append(temp[i])
    print(str(i) + ' '  + str(temp[i]))
print(zs2)

x, y, z = grid(xs2, ys2, zs2, 200, 200)
clev = np.arange(0, 22, 0.1)
plt.contourf(x, y, z, clev)
plt.show()