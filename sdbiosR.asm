; SD BIOS for Computer "Radio 86RK"
; (c) 09-10-2014 vinxru (aleksey.f.morozov@gmail.com)
; (c) 24-10-2024 tchv aka Dmitry Tsvetkov (tchv71@mail.ru)


;----------------------------------------------------------------------------

INIT_VIDEO	EQU  F82DH
INIT_STACK	EQU  0D800h

; MC codes
STA_START	EQU 040h ; MC switched to command receive mode
STA_WAIT	EQU 041h ; MC is executing command
STA_OK_DISK	EQU 042h ; The drive is working, MC is ready to receive command
STA_OK_CMD	EQU 043h ; Command is executed
STA_OK_READ	EQU 044h ; MC is ready to transfer next data block
STA_OK_ENTRY	EQU 045h ; MC is ready to transfer file record
STA_OK_WRITE	EQU 046h ; MC is waiting for next data block (for write)
STA_OK_ADDR	EQU 047h ; MC is ready to send loading address
STA_OK_BLOCK	EQU 04Fh 

VER_BUF		EQU  SDBBUF
	JMP	SdBiosEntry
;----------------------------------------------------------------------------
; RK file header

	db (BiosEntry) AND 0FFh, (BiosEntry) SHR 8 
	
;----------------------------------------------------------------------------

SdBiosEntry:
IF 0
	; Set free memory border
	;LXI	H, SELF_NAME
	;CALL	0F833h

	; Output controller name
	LXI	H, aHello
	CALL	F818h

	; Output controller version
	CALL	PrintVer

	; Line feed
	lxi	h, aCrLf
	CALL	F818h
ENDIF
	; Execute SHELL.RK without command line
	LXI	H, aShellRk
	LXI	D, aEmpty
	CALL	CmdExec
	PUSH	PSW

	; Ошибка - файл не найден
	CPI	04h
	JNZ 	Error2

	; Output message "ФАЙЛ НЕ НАЙДЕН BOOT/SHELL.RK"
	LXI	H, aErrorShellRk
	CALL	F818h
	JMP	$
F818h:
	;JMP	0f818h
	RET
F815h:
	;JMP	0f815h
	RET
F809h:
	;JMP	0f809h
	RET
F82Dh:
	;JMP	0f82dh
	RET

;----------------------------------------------------------------------------

PrintVer:
	; Команда получения версии
	MVI	A, 1
	CALL	StartCommand	; Лишний такт в котором пропустим версию

IFNDEF USE_DMA
	CALL	SwitchRecv
ENDIF
	
	; Получаем версию набора команд и текст
	;LXI	D, VER_BUF
	CALL	RecvSD;Block2
	
	; Вывод версии железа
	;XRA	A
	;STA	SDBUF_SIZE

	STA	VER_BUF+17+2

	LXI	H, VER_BUF+1+2
	JMP 	F818h

;----------------------------------------------------------------------------

aHello:		db 13,10,"SDB",0;"SD BIOS V1.1",13,10
aSdController:  db 0;"SD DMA CONTROLLER ",0
aCrLf:		db 13,10,0
aErrorShellRk:  db "fajl ne najden "
aShellRk:	db "BOOT/SHELL.RK",0
		;db "(c) 04-05-2014 vinxru, 2024-25 (c) tchv"

; Код ниже будет затерт ком строкой и собственым именем

SELF_NAME	EQU 0d000h;$-512 ; путь (буфер 256 байт)
CMD_LINE	EQU SELF_NAME+256; $-256 ; команданая строка 256 байт

;----------------------------------------------------------------------------
; SD BIOS resident part
;----------------------------------------------------------------------------

aError:		db "SD ERROR"
aEmpty:		db 0

;----------------------------------------------------------------------------
; Here we restore what been damaged during failure

ErrorSD:
	; Stack init
	LXI	SP, INIT_STACK

	; Save error code
	PUSH	PSW

	CALL	CLS_INIT_VDP

Error2:
	; Output text "SD ERROR"
	LXI	H, aError
	CALL	F818h

	; Output error code
	POP	PSW
	CALL	F815h

	; Hangs
	JMP	$

