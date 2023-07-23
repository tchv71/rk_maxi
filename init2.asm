; Блок начальной настройки программируемого
; дешифратора
	.phase 0e000h
PROG_PAGE	EQU	0FE00h
	jmp ON_DC
	JMP	LOOP
ON_DC:	IN	-1	; Обязательное чтение перед записью системного регистра
	MVI	A,20H	; Включить режим начального программирования
	OUT	-1		; внутренних устройств

	MVI	A,4	; Включить ПЗУ E000H-E0FFH
	OUT	0E0h

	MVI A,10	; Номер линии выбора теневого озу
	OUT 0FEH	; Страницу FE00H—FEFFH перевести в режим озу

	IN	-1	; Обязательное чтение перед записью системного регистра
	MVI	A,0A0H	; Включить режим репрограммирования
	OUT	-1	; внутренних устройств, повторяя младшие
			; четыре разряда для последней страницы

	MVI C,ENDPRO-BEGPRO	; Скопировать в предпоследнюю
	LXI H,PROG_PAGE		; страницу, работающую как озу,
	LXI D,BEGPRO		; программу для полного программирования
	LDAX D			; всех внутренних устройств пэвм
	MOV M,A
	INX H
	INX D
	DCR C
	JNZ $-5 ;

	LXI SP,PROG_PAGE+0100H	; Установить указатель стека в открытой
	LXI H,PROG_PAGE+1	; странице, записать в hl адрес операнда
				; команды out для обеспечения инкремента
				; начинаем с out 00
	LXI	D,MAP
	CALL	LOOP

	MVI	A,4
	OUT	-2
	OUT	-1

	IN	-1	; Обязательное чтение перед записью системного регистра
	MVI	A,80H	; Записать в системный регистр-начальные
	OUT	-1	; значения: турборежим выключен, нулевая
			; страница дополнительного озу

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
	MOV	C,A
	ANI	040H
	LXI	D,APOGEE
	JZ	LOAD
	MOV	A,C
	ANI	20H
	LXI	D,CPM
	JNZ	0F800H

LOAD:
	MVI	A,3
	PUSH	D
	CALL	0F003H
	POP	D
	JNZ	0F800h
	CALL	EXEC_A
	; Управление будет тут если вызов не удался
	JMP 0F800h  ; Перейти к программированию контроллеров рк

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

MAP:	DB	80h,5,40h,10
	DB	2,2,2,0,2,1,2,7,2,8,2,10,2,6,2,11
	DB	8,10,8,13,30,4,0
APOGEE:
	DB	"APOGEE.RKL"
EMPTY:	DB	0
CPM:	DB	"CPM/CPM.RKL",0
	END













