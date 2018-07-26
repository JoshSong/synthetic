import os
import csv
import matplotlib.pyplot as plt

dirs = ['syn100', 'syn1000']


data = {}
for dir in dirs:
    data[dir] = {}
    for f in os.listdir(dir):
        name = f.split('_')[-1].split('.')[0].lower()
        data[dir][name] = ([], [])
        path = os.path.join(dir, f)
        with open(path) as fp:
            reader = csv.DictReader(fp)
            for row in reader:
                data[dir][name][0].append(int(row['Step']))
                data[dir][name][1].append(float(row['Value']))

fig, ax = plt.subplots()
names = sorted(data[dirs[0]])
print names
index = 0
current = names[index]

def draw():
    ax.clear()
    ax.set_xlabel('Steps')
    ax.set_ylabel('AP')
    ax.plot(data[dirs[0]][current][0], data[dirs[0]][current][1], 'b-', label=dirs[0])
    ax.plot(data[dirs[1]][current][0], data[dirs[1]][current][1], 'r-', label=dirs[1])
    ax.set_title(current)
    ax.legend()
    plt.show()

def press(event):
    global index, current
    if event.key == 'down':
        index += 1
        if index == len(names):
            index = 0
        current = names[index]
        draw()
    elif event.key == 'up':
        index -= 1
        if index == -1:
            index = len(names) - 1
        current = names[index]
        draw()
fig.canvas.mpl_connect('key_press_event', press)
draw()

