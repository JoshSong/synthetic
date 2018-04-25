import os
import sys
import json
import math
import numpy as np
import cv2
import re

extensions = ['jpg']

sys.path.append("..")
from object_detection.utils import label_map_util

def get_label_map(label_map_path):
    """Return dict mapping label names to id."""
    input = label_map_util.load_labelmap(label_map_path)
    label_map = {}
    for i in input.item:
        label_map[i.display_name] = i.id
    return label_map


def get_label_id_from_filename(fname, label_map):
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
        'stella_artois_1': 'stellaartois_symbol',
        'pepsi_0': 'pepsi_symbol',
        'pepsi_1': 'pepsi_symbol',
        'singha_0': 'singha_symbol',
        'singha_1': 'singha_symbol',
        'tsingtao_0': 'tsingtao_symbol',
        'tsingtao_1': 'tsingtao_symbol'
    }
    name = fname.rsplit('.', 1)[0]
    if name in old_map:
        name = old_map[name]
    if name in label_map:
        return name, label_map[name]
    name = name.rsplit('_', 1)[0]
    if name in label_map:
        return name, label_map[name]

    #raise ValueError('No label for fname ' + fname)
    print 'No label for fname ' + fname
    return None, None


def read_info(path, label_map):
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
        name = os.path.basename(path)
        mask_name = re.split('[._]', name)[0] + '_mask.bmp'
        mask_path = os.path.join(os.path.dirname(path), mask_name)
        if not os.path.isfile(mask_path):
            print 'WARNING: {} does not exist'.format(mask_path)
            return None
        bbox = get_bbox_from_mask(mask_path)
        if bbox is None:
            return None
        x0, y0, x1, y1 = bbox

        # Read logo name
        logo_fname = fp.readline().strip()
        label_name, label_id = get_label_id_from_filename(logo_fname, label_map)
        if label_name is None:
            return None
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
    #im2, contours, hierarchy = cv2.findContours(img, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
    contours, hierarchy = cv2.findContours(img, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)

    if len(contours) == 0:
        print 'WARNING: no contours found for {}'.format(path)
        return None

    # Return largest bounding box
    area = -1
    for c in contours:
        tx, ty, tw, th = cv2.boundingRect(c)
        if tw * th > area:
            area = tw * th
            x, y, w, h = tx, ty, tw, th
    return [x, y, x + w, y + h]

def combine_subdirs(input_dir, output_path, label_map_path):
    # Load label map
    label_map = get_label_map(label_map_path)

    # Get list of paths to all images under input_dir
    img_paths = []
    for root, dirs, files in os.walk(input_dir):
        for f in files:
            s = f.rsplit('.', 1)
            if len(s) > 1 and s[1] in extensions and s[0].isdigit():
                img_paths.append(os.path.join(root, f))
    print 'Done'

    max_per_logo = 100
    counts = {}
    allowed = set(['erdinger_symbol','ferrari','pepsi_symbol','stellaartois_symbol','dhl',
            'guinness_symbol','carlsberg_symbol','milka','cocacola','apple','ups',
            'aldi','tsingtao_symbol','google','chimay_symbol','singha_symbol','HP',
            'starbucks','heineken','bmw','corona_symbol','paulaner_symbol','fosters_symbol',
            'rittersport','nvidia_symbol','fedex','esso_symbol','ford','texaco','becks_symbol',
            'shell','adidas_symbol'])
    use_limits = True

    # Collect bounding box and label info
    i = 0
    all_info = {}
    for img_path in img_paths:
        i += 1
        if i % 100 == 0:
            print '{}/{} done'.format(i, len(img_paths))
        s = img_path.rsplit('.', 1)
        info_path = s[0] + '_bb.txt'
        if os.path.isfile(info_path):
            info = read_info(info_path, label_map)
            if info is not None:
                name = info['label_names'][0]
                if use_limits :
                    if name not in allowed or counts.get(name, 0) >= max_per_logo:
                        continue
                counts[name] = counts.get(name, 0) + 1
                all_info[img_path] = info
        else:
            print info_path + ' does not exist, skipping'

    # Save json to output_path
    with open(output_path, 'w') as fp:
        json.dump(all_info, fp, indent=4, sort_keys=True)

    print counts

if __name__ == '__main__':
    args = sys.argv

    if len(args) == 4:
        combine_subdirs(args[1], args[2], args[3])
    else:
        print "Usage: python combine_subdirs input_dir output_path label_map"

