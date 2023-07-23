; Блок начальной настройки программируемого
; дешифратора - Апогей БК
	.phase 0100h


	LXI	SP,100H
	IN	-1	; Обязательное чтение перед записью системного регистра
	MVI	A,0C0h
	OUT	-1	; Turn on external device programming mode (for in/out commands)
	LXI	H,BEGPRO+1
	LXI	B,0000h
	MVI	A,15
	CALL	READR

	MVI	A,80H ; Start page
	LXI	D,MAP
	CALL	PROG_DC
	MVI	A,10
	OUT	-1

	LXI	H,180H
	LXI	D, 0F000h
	LXI	B, 1000h
CP001:
	MOV	A,M
	STAX	D
	INX	H
	INX	D
	DCX	B
	MOV	A,B
	ORA	C
	JNZ	CP001

	MVI	A,0f0h
	LXI	D,MAP2
	CALL	PROG_DC
	MVI	A,1Ah
	OUT	-1

	IN	-1
	MVI	A,80H   ; Включить рабочий режим
	OUT	-1

	JMP 0F800h  ; Перейти к программированию контроллеров рк
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

MAP:	DB	60h,10 ; // E000
	DB	12, 10 ; // E000-EBFF
	DB	1,6, 1,0, 1,1 ,1,2
	DB	15,10,0

MAP2:	DB	8,3,7,1Ah,0
	
	END













