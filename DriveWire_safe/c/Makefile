vpath %.c .

CFLAGS += -g -DLINUX
LDLIBS	+= -lcurses -lpthread -g

drivewire: drivewire.o dwprotocol.o dwwin.o

clean:
	rm drivewire *.o

install: drivewire
	cp drivewire /usr/local/bin
