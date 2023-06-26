; Блок начальной настройки программируемого
; дешифратора
	.phase 0E000h
PROG_PAGE	EQU	0FE00h
	jmp ON_DC
	JMP	LOOP
ON_DC:	MVI A,24H;  Включить режим начального программирования
	OUT -1;     внутренних устройств
	;OUT -1;     Установить пзу в последнее странице FF00H—FFFFH 
	OUT 0E0h
	;OUT 0E1h
	;OUT 0E2h
	;OUT 0E3h
	;OUT 0E4h


	MVI A,10;   Номер линии выбора теневого озу
	OUT 0FEH;   Страницу FE00H—FEFFH перевести в режим озу
	MVI A,0A4H; Включить режим репрограммирования
	OUT -1;     внутренних устройств, повторяя младшие
	      ;     четыре разряда для последней страницы
	;MVI	A,11
	;OUT	0CEh
	;MVI	A,80h
	;STA	0CE00h

	;MVI	A,10
	;OUT	0B5h

	MVI C,ENDPRO-BEGPRO ; Скопировать в предпоследнюю
	LXI H,PROG_PAGE;      страницу, работающую как озу,
	LXI D,BEGPRO;         программу для полного программирования
	LDAX D;               всех внутренних устройств пэвм
	MOV M,A
	INX H
	INX D
	DCR C
	JNZ $-5 ;
	LXI SP,PROG_PAGE+0100H; Установить указатель стека в открытой
	LXI H,PROG_PAGE+1 ; странице, записать в hl адрес операнда
		     ; команды out для обеспечения инкремента
		     ; начинаем с out 00
	LXI	D,MAP
	CALL	LOOP

	MVI A,0A4H  ; В режиме репрограммирования
	OUT -1      ; внутренних устройств перевести
	OUT -2      ; страницу FE00-FEFF в режим пзу
	MVI A,84H   ; Включить рабочий режим
	OUT -1
	MVI A,80H   ; Записать в системный регистр-начальные
	OUT -1      ; значения: турборежим выключен, нулевая
                    ; страница дополнительного озу
	;lxi	h,0cc03h
	;mvi	m,36h
	;mvi	m,76h
	;mvi	m,0b6h

	JMP 0F800h  ; Перейти к программированию контроллеров рк
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
	
	END













