import tensorflow as tf
import PIL.Image
import os
import sys
import io
import hashlib
import shutil

from object_detection.utils import dataset_util
from object_detection.utils import label_map_util

file_dir = os.path.dirname(os.path.abspath(__file__))
output_dir = 'output'

flags = tf.app.flags
flags.DEFINE_string('output_path', '', 'Path to output TFRecord')
flags.DEFINE_string('input_dir', '', 'Path to input directory generated from combine_subdirs')
flags.DEFINE_string('label_map_path', 'flickr47_label_map.pbtxt', 'Path to label map proto')
FLAGS = flags.FLAGS


def get_label_map(label_map_path):
    """Return dict mapping label names to id."""
    input = label_map_util.load_labelmap(label_map_path)
    label_map = {}
    for i in input.item:
        label_map[i.display_name] = int(i.name)
    return label_map
label_map = get_label_map(FLAGS.label_map_path)


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
        'stella_artois_0': 'stellaartois_symbol'
    }
    name = fname.rsplit('.', 1)[0]
    if name in old_map:
        name = old_map[name]
    return name

def combine_subdirs(input_dir, output_dir, extensions=['.jpg']):

    # Get list of paths to all images under input_dir
    img_paths = []
    for root, dirs, files in os.walk('input_dir'):
        for f in files:
            s = f.rsplit('.', 1)
            if len(s) > 1 and s[1] in extensions:
                img_paths.append(os.path.join(root, f))

    # Copy images to output_dir and collect bounding box and label info
    all_info = {}
    i = 0
    for img_path in img_paths:
        s = img_path.rspilt('.', 1)
        info_path = s[0] + '_bb.txt'
        if os.path.isfile(info_path):
            new_img_fname = '{}.{}'.format(i, s[1])
            new_img_path = os.path.join(output_dir, new_img_fname)
            all_info[new_img_fname] = read_info(info_path)
            shutil.copyfile(img_path, new_img_path)
            i += 1
        else:
            print info_path + ' does not exist, skipping'

    with open(os.path.join(output_dir, 'info.json'), 'w') as fp:
        json.dump(all_info, fp, indent=4, sort_keys=True)


def read_info(path):
    with open(path) as fp:
        # Read bounding box points
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

        # Read logo name
        logo_fname = fp.readline().strip()
        label_name = get_label_from_filename(logo_fname)
        label_id = label_map[label_name]
        return {'bboxes': [[x0, y0, x1, y1]], 'label_names': [label_name], 'label_ids': [label_id]}


def create_tf_example(img_path, info):

    with tf.gfile.GFile(img_path, 'rb') as fid:
        encoded_jpg = fid.read()
    encoded_jpg_io = io.BytesIO(encoded_jpg)
    image = PIL.Image.open(encoded_jpg_io)
    if image.format != 'JPEG':
        raise ValueError('Image format not JPEG')
    key = hashlib.sha256(encoded_jpg).hexdigest()
    import pdb; pdb.set_trace()

    height = image.size[1]
    width = image.size[0]
    filename = os.path.basename(img_path)

    xmins = []    # List of normalized left x coordinates in bounding box (1 per box)
    xmaxs = []    # List of normalized right x coordinates in bounding box (1 per box)
    ymins = []    # List of normalized top y coordinates in bounding box (1 per box)
    ymaxs = []    # List of normalized bottom y coordinates in bounding box (1 per box)

    fwidth = float(width)
    fheight = float(height)
    for bb in info['bbs']:
        xmins.append(bb[0] / fwidth)
        xmaxs.append(bb[2] / fwidth)
        ymins.append(bb[1] / fheight)
        ymaxs.append(bb[3] / fheight)

    tf_example = tf.train.Example(features=tf.train.Features(feature={
            'image/height': dataset_util.int64_feature(height),
            'image/width': dataset_util.int64_feature(width),
            'image/filename': dataset_util.bytes_feature(filename),
            'image/source_id': dataset_util.bytes_feature(filename),
            'image/encoded': dataset_util.bytes_feature(encoded_jpg),
            'image/format': dataset_util.bytes_feature('jpeg'.encode('utf8')),
            'image/object/bbox/xmin': dataset_util.float_list_feature(xmins),
            'image/object/bbox/xmax': dataset_util.float_list_feature(xmaxs),
            'image/object/bbox/ymin': dataset_util.float_list_feature(ymins),
            'image/object/bbox/ymax': dataset_util.float_list_feature(ymaxs),
            'image/object/class/text': dataset_util.bytes_list_feature(info['label_names']),
            'image/object/class/label': dataset_util.int64_list_feature(info['label_ids']),
    }))
    return tf_example


def main(_):
    writer = tf.python_io.TFRecordWriter(FLAGS.output_path)

    with open(os.path.join(FLAGS.input_dir, 'info.json')) as fp:
        all_info = json.load(fp)

    for fname, info in all_info.iteritems():
        img_path = os.path.join(FLAGS.input_dir, fname)
        tf_example = create_tf_example(img_path, info)
        writer.write(tf_example.SerializeToString())

    writer.close()


if __name__ == '__main__':
    tf.app.run()
