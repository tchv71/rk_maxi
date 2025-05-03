; Блок начальной настройки программируемого
; дешифратора - Апогей БК
	.phase 0100h

RAM	equ	13
RAM2	equ	3
PALM_CNTRL equ	0CE00h;  Palmira control byte
MEM_LO	equ	5
MEM_HI	equ	0dh
FONT_ID	equ	10

@SYSREG	MACRO	VAL
	IN	-1
	MVI	A,VAL
	OUT	-1
	ENDM

	LXI	SP,100H
	CALL	LOAD_FONT

	MVI	A,80H ; Start page
	LXI	D,MAP
	CALL	PROG_DC

	LXI	H,200H
	LXI	D, 0F800h
	LXI	B, 800h
	CALL	MEMCPY

	MVI	A,0f8h
	LXI	D,MAP2
	CALL	PROG_DC

	IN	-1
	MVI	A,80H   ; Включить рабочий режим
	OUT	-1

	JMP 0F800h  ; Перейти к программированию контроллеров рк
LOAD_FONT:
	MVI	A,FONT_ID
	CALL	SET_PORTS_D8
	MVI	A,80H
	STA	PALM_CNTRL
	LXI	H,0A00H
	LXI	D,0D800H
	LXI	B,800h
	CALL	MEMCPY
	MVI	A,MEM_HI+10h
	CALL	SET_PORTS_D8
	MVI	A,0C0h
	STA	PALM_CNTRL
	RET
READR:
	MOV	M,C
BEGPRO:
	OUT 0
	INR M
	DCR B
	RZ
	JMP BEGPRO

PROG_DC:
	PUSH	PSW
	IN	-1	; Обязательное чтение перед записью системного регистра
	MVI	A,0A0H	;  Включить режим репрограммирования
	OUT	-1	;  внутренних устройств
	POP	PSW
	LXI H,BEGPRO+1	; Записать в hl адрес операнда
			; команды out для обеспечения инкремента
	MOV	M,A
LOOP:
	LDAX	D
	ORA	A
	RZ
	MOV	B,A
	INX	D
	LDAX	D
	INX	D
	CALL	BEGPRO
	JMP	LOOP

MEMCPY:
	MOV	A,B
	ORA	C
	RZ
	MOV	A,M
	STAX	D
	INX	H
	INX	D
	DCX	B
	JMP	MEMCPY

SET_PORTS_D8:
	LXI	H,SET_PORTS1+1
	LXI	B,8D8H
	MOV	M,C
	PUSH	PSW
	@SYSREG	0A0H
	POP	PSW
	CALL	SET_PORTS1
	@SYSREG	80H
	RET

SET_PORTS1:
	OUT 0
	INR M
	DCR B
	RZ
	JMP SET_PORTS1

MAP:	DB	40h, RAM
	DB	37h,RAM+10h	; 0000h - F6FFh
	DB	1,15		; F700h - F7FFh	rk60k controller page
	DB	8,RAM+10h,0	; F800h - FFFFh

MAP2:	DB	8,RAM2+10h,0
	
	END













