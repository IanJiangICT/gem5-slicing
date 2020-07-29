CC=riscv64-unknown-linux-gnu-gcc
CFLAGS=-static
CFLAGS+=-march=rv64g

tests=hello
tests+=hannoi

all: ${tests}

default: all

%:%.c
	${CC} ${CFLAGS} -o $@ $^

check: ${tests}
	readelf -h $^ | grep Flags
	file $^

clean:
	rm -f ${tests}
