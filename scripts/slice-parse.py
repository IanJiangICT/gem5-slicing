#!/usr/bin/python3

import sys
import os
import re
import copy

class SliceData:
	def __init__(self):
		self.reg_int = []
		self.reg_float= []
		self.stack_data = []
		self.stack_base = 0
		self.stack_max_size = 0
		self.stack_sp_top = 0
		self.stack_sp_bottom = 0
		self.vma_list_start = []
		self.vma_list_end = []
		self.vma_list_name = []
		self.mem_init_addr = []
		self.mem_init_data = []

	def printOut(self):
		for i in range(0, len(self.reg_int)):
			print("reg_int " + str(i) + " " + hex(self.reg_int[i]))
		for i in range(0, len(self.reg_float)):
			print("reg_float " + str(i) + " " + hex(self.reg_float[i]))
		for i in range(0, len(self.stack_data)):
			print("stack_data " + str(i) + " " + hex(self.stack_data[i]))
		for i in range(0, len(self.vma_list_name)):
			print("vma " + str(i) + " " + self.vma_list_name[i] + " " \
					+ hex(self.vma_list_start[i]) + " " + hex(self.vma_list_end[i]))
		for i in range(0, len(self.mem_init_addr)):
			print("mem " + str(i) + " " + hex(self.mem_init_addr[i]) + " " + hex(self.mem_init_data[i]))

class SliceParse:
	'''Parse a slice output by Gem5 and give target source codes'''

	FLAG_START_REG_INT= "simpoint_gen_reg_int:"
	FLAG_START_REG_FLOAT = "simpoint_gen_reg_float:"
	FLAG_START_STACK_DATA = "simpoint_stack_top:"
	FLAG_START_VMA_LIST = "/* VMA list */"
	FLAG_START_MEM_INIT = "/* Address-Value pairs */"

	def __init__(self, slice_fd):
		self.slice_fd = slice_fd
		self.slice_data = SliceData()
		self.slice_data_update = SliceData()
		self.slice_text = []

	def parse_reg_int(self):
		slice_fd = self.slice_fd
		data_list = []
		while (True):
			slice_line = slice_fd.readline()
			if (not slice_line):
				break
			slice_line = slice_line.strip('\n')
			line_words = slice_line.split(' ')
			if (len(line_words) < 6):
				break
			if (line_words[4] != ".dword"):
				break
			data_list.append(int(line_words[5], 16))
		self.slice_data.reg_int = data_list

	def parse_reg_float(self):
		self.slice_data.reg_float = []
	
	def parse_stack(self):
		slice_fd = self.slice_fd
		# Stack data is at the begining
		data_list = []
		while (True):
			slice_line = slice_fd.readline()
			if (not slice_line):
				break
			slice_line = slice_line.strip('\n')
			line_words = slice_line.split(' ')
			if (len(line_words) < 6):
				break
			if (line_words[4] != ".dword"):
				break
			data_list.append(int(line_words[5], 16))
		self.slice_data.stack_data = data_list

		# The following is other information of format #define
		while (True):
			slice_line = slice_fd.readline()
			if (not slice_line):
				break	
			slice_line = slice_line.strip('\n')
			if (len(slice_line) == 0):
				break
			line_words = slice_line.split(' ')
			if (len(line_words) != 3):
				continue
			if (line_words[0] != "#define"):
				continue
			if (line_words[1] == "SIMPOINT_STACK_BASE"):
				self.slice_data.stack_base = int(line_words[2], 16)
			elif (line_words[1] == "SIMPOINT_STACK_MAX_SIZE"):
				self.slice_data.stack_max_size = int(line_words[2], 16)
			elif (line_words[1] == "SIMPOINT_STACK_SP_TOP"):
				self.slice_data.stack_sp_top = int(line_words[2], 16)
			elif (line_words[1] == "SIMPOINT_STACK_SP_BOTTOM"):
				self.slice_data.stack_sp_bottom = int(line_words[2], 16)

	def parse_vma_list(self):
		slice_fd = self.slice_fd
		while (True):
			slice_line = slice_fd.readline()
			if (not slice_line):
				break
			slice_line = slice_line.strip('\n')
			line_words = slice_line.split(' ')
			if (len(line_words) != 6):
				break
			sub_words = line_words[0].split('-')
			if (len(sub_words) != 2):
				break
			if (len(line_words[5]) < 3): # Min. VMA name is "[?]"
				break
			self.slice_data.vma_list_start.append(int("0x" + sub_words[0], 16))
			self.slice_data.vma_list_end.append(int("0x" + sub_words[1], 16))
			self.slice_data.vma_list_name.append(line_words[5][1:-1])
	
	def parse_mem_init(self):
		slice_fd = self.slice_fd
		while (True):
			slice_line = slice_fd.readline()
			if (not slice_line):
				break
			slice_line = slice_line.strip('\n')
			line_words = slice_line.split(' ')
			if (len(line_words) != 2):
				break
			self.slice_data.mem_init_addr.append(int(line_words[0], 16))
			self.slice_data.mem_init_data.append(int(line_words[1], 16))

	def parse_text_line(self, slice_line):
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
		self.slice_text.append(output_line)

	def parse(self):
		slice_fd = self.slice_fd
		while (True):
			slice_line = slice_fd.readline()
			if (not slice_line):
				break
			slice_line = slice_line.strip('\n')

			if (len(slice_line) <= 0):
				continue
			elif (slice_line.find(self.FLAG_START_REG_INT) == 0):
				print("Dectecting register integer...")
				self.parse_reg_int()
				continue
			elif (slice_line.find(self.FLAG_START_REG_FLOAT) == 0):
				print("Dectecting register float...")
				self.parse_reg_float()
				continue
			elif (slice_line.find(self.FLAG_START_STACK_DATA) == 0):
				print("Dectecting stack...")
				self.parse_stack()
				continue
			elif (slice_line.find(self.FLAG_START_VMA_LIST) == 0):
				print("Dectecting VMA list...")
				self.parse_vma_list()
				continue
			elif (slice_line.find(self.FLAG_START_MEM_INIT) == 0):
				print("Dectecting memory initial...")
				self.parse_mem_init()
				continue
			else:
				self.parse_text_line(slice_line)
				continue

	def reconstruct(self):
		# Make a copy of slice data to make update
		self.slice_data_update = copy.deepcopy(self.slice_data)
		# Build new VMA list
		# Update stack and memory information

		print("== Slice Data Original ==")
		self.slice_data.printOut()
		print("== Slice Data Updated ==")
		self.slice_data_update.printOut()
		for l in self.slice_text:
			print(l)

	def output(self):
		print("TODO SliceParse::output()")


def usage():
		print("Usage:");
		print("    " + sys.argv[0] + " slice-file");

def main():
	if (len(sys.argv) < 2):
		usage()
		sys.exit(2)
		
	slice_file = sys.argv[1]
	print("Open slice file", slice_file)
	try:
		slice_fd = open(slice_file, 'r')
	except IOError:
		print("Failed to open slice file", slice_file)
		sys.exit(2)
	
	print("Start process")
	parser = SliceParse(slice_fd)
	parser.parse()
	parser.reconstruct()
	parser.output()

if __name__== "__main__":
	main()