CLS_INIT_VDP:
	; Screen clear
	; First, we need to delete all special symbols othervice sync may be corrupted
	MVI	C, 1Fh
	CALL	F809h
	; And then reset video controller
	JMP	INIT_VIDEO
;----------------------------------------------------------------------------

BiosEntry:
	PUSH	H
	LXI	H, JmpTbl
	ADD	A
	ADD	L
	MOV	L, A
	JNC	BE01
	INR	H
BE01:
	MOV	A,M
	INX	H
	MOV	H, M
	MOV	L, A
	XTHL
	RET

; File open modes
O_OPEN		EQU	0
O_CREATE	EQU	1
O_MKDIR		EQU	2
O_DELETE	EQU	100
O_SWAP		EQU	101

;----------------------------------------------------------------------------
; JmpTbl transitions do not have to be within the same page
JmpTbl:
	dw CmdExec		; 0 HL-file name, DE-command line / A-error code
	dw CmdFind		; 1 HL-file name, DE-maximum number of files to load, BC-address / HL-how much was loaded, A-error code
	dw CmdOpenDelete	; 2 D-mode, HL-file name / A-error code
	dw CmdSeekGetSize	; 3 B-mode, DE:HL-position / A-error code, DE:HL-position
	dw CmdRead		; 4 HL-size, DE-address / HL-how much was loaded, A-error code
	dw CmdWrite		; 5 HL-size, DE-address / A-error code
	dw CmdMove		; 6 HL-from, DE-to / A-error code

;----------------------------------------------------------------------------
; HL-path, DE-maximum number of files to load, BC-address / HL-how much was loaded, A-error code

CmdFind:
	; Command code
	MVI	A, 3
	CALL	StartCommand

	; Path
	CALL	SendString

	; Files maximum
	XCHG
	CALL	SendWord

IFNDEF USE_DMA
	; Switch to receive mode
	CALL	SwitchRecv
ENDIF

	; Counter
	LXI	H, 0

CmdFindLoop:
	; Wait for MC will read
	CALL	WaitForReady
	CPI	STA_OK_CMD
	JZ	Ret0
	CPI	STA_OK_ENTRY
	RNZ;	EndCommand

	; Receive data block
	LXI	D, 20	; Block length
	CALL	RecvBlock

	; Increment file counter
	INX	H

	; Loop
	JMP	CmdFindLoop
ERR_DATETIME	EQU	50H

; IN and OUT MACRO comands
@in	MACRO	addr
IF ((addr) LT 256)
	in	addr
ELSE
	lda	addr
ENDIF
	ENDM

@out	MACRO	addr
IF ((addr) LT 256)
	out	addr
ELSE
	sta	addr
ENDIF
	ENDM


;----------------------------------------------------------------------------
; D-mode, HL-file name / A-error code

CmdOpenDelete: 
	; Command code
	MVI	A, 4
	CALL	StartCommand

	; Mode
	MOV	A, D
	CALL	SendByte

	; File name
	CALL	SendString

	; Wait for MC will be ready
	CALL	SwitchRecvAndWait
	CPI	STA_OK_CMD
	JZ	Ret0
IFDEF USE_DMA
	ret
ELSE
	JMP	EndCommand
ENDIF
;----------------------------------------------------------------------------
; B-mode, DE:HL-position / A-error code, DE:HL-position

CmdSeekGetSize:
	; Command code
	MVI 	A, 5
	CALL	StartCommand

	; Mode
	MOV	A, B
	CALL	SendByte

	; Position
	CALL	SendWord
	XCHG
	CALL	SendWord

	; Wait for MC will be ready. Should answer with STA_OK_CMD code
	CALL	SwitchRecvAndWait
	CPI	STA_OK_CMD
IFDEF USE_DMA
	RNZ
ELSE
	JNZ	EndCommand
ENDIF
	; File size
	CALL	RecvWord
	XCHG
	CALL	RecvWord

	; The result
	JMP	Ret0
	
;----------------------------------------------------------------------------
; HL-size, DE-address / HL-how much was loaded, A-error code
CmdRead:
	; Command code
	MVI	A, 6
	CALL	StartCommand

	; Address in BC
	MOV	B, D
	MOV	C, E

	; Block size
	CALL	SendWord	; HL-size

