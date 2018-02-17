import os
import sys
import json
import math
import numpy as np
import cv2

label_map_path = 'flickr47_label_map.pbtxt'
extensions = ['jpg']

sys.path.append("..")
from object_detection.utils import label_map_util

def get_label_map(label_map_path):
    """Return dict mapping label names to id."""
    input = label_map_util.load_labelmap(label_map_path)
    label_map = {}
    for i in input.item:
        label_map[i.display_name] = int(i.name)
    return label_map
label_map = get_label_map(label_map_path)


def get_label_from_filename(fname):
    old_map = {
        'becks': 'becks_symbol',
        'carlsberg': 'carlsberg_symbol',
        'chimay': 'chimay_symbol',
        'coca_cola': 'cocacola',
        'corona_0': 'corona_symbol',
        'corona_1': 'corona_symbol',
        'erdinger': 'erdinger_symbol',
        'esso': 'esso_symbol',
        'fosters': 'fosters_symbol',
        'stella_artois_0': 'stellaartois_symbol',
        'stella_artois_1': 'stellaartois_symbol'
    }
    name = fname.rsplit('.', 1)[0]
    if name in old_map:
        name = old_map[name]
    return name

def read_info(path):
    with open(path) as fp:
        # Read bounding box points
        line = fp.readline()
        """
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
        """
        mask_path = path.rsplit('.', 1)[0] + '_mask.bmp'
        x0, y0, x1, y1 = get_bbox_from_mask(mask_path)

        # Read logo name
        logo_fname = fp.readline().strip()
        label_name = get_label_from_filename(logo_fname)
        label_id = label_map[label_name]
        return {'bboxes': [[x0, y0, x1, y1]], 'label_names': [label_name], 'label_ids': [label_id]}

def dist(p1, p2):
    dx = p1[0] - p2[0]
    dy = p1[1] - p2[1]
    return math.sqrt(dx*dx + dy*dy)

def get_bbox_from_mask(path):
    img = cv2.imread(path, 0)

    # Need to get rid of weird cylinder bug. Dilate and use contour detection
    kernel = np.ones((15, 15), np.uint8)
    img = cv2.morphologyEx(img, cv2.MORPH_CLOSE, kernel)
    im2, contours, hierarchy = cv2.findContours(thresh, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)

    # Return largest bounding box
    area = -1
    for c in contours:
        tx, ty, tw, th = cv2.boundingRect(c)
        if tw * th > area:
            area = tw * th
            x, y, w, h = tx, ty, tw, th
    return [x, y, x + w, y + h]

def combine_subdirs(input_dir, output_path):
    # Get list of paths to all images under input_dir
    img_paths = []
    for root, dirs, files in os.walk(input_dir):
        for f in files:
            s = f.rsplit('.', 1)
            if len(s) > 1 and s[1] in extensions:
                img_paths.append(os.path.join(root, f))

    # Collect bounding box and label info
    all_info = {}
    for img_path in img_paths:
        s = img_path.rsplit('.', 1)
        info_path = s[0] + '_bb.txt'
        if os.path.isfile(info_path):
            all_info[img_path] = read_info(info_path)
        else:
            print info_path + ' does not exist, skipping'

    # Save json to output_path
    with open(output_path, 'w') as fp:
        json.dump(all_info, fp, indent=4, sort_keys=True)


if __name__ == '__main__':
    args = sys.argv

    if len(args) == 3:
        combine_subdirs(args[1], args[2])
    else:
        print "Usage: python combine_subdirs input_dir output_path"

