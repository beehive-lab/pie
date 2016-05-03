CC=$(CROSS_COMPILE)gcc
CFLAGS= -Os -Wall -g -std=c99
LDFLAGS=-Wl,-z,execstack

.SECONDARY:
.PHONY: pie clean

all:
	make ARCH=arm pie
	make ARCH=thumb pie

pie: pie-$(ARCH)-decoder.o pie-$(ARCH)-encoder.o pie-$(ARCH)-field-decoder.o

pie-$(ARCH)-%.o: pie-$(ARCH)-%.c pie-$(ARCH)-%.h
	$(CC) -c $(CFLAGS) $< -o $@

pie-$(ARCH)-%.h: generate_%.rb $(ARCH).txt
	ruby $< $(ARCH) header > $@

pie-$(ARCH)-%.c: generate_%.rb $(ARCH).txt
	ruby $< $(ARCH) > $@

clean:
	rm -f *.o pie-arm-*.h pie-thumb-*.h pie-*.c

