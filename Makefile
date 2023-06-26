M80PATH=D:/M80

.SUFFIXES: .ASM .REL .BIN

init1.REL: init1.asm
	$(M80PATH)/M80 '=$< /I/L'

.asm.REL:
	$(M80PATH)/M80 '=$< /I/L'

clean:
	del *.REL
	del *.PRN
	del *.BIN

all: init1.rkl init2.BIN

init1.rkl: init1.BIN

.BIN.rkl:


.REL.BIN:
	$(M80PATH)/L80 /P:100,$<,$@/N/Y/E

