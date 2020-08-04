.global _start
.global exit
.section .text
.balign 4

exit:
1:	nop
	j 1b

_start:
	j simpoint_entry
