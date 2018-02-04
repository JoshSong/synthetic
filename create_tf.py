import tensorflow as tf
import PIL.Image
import os
import io
import json

from object_detection.utils import dataset_util

file_dir = os.path.dirname(os.path.abspath(__file__))
output_dir = 'output'

flags = tf.app.flags
flags.DEFINE_string('output_path', '', 'Path to output TFRecord')
flags.DEFINE_string('input_json', '', 'Path to json generated from combine_subdirs')
FLAGS = flags.FLAGS


def create_tf_example(img_path, info):
    img_path = str(img_path)
    with tf.gfile.GFile(img_path, 'rb') as fid:
        encoded_jpg = fid.read()
    encoded_jpg_io = io.BytesIO(encoded_jpg)
    image = PIL.Image.open(encoded_jpg_io)
    if image.format != 'JPEG':
        raise ValueError('Image format not JPEG')

    height = image.size[1]
    width = image.size[0]

    xmins = []    # List of normalized left x coordinates in bounding box (1 per box)
    xmaxs = []    # List of normalized right x coordinates in bounding box (1 per box)
    ymins = []    # List of normalized top y coordinates in bounding box (1 per box)
    ymaxs = []    # List of normalized bottom y coordinates in bounding box (1 per box)

    fwidth = float(width)
    fheight = float(height)
    for bb in info['bboxes']:
        xmins.append(bb[0] / fwidth)
        xmaxs.append(bb[2] / fwidth)
        ymins.append(bb[1] / fheight)
        ymaxs.append(bb[3] / fheight)

    tf_example = tf.train.Example(features=tf.train.Features(feature={
            'image/height': dataset_util.int64_feature(height),
            'image/width': dataset_util.int64_feature(width),
            'image/filename': dataset_util.bytes_feature(img_path),
            'image/source_id': dataset_util.bytes_feature(img_path),
            'image/encoded': dataset_util.bytes_feature(encoded_jpg),
            'image/format': dataset_util.bytes_feature('jpeg'.encode('utf8')),
            'image/object/bbox/xmin': dataset_util.float_list_feature(xmins),
            'image/object/bbox/xmax': dataset_util.float_list_feature(xmaxs),
            'image/object/bbox/ymin': dataset_util.float_list_feature(ymins),
            'image/object/bbox/ymax': dataset_util.float_list_feature(ymaxs),
            'image/object/class/text': dataset_util.bytes_list_feature([str(s) for s in info['label_names']]),
            'image/object/class/label': dataset_util.int64_list_feature(info['label_ids']),
    }))
    return tf_example


def main(_):
    if not FLAGS.output_path or not FLAGS.input_json:
        print 'Required args --output_path and --input_json'
        return

    writer = tf.python_io.TFRecordWriter(FLAGS.output_path)

    with open(FLAGS.input_json) as fp:
        all_info = json.load(fp)

    for fname, info in all_info.iteritems():
        tf_example = create_tf_example(fname, info)
        writer.write(tf_example.SerializeToString())

    writer.close()


if __name__ == '__main__':
    tf.app.run()
