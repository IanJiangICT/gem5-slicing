# gem5-slicing
Scritps and examples to do slicing based on Gem5 and SimPoint.

Building example applications:

    $ cd tests/
    $ make
    riscv64-unknown-linux-gnu-gcc -static -march=rv64g -o hello hello.c
    riscv64-unknown-linux-gnu-gcc -static -march=rv64g -o hannoi hannoi.c
    $ make check
    readelf -h hello hannoi | grep Flags
      Flags:                             0x4, double-float ABI
      Flags:                             0x4, double-float ABI
    file hello hannoi
    hello:  ELF 64-bit LSB executable, UCB RISC-V, version 1 (SYSV), statically linked, for GNU/Linux 4.15.0, with debug_info, not stripped
    hannoi: ELF 64-bit LSB executable, UCB RISC-V, version 1 (SYSV), statically linked, for GNU/Linux 4.15.0, with debug_info, not stripped
    $ cd ..
    $ cp tests/hello slicing/hello/hello
    $ cp tests/hannoi slicing/hannoi/hannoi

Making checkpoints and slices:

    $ ./scripts/make-checkpoint.sh --help
    Usage:
      ./scripts/make-checkpoint.sh application

    $ ./scripts/make-slice.sh --help
    Usage:
      ./scripts/make-slice.sh application [checkpoint-num]
    Example:
      ./scripts/make-slice.sh hello   # for all checkpoints
      ./scripts/make-slice.sh hello 1 # for single checkpoint: the 1st one
