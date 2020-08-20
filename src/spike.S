.global _start
.global exit
.section .text
.balign 4

_start:
	# Enable floating-point
	csrr t0, mstatus
	li t1, 0x2000
	or t0, t0, t1
	csrw mstatus, t0
	j simpoint_entry

exit:
1:	nop
	j 1b

