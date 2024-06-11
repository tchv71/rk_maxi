M80PATH=D:/M80
PORT=COM2:

.SUFFIXES: .ASM .REL .BIN

init1.REL: init1.asm
	$(M80PATH)/M80 '=$< /I/L'

.asm.REL:
	$(M80PATH)/M80 '=$< /I/L'

clean:
	del *.REL
	del *.PRN
	del *.BIN
	del *.NoiCtx

all: init1.rkl init2.BIN RomCopy.BIN apogee.rkl port.rkl memtest.rkl

init1.rkl: init1.BIN

port.rkl: port.BIN
	../makerk/Release/makerk.exe 100 $< $@

.BIN.rkl:
	../makerk/Release/makerk.exe 100 $< $@


.REL.BIN:
	$(M80PATH)/L80 /P:100,$<,$@/N/Y/E

apogee.rkl: apogee.BIN
	copy /B apogee.BIN+apogey.rom apogee.BIN
	../makerk/Release/makerk.exe 100 $< $@

send: apogee.rkl
	MODE $(PORT) baud=115200 parity=N data=8 stop=1
	cmd /C copy /B $< $(PORT)

memtest.rkl: memtest.BIN
	../makerk/Release/makerk.exe 80 $< $@
