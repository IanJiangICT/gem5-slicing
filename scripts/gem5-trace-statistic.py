#!/usr/bin/python

import sys

if (len(sys.argv) < 2):
	print("Usage:");
	print("    " + sys.argv[0] + " trace-file");
	exit();
else:
	trace_file = sys.argv[1]

# instruction: (cnt, last-line)
#inst_cnt = {'null': (0, 0)}
inst_cnt = {}
line_num = 0
with open(trace_file) as f:
	for line in f:
		line_num += 1
		if line in inst_cnt:
			inst_cnt[line] = [(inst_cnt[line][0] + 1), line_num, inst_cnt[line][1]]
		else:
			inst_cnt[line] = [1, line_num, 0]

sorted_cnt = sorted(inst_cnt.items(), key=lambda x:x[1])
print("instruction, cnt, last-line, last-but-one line")
for recored in sorted_cnt:
	print(recored)

