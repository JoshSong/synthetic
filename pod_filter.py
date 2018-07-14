#!/usr/bin/env python
import os
import sys
import json
import csv
import string
import shutil

printable = set(string.printable)
unwanted_tokens = {'inc', 'llc', 'ltd', 'co', 'sa', 'gmbh', 'de', 'sas',
        'ltda', 'corp', 'the', 'sarl', 'spa', 'srl', 'ind', 'pty', 'sdn', 'bhd'}
for p in string.punctuation:
    unwanted_tokens.add(p)

missing_brands = {'solo', '100 plus', 'pacific refreshments', 'bundaberg',
        'paulaner', 'kirsch beverages', 'frucor brands international bv'}

group_dir = 'grouped'

def format_string(s):
    s = ''.join(filter(lambda x: x in printable, s))
    s = str(s).strip().lower()
    s = s.translate(None, string.punctuation)
    s = s.split(' ')
    s = [t for t in s if t and t not in unwanted_tokens]
    return ' '.join(s)

def get_phrases(info, use_owner=True):
    phrases = []
    phrases += info.get('text_description', [])
    #phrases += info.get('word_constituents', [])
    if use_owner:
        phrases += info.get('owner_name-0', [])
        phrases += info.get('owner_name-1', [])
        phrases += info.get('owner_name-2', [])
    phrases = [format_string(p) for p in phrases]
    phrases = [p for p in phrases if len(p) > 2]
    return phrases

def run_filter(input_dir):

    # Load pod info
    with open(os.path.join('products_open_database', 'pod_gtin.csv')) as fp:
        reader = csv.DictReader(fp, delimiter=';')
        count = 0
        brands = set()
        for row in reader:
            gpc = row['GPC Segmentation Code'].strip()
            if gpc == '' or gpc == '50000000':
                brands.add(format_string(row['Brand']))
                brands.add(format_string(row['Brand Owner']))
                brands.add(format_string(row['Logistical Owner (GLN)']))
            count += 1
        print '{} lines read from pod csv'.format(count)
        brands = set([o for o in brands if len(o) > 2])
    brands = brands.union(missing_brands)

    if not os.path.isdir('yes'):
        os.mkdir('yes')

    for root, dirs, files in os.walk(input_dir):
        for f in files:
            s = f.rsplit('.', 1)
            if s[1] == 'json':
                json_path = os.path.join(root, f)
                img_path = os.path.join(root, s[0] + '.png')
                if not os.path.isfile(img_path):
                    continue

                info = json.load(open(json_path))[1]
                phrases = get_phrases(info)
                if any(p in brands for p in phrases):
                    os.rename(json_path, os.path.join('yes', f))
                    os.rename(img_path, os.path.join('yes', s[0] + '.png'))

def group(input_dir):
    if not os.path.isdir(group_dir):
        os.mkdir(group_dir)

    grouped = {}   # {group name: set of phrases}
    ungrouped = {} # {image id: set of phrases}

    def create_group(id0, id1, phrases0, phrases1, group_name):
        os.mkdir(os.path.join(group_dir, group_name))
        grouped[group_name] = set(phrases0).union(phrases1)
        os.rename(os.path.join(input_dir, id0 + '.json'), os.path.join(group_dir, group_name, id0 + '.json'))
        os.rename(os.path.join(input_dir, id0 + '.png'), os.path.join(group_dir, group_name, id0 + '.png'))
        os.rename(os.path.join(input_dir, id1 + '.json'), os.path.join(group_dir, group_name, id1 + '.json'))
        os.rename(os.path.join(input_dir, id1 + '.png'), os.path.join(group_dir, group_name, id1 + '.png'))

    def add_to_group(group_name, id, phrases):
        grouped[group_name] = grouped[group_name].union(phrases)
        os.rename(os.path.join(input_dir, id + '.json'), os.path.join(group_dir, group_name, id + '.json'))
        os.rename(os.path.join(input_dir, id + '.png'), os.path.join(group_dir, group_name, id + '.png'))

    def helper(use_owner):
        count = 0
        files = os.listdir(input_dir)
        for f in files:
            s = f.rsplit('.', 1)
            if s[1] == 'json':
                id = s[0]
                info = json.load(open(os.path.join(input_dir, f)))[1]
                phrases = set(get_phrases(info, use_owner))
                added = False
                for group_name in grouped:
                    group_phrases = grouped[group_name]
                    if any(p in group_phrases for p in phrases):
                        add_to_group(group_name, id, phrases)
                        added = True
                        break
                if not added:
                    for id1 in list(ungrouped.keys()):
                        for p in phrases:
                            if p in ungrouped[id1]:
                                create_group(id, id1, phrases, ungrouped.pop(id1), p)
                                added = True
                                break
                        if added:
                            break
                if not added:
                    ungrouped[id] = set(phrases)

                print '{}/{}'.format(count, len(files)/2)
                count += 1

    # First round: group only on logo text
    print 'Round 1'
    helper(False)

    # Second round: group on company name
    print 'Round 2'
    grouped.clear()
    ungrouped.clear()
    dirs = [d for d in os.listdir(group_dir) if os.path.isdir(os.path.join(group_dir, d))]
    for group_name in dirs:
        grouped[group_name] = set()
        for f in os.listdir(os.path.join(group_dir, group_name)):
            s = f.rsplit('.', 1)
            if s[1] == 'json':
                info = json.load(open(os.path.join(group_dir, group_name, f)))[1]
                phrases = set(get_phrases(info, True))
                grouped[group_name] = grouped[group_name].union(phrases)
    helper(True)

    # Move all remaining ones to group_dir
    for id in ungrouped:
        os.rename(os.path.join(input_dir, id + '.json'), os.path.join(group_dir, id + '.json'))
        os.rename(os.path.join(input_dir, id + '.png'), os.path.join(group_dir, id + '.png'))

def undo_group(original_dir):
    for root, dirs, files in os.walk(group_dir):
        for f in files:
            os.rename(os.path.join(root, f), os.path.join(original_dir, f))

if __name__ == '__main__':
    args = sys.argv

    if len(args) == 3 and args[1] == 'filter':
        run_filter(args[2])
    elif len(args) == 3 and args[1] == 'group':
        group(args[2])
    elif len(args) == 3 and args[1] == 'undo_group':
        undo_group(args[2])
    else:
        print "Usage: python pod_filter.py filter input_dir"
        print "Or: python pod_filter.py group input_dir"
        print "Or: python pod_filter.py undo_group original_dir"
