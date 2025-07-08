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

all: init1.rkl init2.BIN RomCopy.BIN apogee.rkl port.rkl memtest.rkl SDDMA.rkl boot.rkl sdbios.rkl write.rkl 9918test.rkl sprite.rkl 9918txt.rkl rk60k.rkl bootRom.rkl MON580.rkl

init1.rkl: init1.BIN

boot.BIN: boot.REL

boot.REL: boot.asm

SDDMA.BIN: SDDMA.REL

sdbios.REL: sdbios.asm DmaIo.asm

sdbios.BIN: sdbios.REL

write.REL: write.asm

write.BIN: write.rel

port.rkl: port.BIN
	../makerk/Release/makerk.exe 100 $< $@

.BIN.rkl:
	../makerk/Release/makerk.exe 100 $< $@


.REL.BIN:
	$(M80PATH)/L80 /P:100,$<,$@/N/Y/E

apogee2.BIN: apogey.rom apogee.BIN
	copy /B apogee.BIN+apogey.rom apogee2.BIN

apogee.rkl: apogee2.BIN
	../makerk/Release/makerk.exe 100 $< $@

rk60k2.BIN: rk60k.rom rk60k.BIN
	copy /B rk60k.BIN+rk60k.rom+8X16eng.FNT rk60k2.BIN

rk60k.rkl: rk60k2.BIN
	../makerk/Release/makerk.exe 100 $< $@

send: apogee.rkl
	MODE $(PORT) baud=115200 parity=N data=8 stop=1
	cmd /C copy /B $< $(PORT)

memtest.rkl: memtest.BIN
	../makerk/Release/makerk.exe 80 $< $@

SDDMA.rkl: SDDMA.BIN
	../makerk/Release/makerk.exe 80 $< $@

boot.rkl: boot.BIN
	../makerk/Release/makerk.exe 0 $< $@

sdbios.rkl: sdbios.bin
	../makerk/Release/makerk.exe D280 $< $@

write.rkl: write.bin
	../makerk/Release/makerk.exe 100 $< $@

9918test.REL: 9918test.asm 9918.asm 9918font.asm

9918test.BIN: 9918test.rel


9918test.rkl: 9918test.bin
	../makerk/Release/makerk.exe 100 $< $@

sprite.REL: sprite.asm tms.asm utility.asm z180.asm

sprite.BIN: sprite.rel


sprite.rkl: sprite.bin
	../makerk/Release/makerk.exe 100 $< $@


9918txt.REL: 9918txt.asm 9918.asm 9918font.asm

9918txt.BIN: 9918txt.rel

9918txt.rkl: 9918txt.bin
	../makerk/Release/makerk.exe 100 $< $@

#bootRom.BIN: bootRom.REL

#bootRom.REL: bootRom.asm

#bootRom.rkl: bootRom.BIN
#	../makerk/Release/makerk.exe 8600 $< $@

MON580.REL: MON580.ASM F8X16.asm MonRKRom.asm bootRom.asm sdbiosR.asm SendRcv.asm init2R.asm

MON580.BIN: MON580.REL

MON580.rkl: MON580.BIN
	../makerk/Release/makerk.exe 8000 $< $@
	../m80noi/x64/Release/m80noi.exe mon580.prn