IFNDEF USE_DMA
	; Switch to receive mode
	CALL	SwitchRecv
ENDIF

	; Block receiving. On enter BC - address, HL - received length
IFDEF USE_DMA
; Load data to address in BC. 
; On exit: HL - how much loaded
; A will be rewritten
; If no errors, Z=1 on exit

RecvBuf:
	LXI	H, 0
RecvBuf0:	
	; Wait
	CALL	WaitForReady
	CPI	STA_OK_READ
	JZ	Ret0		; Z on exit (no error)
	CPI	STA_OK_BLOCK
	RNZ;	EndCommand	; NZ on exit (error)

	; Loaded data size in DE
	CALL	RecvWord

	; Overall size in HL
	DAD	D

	;CALL	ReceiveBufferIfEmpty
	; Load DE bytes to address in BC
	CALL	RecvBlock

	JMP	RecvBuf0
ELSE
	JMP	RecvBuf
ENDIF


;----------------------------------------------------------------------------
; HL-size, DE-address / A-error code
CmdWrite:
	; Command code
	MVI	A, 7
	CALL	StartCommand
	
	; Block size
	CALL	SendWord		 ; HL-размер

	; Now the address in HL
	XCHG
IFDEF USE_DMA
	MOV    B,H
	MOV    C,L
ENDIF
CmdWriteFile2:
	; Command result
	CALL	SwitchRecvAndWait
	CPI	STA_OK_CMD
	JZ	Ret0
	CPI	STA_OK_WRITE
IFDEF USE_DMA
	RNZ
ELSE
	JNZ	EndCommand
ENDIF

	; Block size MC may receive in DE
	CALL	RecvWord

IFNDEF USE_DMA
	; Switch to send mode
	CALL	SwitchSend
ENDIF

	; Block transfer. Address in BC, length in DE.
CmdWriteFile1:
IFDEF USE_DMA
	CALL	SendBlock
ELSE
	MOV	A, M
	INX	H
	CALL	SendByte
	DCX	D
	MOV	A, D
	ORA	E
	JNZ 	CmdWriteFile1
ENDIF

	JMP	CmdWriteFile2

;----------------------------------------------------------------------------
; HL-from, DE-to / A-error code

CmdMove:
	; Command code
	MVI	A, 8
	CALL	StartCommand

	; File name
	CALL	SendString

	; Wait for MC will be ready
	CALL	SwitchRecvAndWait
	CPI	STA_OK_WRITE
	RNZ;	EndCommand

IFNDEF USE_DMA
	; Switch to send mode
	CALL	SwitchSend
ENDIF

	; File name
	XCHG
	CALL	SendString

WaitEnd:
	; Wait for MC will be ready
	CALL	SwitchRecvAndWait
	CPI	STA_OK_CMD
	JZ	Ret0
	RET;	JMP	EndCommand

;----------------------------------------------------------------------------
; HL-file name, DE-command line / A-error code
CmdExec:
	; Command code
	MVI	A, 2
	CALL	StartCommand

	; File name
	PUSH	H
	CALL	SendString
	POP	H

	; Wait for MC will read the file
	; MC should  answer with code STA_OK_ADDR
	CALL	SwitchRecvAndWait
	CPI	STA_OK_ADDR
	RNZ;	EndCommand

	; Save file name (HL-string)
	PUSH	D
	XCHG
	LXI	H, SELF_NAME
	CALL	strcpy255
	POP	D

	; Save command line (DE-string)
	LXI	H, CMD_LINE
	CALL	strcpy255

	; *** This is no-return point. Any error will lead to restart. ***

	; Stack init (as in monitor)
	LXI	SP, INIT_STACK

	; Receive loadind address in BC and save it to stack
	CALL	RecvWord
	PUSH	D
	MOV 	B, D
	MOV 	C, E

	; Loading the file
	CALL	RecvBuf
	JNZ 	ErrorSD

	CALL	CLS_INIT_VDP

	; Program settings
	MVI  A, 1		; Controller version
	LXI  B, BiosEntry  ; SD BIOS entry point
	LXI  D, SELF_NAME  ; Self name
	LXI  H, CMD_LINE	; Command line

	; Run loaded program
	RET

