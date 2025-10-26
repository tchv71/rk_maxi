; Блок начальной настройки программируемого
; дешифратора
@SYSREG	MACRO	VAL
        IN	-1
        MVI	A,VAL
        OUT	-1
        ENDM

	.phase	100H
	@SYSREG	0A0h
	MVI	A,9
	OUT	0C4H
	@SYSREG	80h
	;RET
	JMP	0F86Ch

	END













