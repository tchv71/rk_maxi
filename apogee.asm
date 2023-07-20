; Блок начальной настройки программируемого
; дешифратора - Апогей БК
	.phase 0100h

	MVI	A,0C4h
	OUT	-1 ; Turn on external device programming mode (for in/out commands)
	LXI	H,BEGPRO+1
	LXI	B,0FE00h
	MVI	A,15
	CALL	READR
	CALL	LOOP01 ; Turn on working mode

	MVI	A,80H ; Start page
	LXI	D,MAP
	CALL	PROG_DC
	MVI	A,0AAH
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

	;MVI	A,0AAH
	;OUT	-1
	MVI	A,0BAH
	OUT	-1
	MVI	A,9AH   ; Включить рабочий режим
	OUT	-1
	MVI	A,80h
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
	MVI A,0AAH;  Включить режим репрограммирования
	OUT -1;     внутренних устройств
	POP	PSW
	LXI H,BEGPRO+1 ; Записать в hl адрес операнда
		     ; команды out для обеспечения инкремента
		     ; начинаем с out 80H
	MOV	M,A
LOOP:
	LDAX	D
	ORA	A
	JZ	LOOP01
	MOV	B,A
	INX	D
	LDAX	D
	INX	D
	CALL	BEGPRO
	JMP	LOOP
LOOP01:
	;MVI A,8AH   ; Включить рабочий режим
	;OUT -1
	;MVI A,80H   ; Записать в системный регистр-начальные
	;OUT -1      ; значения: турборежим выключен, нулевая
                    ; страница дополнительного озу
	RET

MAP:	DB	60h,10 ; // E000
	DB	12, 10 ; // E000-EBFF
	DB	1,6, 1,0, 1,1 ,1,2
	DB	15,10,0

MAP2:	DB	8,3,7,1Ah,0
	
	END