IF 1
;----------------------------------------------------------------------------
; Beginning of every command
; A - command code
StartCommand:
	; The first stage is synchronization with the controller
	; 256 attempts are accepted, each of which skips 256+ bytes
	; That is, this is the maximum amount of data that the controller can transmit
	PUSH	B
	PUSH	H
	PUSH	PSW
IFNDEF USE_DMA
	MVI	C, 0
ENDIF

StartCommand1:
IFNDEF USE_DMA
	; Send mode (release the bus) and init HL
	CALL	SwitchRecv
	; Начало любой команды (это шина адреса)
	;LXI	H, USER_PORT+1
	;MVI	M,0
	XRA	A
	@out	USER_PORT+1
	;MVI	M, 44h
	MVI	A,44h
	@out	USER_PORT+1
	;MVI	M, 40h
	MVI	A,40h
	@out	USER_PORT+1
	;MVI	M, 0h
	XRA	A
	@out	USER_PORT+1
ENDIF
	; If there is synchronization, controller will answer STA_START
	CALL	RecvByte
	CPI	STA_START
IFDEF USE_DMA
	JNZ	StartCommandErr2
ELSE
	JZ	StartCommand2

	; Пауза. И за одно пропускаем 256 байт (в сумме будет 
	; пропущено 64 Кб данных, максимальный размер пакета)
	PUSH	B
	MVI	C, 0
StartCommand3:
	CALL	RecvByte
	DCR	C
	JNZ	StartCommand3
	POP	B

	; Попытки
	DCR	C
	JNZ	StartCommand1
	; Код ошибки
	MVI	A, STA_START
StartCommandErr2:
	POP	B ; Прошлое значение PSW
	POP	H ; Прошлое значение H
	POP	B ; Прошлое значение B
	POP	B ; Выходим через функцию.
	RET

;----------------------------------------------------------------------------
; There is synchronization with controller.Controller should answer STA_OK_DISK

StartCommand2:
ENDIF
	; Reply
	CALL	WaitForReady
	CPI	STA_OK_DISK
	JNZ	StartCommandErr2

IFNDEF USE_DMA
	; Switch to send mode
	CALL	SwitchSend
ENDIF

	POP	PSW
	POP	H
	POP	B

	; Transmit command code
	JMP	SendByte
IFDEF USE_DMA
StartCommandErr2:
	POP	B
	POP	H
	POP	B
	POP	B
	RET
ELSE

;----------------------------------------------------------------------------
; Переключиться в режим передачи

SwitchSend:
	CALL	RecvByte
SwitchSend0:
	MVI	A, SEND_MODE
	@out	USER_PORT+3
	RET
ENDIF
;----------------------------------------------------------------------------
; Successful command ending 
Ret0:
	XRA	A
;----------------------------------------------------------------------------
; Command ending with error in A 
;EndCommand:
IFNDEF USE_DMA

EndCommand:
	PUSH	PSW
	CALL	RecvByte
	POP	PSW
ENDIF
	RET

;----------------------------------------------------------------------------
; Receive word in DE 
; A is corrupted.

RecvWord:
	PUSH	H
	PUSH	B
	LXI	D,SDBUF2
	LXI	B,4002h
	;RST	3;
	CALL	SET_DMAW
	XCHG
	MOV	E,M
	INX	H
	MOV	D,M
	POP	B
	POP	H
	RET
	
;----------------------------------------------------------------------------
; Send word from HL 
; A is corrupted.

SendWord:
	PUSH	D
	PUSH	B
	LXI	D, SDBUF2
	MOV	A, L
	STAX	D
	INX	D
	MOV	A,H
	STAX	D
	DCX	D
	LXI	B,8002h
	JMP	SendDma
;----------------------------------------------------------------------------
; Send string
; HL - string
; A is corrupted.

SendString:
	XRA	A
	ORA	M
	JZ	SendByte
	CALL	SendByte
	INX	H
	JMP	SendString
	
IFNDEF USE_DMA
;----------------------------------------------------------------------------
; Switch to receive mode

