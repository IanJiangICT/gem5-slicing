OUTPUT_ARCH( "riscv" )
OUTPUT_FORMAT("elf64-littleriscv")
ENTRY( _start )
SECTIONS
{
  /* text: test code section */
  . = 0x80000000;
  stack_base = .;
  .text : { *(.text) }
  /* data: Initialized data segment */
  .data : { *(.data) }
  .rodata : { *(.rodata) }
  .sdata : { *(.sdata) }
  .debug : { *(.debug) }

  /* End of uninitalized data segement */
  _end = .;
}
