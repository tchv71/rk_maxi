; Блок начальной настройки программируемого
; дешифратора - Апогей БК
	.phase 0100h

RAM	equ	0dh
RAM2	equ	3

	LXI	SP,100H
	IN	-1	; Обязательное чтение перед записью системного регистра
	MVI	A,0C0h
	OUT	-1	; Turn on external device programming mode (for in/out commands)
	;LXI	H,BEGPRO+1
	;LXI	B,0000h
	;MVI	A,15
	;CALL	READR

	MVI	A,80H ; Start page
	LXI	D,MAP
	CALL	PROG_DC
	MVI	A,RAM
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
	MVI	A,RAM2
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

MAP:	DB	40h,RAM	; 0000h - DFFFh
	DB	20h+12, RAM+10h ; E000h - EBFFh
	DB	1,6	; EС00h - EСFFh	Генератор звука КР580ВИ53
	DB	1,0	; ED00h - EDFFh	Интерфейс клавиатуры и магнитофона КР580ВВ55
	DB	1,1	; EE00h - EEFFh	Интерфейс пользователя КР580ВВ55
	DB	1,2	; EF00h - EFFFh	Контроллер дисплея КР580ВГ75
	DB	16,RAM+10h,0

MAP2:	DB	16,RAM2+10h,0
	
	END