SwitchRecv:
	MVI	A, RECV_MODE
	@out	USER_PORT+3
	RET
ENDIF

;----------------------------------------------------------------------------
; Switch to receive mode and wait for MC ready

SwitchRecvAndWait:
IFNDEF USE_DMA
	CALL	SwitchRecv
ENDIF

;----------------------------------------------------------------------------
; Wait for MC ready.

WaitForReady:
	CALL	RecvByte
	CPI	STA_WAIT
	JZ	WaitForReady
	RET

IFDEF USE_DMA
;----------------------------------------------------------------------------
; Send DE bytes from address in BC
; A is corrupted.
SendBlock:
	MVI	A,80H
	JMP	RecvSendBlock

;----------------------------------------------------------------------------
; Receive DE bytes to address in BC
; Enlarge BC by block size
; A is corrupted.
RecvBlock:
	MVI	A,40H
RecvSendBlock:
	PUSH	D

	; Swap BC and DE
	PUSH	B
	PUSH	D
	POP	B
	POP	D

	PUSH	B
	ORA	B
	MOV	B,A
	CALL	SET_DMAW
	XCHG
	POP	B
	DAD	B
	XCHG
	MOV	C,E
	MOV	B,D
	POP	D
	RET

;RecvBlock2:
;	JMP	DmaReadVariable
ELSE
;----------------------------------------------------------------------------
; Принять DE байт по адресу BC
; Портим A
RecvBlock:
	PUSH	H
	LXI 	H, USER_PORT+1
	INR 	D
	XRA 	A
	ORA 	E
	JZ 	RecvBlock2
RecvBlock1:
	MVI	A, 20h
	@out	USER_PORT+1
	XRA	A
	@out	USER_PORT+1
	@in	USER_PORT		; 13
	STAX	B		        ; 7
	INX	B		        ; 5
	DCR	E		        ; 5
	JNZ	RecvBlock1		; 10 = 54
RecvBlock2:
	DCR	D
	JNZ	RecvBlock1
	POP	H
	RET

;PPI_PG	EQU	0D0H 

;----------------------------------------------------------------------------
; Загрузка данных по адресу BC. 
; На выходе HL сколько загрузили
; Портим A
; Если загружено без ошибок, на выходе Z=1

RecvBuf:
	LXI	H, 0
RecvBuf0:
	; Подождать
	CALL	WaitForReady
	CPI	STA_OK_READ
	JZ	Ret0		; на выходе Z (нет ошибки)
	CPI	STA_OK_BLOCK
	JNZ	EndCommand	; на выходе NZ (ошибка)

	; Размер загруженных данных в DE
	CALL	RecvWord

	; В HL общий размер
	DAD D

	; Принять DE байт по адресу BC
	CALL	RecvBlock

	JMP	RecvBuf0
ENDIF
;----------------------------------------------------------------------------
; Send byte from A.
SendByte:
IFDEF USE_DMA
	PUSH	D
	PUSH	B
	LXI	D,SDBUF2
	STAX	D
	LXI	B,8001H
	;RST	3;
SendDma:
	CALL	SET_DMAW
	POP	B
	POP	D
	XRA	A
	RET
ELSE
	@out	USER_PORT
ENDIF
;----------------------------------------------------------------------------
; Receive byte into А

RecvByte:
IFDEF USE_DMA
	PUSH	D
	PUSH	B
	LXI	D,SDBUF2
	LXI	B,4001h
	;RST	3;
	CALL	SET_DMAW
	LDAX	D
	POP	B
	POP	D
ELSE
	MVI	A, 20h
	@out	USER_PORT+1
	XRA	A
	@out	USER_PORT+1
	@in	USER_PORT
ENDIF
	RET

IFDEF USE_DMA

;DmaMode		EQU	BASE_W+1	;:	db RECV_MODE
;SDBUF_PTR	EQU	DmaMode+1	;:	ds  2
;SDBUF_SIZE	EQU	BASE_W+1	;:	ds  1
SDBBUF		EQU	BASE_W+1	;:	ds  32
ENDIF
ENDIF
SDBUF2		EQU	SDBBUF+32;:	ds	2
