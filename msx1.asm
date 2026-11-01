; Блок начальной настройки программируемого
; дешифратора - MSX1
	.phase 0100h

RAM	equ	5+80h;0dh

	LXI	SP,100H
	CALL	SETMAINROM
	JMP	0E00h


SETMAINROM:
	MVI	A,90H ; Start page
	LXI	D,MAP
	CALL	SETMAP

	LXI	H,180H
	LXI	D, 9000h
	LXI	B, 4000h
	CALL	MEMCPY

	MVI	A,90h
	LXI	D,MAP2
	CALL	SETMAP

	LXI	D, 9000h
	LXI	B, 4000h
MEMCPY:
	MOV	A,M
	STAX	D
	INX	H
	INX	D
	DCX	B
	MOV	A,B
	ORA	C
	JNZ	MEMCPY
	RET
READR:
	MOV	M,C
BEGPRO:
	OUT 0
	INR M
	DCR B
	RZ
	JMP BEGPRO

SETMAP:	PUSH	H
	CALL	PROG_DC
	POP	H
	IN	-1
	MVI	A,80h
	OUT	-1
	RET

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

MAP:	DB	40h,RAM	; 9000h - BFFFh
	DB	0

MAP2:	DB	40h,RAM+10h	; 8000h - BFFFh
	DB	0
	
	END













