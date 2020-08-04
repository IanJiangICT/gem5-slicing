.global _start
.global exit
.section .text
.balign 4

_start:
	j simpoint_entry

exit:
1:	nop
	j 1b

