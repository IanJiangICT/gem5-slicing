#!/usr/bin/python3

import sys

if (len(sys.argv) < 2):
	print("Usage:");
	print("    " + sys.argv[0] + " slice-file");
	exit();
else:
	slice_file = sys.argv[1]

try:
	slice_fd = open(slice_file, 'r')
except IOError:
	print("Failed to open slice file", slice_file)
	sys.exit(1)

while (True):
	slice_line = slice_fd.readline()
	if (not slice_line):
		break
	slice_line = slice_line.strip('\n')

	#
	# Replace '_' with '.' in instruction mnemonic.
	#
	if (len(slice_line) <= 0):
		output_line = slice_line
	elif (slice_line[0] == '#' or slice_line[0] == '/'):
		output_line = slice_line
	elif (':' in slice_line):
		output_line = slice_line
	else:
		mnemonic = slice_line.split(' ')[0]
		underscore_cnt = mnemonic.count('_')
		output_line = slice_line.replace('_', '.', underscore_cnt)
	
	print(output_line)

