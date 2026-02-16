	.phase	ORGB
	.8080
PROG_PAGE	EQU	0FE00h
	jmp ON_DC
	JMP	LOOP
ON_DC:
	LXI	B,8000h
	DCX	B
	XTHL
	XTHL
	MOV	A,B
	ORA	C
	JNZ	$-5

	IN	-1	; Обязательное чтение перед записью системного регистра

	MVI	A,20H	; Включить режим начального программирования
	OUT	-1		; внутренних устройств

	MVI	A,4	; Включить ПЗУ E000H-E0FFH
	OUT	0E0h

	MVI A,13+10h	; Номер линии выбора теневого озу
	OUT 0FEH	; Страницу FE00H—FEFFH перевести в режим озу

	IN	-1	; Обязательное чтение перед записью системного регистра
	MVI	A,80H	; Записать в системный регистр-начальные
	OUT	-1	; значения

	MVI C,ENDPRO-BEGPRO	; Скопировать в предпоследнюю
	LXI H,PROG_PAGE		; страницу, работающую как озу,
	LXI D,BEGPRO		; программу для полного программирования
	LDAX D			; всех внутренних устройств пэвм
	MOV M,A
	INX H
	INX D
	DCR C
	JNZ $-5 ;

	IN	-1
	MVI	A,0C0h
	OUT	-1

	LXI SP,PROG_PAGE+0100H	; Установить указатель стека в открытой
	;LXI	H,PROG_PAGE+1	; странице, записать в hl адрес операнда
	;XRA	A
	;MOV	M,A
	;MOV	B,A
	;MVI	A,15
	;CALL	PROG_PAGE
	MVI	A,14
	OUT	VDP
	OUT	VDP+1

	IN	-1	; Обязательное чтение перед записью системного регистра
	MVI	A,0A0H	; Включить режим репрограммирования
	OUT	-1	; внутренних устройств, повторяя младшие
			; четыре разряда для последней страницы

	LXI H,PROG_PAGE+1
				; команды out для обеспечения инкремента
				; начинаем с out 00
	LXI	D,MAP
	CALL	LOOP

	MVI	A,4
	OUT	-2
	OUT	-1

	IN	-1	; Обязательное чтение перед записью системного регистра
	MVI	A,80H	; Записать в системный регистр-начальные
	OUT	-1	; значения

	; Загрузка конфигурации Апогея или CP/M
	; Ctrl - Апогей
	; Shift - CP/M
	LXI	SP,0D800H
	MVI	A,90h
	STA	0C403h
	MVI	A,8Ah
	STA	0C203H
	LDA	0C202H
	ANI	060H
	JZ	ROM2
	MOV	C,A
	ANI	040H
	LXI	D,APOGEE
	JZ	LOAD
	MOV	A,C
	ANI	20H
	LXI	D,CPM
	JNZ	INTR_INIT

LOAD:
	MVI	A,3
	PUSH	D
	CALL	0F003H
	POP	D
	JNZ	INTR_INIT ; Инициализировать прерывание
	CALL	EXEC_A
	; Управление будет тут если вызов не удался
	JMP	INTR_INIT ; 

ROM2:	IN	-1
	MVI	A,0A0H
	OUT	-1

	MVI	A,13+10h
	OUT	0FEh

	JMP	PROG_PAGE + ROM2P - BEGPRO

EXEC_A:
	PUSH	H
	MVI	A,0
	XCHG
	LXI	D,EMPTY
	RET

BEGPRO:
	OUT 0
	INR M
	DCR B
	RZ
	JMP PROG_PAGE

ROM2P:	LXI	H,PROG_PAGE+1
	MVI	M,0E0h
	MVI	A,24h
	MVI	B,30
	CALL	PROG_PAGE
	OUT	0FEh
	OUT	0FFh


	IN	-1
	MVI	A,080H
	OUT	-1
	JMP	0F800h

ENDPRO:

LOOP:
	LDAX	D
	ORA	A
	RZ
	MOV	B,A
	INX	D
	LDAX	D
	INX	D
	CALL	PROG_PAGE
	JMP	LOOP
; Коды дешифратора:
; 0	- 0C200h - ВВ55 - 1
; 1	- 0C400h - ВВ55 - 2
; 2	- 0C000h - ВГ75
; 3	-	Memory R/O
; 4	-	ROM
; 5	-	Memory < 32K
; 6	- 0CC00h - ВИ53 - 1
; 7	- 0C600h - ВТ57
; 8	- 0C800h - ВИ53 - 2
; 9	- 0C100h - SD_CNTR - контроллер SD-карточки
;10	-	ЗГ RAM
;11	- 0CE00h - ТМ9 (Palmira Control Byte)
;12	- 0C300h - PI_SD
;13	-	Memory >= 32K
;14	- 0C500h - VDP TMS9918A
;14	- 0CA00h
;15	- 0F700h - RK60K Ports
MAP:	DB	1,5,3fh,5,40h,15h,40h,13
	DB	1,2  ; 0C000h - ВГ75
	DB	1,9  ; 0C100h - SD_CNTR - контроллер SD-карточки
IFDEF KBD_EMU
	DB	1,9;0  ; 0C200h - ВВ55 - 1
ELSE
	DB	1,0  ; 0C200h - ВВ55 - 1
ENDIF
	DB	1,12 ; 0C300h - PI_SD
	DB	1,1  ; 0C400h - ВВ55 - 2
	DB	1,14 ; 0C500h - VDP TMS9918A
	DB	2,7  ; 0C600h - ВТ57
	DB	2,8  ; 0C800h - ВИ53 - 2
	DB	2,14 ; 0CA00h - VDP TMS9918A
	DB	2,6  ; 0CC00h - ВИ53 - 1
	DB	2,11 ; 0CE00h - ТМ9  (Palmira Control Byte)
	DB	8,13+10h,8,10,30,4,0

APOGEE:
	DB	"APOGEE.RKL"
EMPTY:	DB	0
CPM:	DB	"CPM/CPM.RKL",0

INTR_INIT:
IF 0
	LXI	H,E0F8
	LXI	D,38h
	MVI	C,07
E0CD:	MOV	A,M
	STAX	D
	INX	H
	INX	D
	DCR	C
	JNZ	E0CD
ENDIF
	.Z80
	im	1
	.8080
	DI
	JMP	ORGB+1800h
IF 0
E0F8:
	PUSH	PSW
	LDA	VG_75+1
	POP	PSW
IFDEF INT_ENABLE
	EI
ENDIF
	RET
ENDIF
