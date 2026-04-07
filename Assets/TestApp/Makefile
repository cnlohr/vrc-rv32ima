all : test.png

IMAGEIFY=tooling/imageify
OBJTOH=tooling/objtoh

DEPS:=pistol.h
SRCS:=test.c test.S

CFLAGS:=-nostdlib -static-libgcc -ffunction-sections -fdata-sections -flto -march=rv32im_zicsr -mabi=ilp32 -I/usr/include/newlib -Itooling
LDFLAGS:=-T vrc-rv32im.lds -Wl,--gc-sections -Wl,--print-memory-usage

$(OBJTOH) : tooling/objtoh.c
	tcc -Itooling $^ -o $@

$(IMAGEIFY) : tooling/imageify.c
	tcc -Itooling $^ -o $@

pistol.h : assets/pistol.obj $(OBJTOH)
	$(OBJTOH) $< $@ pistol 4096 1

test.elf : $(SRCS) $(DEPS)
	riscv64-unknown-elf-gcc $(CFLAGS) $(LDFLAGS) $(SRCS) -o $@

test.bin : test.elf
	riscv64-unknown-elf-objdump -S $^ > test.lst
	riscv64-unknown-elf-objdump -t $^ > test.map
	riscv64-unknown-elf-objcopy -O binary $^ $@

test.png : test.bin $(IMAGEIFY)
	$(IMAGEIFY) $< $@

clean :
	rm -rf test.elf test.bin test.lst test.map test.png pistol.h $(OBJTOH) $(IAMGEIFY)

