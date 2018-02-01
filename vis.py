from PIL import ImageTk, Image
import Tkinter, tkFileDialog, tkMessageBox
import ttk
import sys
import os
from os import listdir
from os.path import isfile, join
import math
import json
import shutil

class Vis:
    def __init__(self, master, img_dir):
        self.master = master
        self.img_dir = img_dir
        self.init_tk()
        self.load_imgs()
        self.index = 0
        self.refresh_canvas()

    def init_tk(self):
        self.pressed = None          # Last key pressed
        self.after_id = None         # Tkinter timer for key press debouncing
        self.master.bind('<KeyPress>', self.key_press)
        self.master.bind('<KeyRelease>', self.key_release)

        self.canvas = Tkinter.Canvas(self.master)
        self.canvas.pack()

    def key_press(self, event):
        self.pressed = event.char

        if event.keysym == 'Down' or self.pressed == ' ':
            self.index += 1
            if self.index >= len(self.imgs):
                self.index = len(self.imgs) - 1
        elif event.keysym == 'Up':
            self.index -= 1
            if self.index < 0:
                self.index = 0
        self.refresh_canvas()

        if self.after_id is not None:
            event.widget.after_cancel(self.after_id)
            self.after_id = None

    def release(self):
        self.pressed = None
        self.after_id = None

    def key_release(self, event):
        if self.after_id is None:
            self.after_id = event.widget.after(50, self.release)

    def load_imgs(self):
        self.imgs = [f for f in os.listdir(self.img_dir) if os.path.isfile(join(self.img_dir, f)) and f.rsplit('.', 1)[1] != 'txt']
        self.bbs = []
        for img in self.imgs:
            f = img.rsplit('.', 1)[0] + '_bb.txt'
            self.bbs.append(self.get_bb_from_file(os.path.join(self.img_dir, f)))

    def get_bb_from_file(self, path):
        with open(path) as fp:
            line = fp.readline()
            split = line.split()
            x0 = 9999
            y0 = 9999
            x1 = 0
            y1 = 0
            for s in split:
                l = eval(s)
                x0 = min(x0, l[0])
                x1 = max(x1, l[0])
                y0 = min(y0, l[1])
                y1 = max(y1, l[1])
            return [x0, y0, x1, y1]

    def refresh_canvas(self):
        path = os.path.join(self.img_dir, self.imgs[self.index])
        bb = self.bbs[self.index]
        self.img = ImageTk.PhotoImage(Image.open(path))
        self.canvas.config(width=self.img.width(), height=self.img.height())
        self.canvas.create_image(0, 0, image=self.img, anchor=Tkinter.NW)
        self.canvas.create_rectangle(bb[0], bb[1], bb[2], bb[3], width=2)

def main(argv):
    root = Tkinter.Tk()
    vis = Vis(root, argv[0])
    root.mainloop()

if __name__ == '__main__':
    main(sys.argv[1:])