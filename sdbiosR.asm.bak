; SD BIOS for Computer "Radio 86RK"
; (c) 09-10-2014 vinxru (aleksey.f.morozov@gmail.com)
; (c) 24-10-2024 tchv aka Dmitry Tsvetkov (tchv71@mail.ru)


;----------------------------------------------------------------------------

INIT_VIDEO	EQU  F82DH
INIT_STACK	EQU  0D800h

; MC codes
STA_START	EQU 040h ; MC switched to command receive DmaMode
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
	CALL	SwitchRecv
	
	; Получаем версию набора команд и текст
	;LXI	D, VER_BUF
	CALL	RecvSD;Block2
	 
	; Вывод версии железа
	XRA	A
	STA	SDBUF_SIZE
	STA	VER_BUF+17+2
	LXI	H, VER_BUF+1+2
	JMP 	F818h

;----------------------------------------------------------------------------

aHello:		db 13,10,"SDB",0;"SD BIOS V1.1",13,10
aSdController:  db 0;"SD DMA CONTROLLER ",0
aCrLf:		db 13,10,0
aErrorShellRk:  db "fajl ne najden "
aShellRk:	db "BOOT/SHELL.RK",0
		;db "(c) 04-05-2014 vinxru, 2024 (c) tchv"

; Код ниже будет затерт ком строкой и собственым именем

SELF_NAME	EQU $-512 ; путь (буфер 256 байт)
CMD_LINE	EQU $-256 ; команданая строка 256 байт

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
	dw CmdOpenDelete	; 2 D-DmaMode, HL-file name / A-error code
	dw CmdSeekGetSize	; 3 B-DmaMode, DE:HL-position / A-error code, DE:HL-position
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

	; Switch to receive DmaMode
	CALL	SwitchRecv

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

;----------------------------------------------------------------------------
; D-DmaMode, HL-file name / A-error code

CmdOpenDelete: 
	; Command code
	MVI	A, 4
	CALL	StartCommand

	; DmaMode
	MOV	A, D
	CALL	SendSD

	; File name
	CALL	SendString

	; Wait for MC will be ready
	CALL	SwitchRecvAndWait
	CPI	STA_OK_CMD
	JZ	Ret0
	RET;JMP	EndCommand
	
;----------------------------------------------------------------------------
; B-DmaMode, DE:HL-position / A-error code, DE:HL-position

CmdSeekGetSize:
	; Command code
	MVI 	A, 5
	CALL	StartCommand

	; DmaMode
	MOV	A, B
	CALL	SendSD

	; Position
	CALL	SendWord
	XCHG
	CALL	SendWord

	; Wait for MC will be ready. Should answer with STA_OK_CMD code
	CALL	SwitchRecvAndWait
	CPI	STA_OK_CMD
	RNZ;	EndCommand

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

	; Switch to receive DmaMode
	CALL	SwitchRecv

	; Block receiving. On enter BC - address, HL - received length
;----------------------------------------------------------------------------
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
	SUI	STA_OK_BLOCK
	RNZ;	EndCommand	; NZ on exit (error)

	; Loaded data size in DE
	CALL	RecvWord

	; Overall size in HL
	DAD	D

	; Load DE bytes to address in BC
	CALL	RecvBlock

	JMP	RecvBuf0


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
	MOV	B,H
	MOV	C,L
CmdWriteFile2:
	; Command result
	CALL	SwitchRecvAndWait
	CPI	STA_OK_CMD
	JZ	Ret0
	CPI	STA_OK_WRITE
	RNZ;	EndCommand

	; Block size MC may receive in DE
	CALL	RecvWord

	; Switch to send DmaMode
	CALL	SwitchSend

	; Block transfer. Address in BC, length in DE.
CmdWriteFile1:
	CALL	SendBlock
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

	; Switch to send DmaMode
	CALL	SwitchSend

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

StartCommand1:
	; Send DmaMode (release the bus) and init HL
	CALL	SwitchRecv
	;CALL	ClearRcvBuf

	; If there is synchronization, controller will answer STA_START
	CALL	RecvSD
	CPI	STA_START
	JNZ	StartCommandErr2
;----------------------------------------------------------------------------
; There is synchronization with controller.Controller should answer STA_OK_DISK

	; Reply
	CALL	WaitForReady
	CPI	STA_OK_DISK
	JNZ	StartCommandErr2

	; Switch to send DmaMode
	CALL	SwitchSend

	POP	PSW
	POP	H
	POP	B

	; Transmit command code
	JMP	SendSD
StartCommandErr2:
	POP	B
	POP	H
	POP	B
	POP	B
	RET
ENDIF

;----------------------------------------------------------------------------
; Successful command ending 
Ret0:
	XRA	A
;----------------------------------------------------------------------------
; Command ending with error in A 
;EndCommand:
	RET

;----------------------------------------------------------------------------
; Receive word in DE 
; A is corrupted.

RecvWord:
	CALL	RecvSD
	MOV	E, A
	CALL	RecvSD
	MOV	D, A
	RET
	
;----------------------------------------------------------------------------
; Send word from HL 
; A is corrupted.

SendWord:
	MOV	A, L
	CALL	SendSD
	MOV	A, H
	JMP	SendSD
	
;----------------------------------------------------------------------------
; Send string
; HL - string
; A is corrupted.

SendString:
	XRA	A
	ORA	M
	JZ	SendSD
	CALL	SendSD
	INX	H
	JMP	SendString
	

;----------------------------------------------------------------------------
; Switch to receive DmaMode and wait for MC ready

SwitchRecvAndWait:
	CALL	SwitchRecv

;----------------------------------------------------------------------------
; Wait for MC ready.

WaitForReady:
	CALL	RecvSD
	CPI	STA_WAIT
	JZ	WaitForReady
	RET


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
	PUSH	H
	PUSH	D

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
	MOV	C,L
	MOV	B,H
	POP	D
	POP	H
	RET

;RecvBlock2:
;	JMP	DmaReadVariable

;----------------------------------------------------------------------------
SEND_MODE		EQU 0			; Send DmaMode
RECV_MODE		EQU 1			; Receive DmaMode
;----------------------------------------------------------------------------
CHANNEL0 EQU 1

SwitchRecv:
	PUSH	H
	PUSH	D
	PUSH	B
	LDA	DmaMode
	ORA	A	; CPI SEND_MODE
	JNZ	RM01
	; Flush send buffer
	LXI	H,-SDBBUF
	XCHG
	LHLD	SDBUF_PTR
	DAD	D
	MOV	A,H
	ORA	L
	JZ	 RM01
	XCHG
	LXI	H,SDBBUF-2
	MOV	M,E
	INX	H
	MOV	M,D
	DCX	H
	XCHG
	LXI	B,8002h
	;RST	3
	CALL	SET_DMAW
	LDAX	D
	INX	D
	MOV	C,A
	LDAX	D
	INX	D
	ORI	80H
	MOV	B,A
	;RST	3
	CALL	SET_DMAW
RM01:
	MVI	A, RECV_MODE
	JMP	SetMode
SwitchSend:
	PUSH  H
	PUSH  D
	PUSH  B
	XRA	A ; MVI	A,SEND_MODE
SetMode:
	STA	DmaMode
	XRA	A
	STA	SDBUF_SIZE
	LXI	H, SDBBUF
	SHLD	SDBUF_PTR
	POP	B
	POP	D
	POP	H
	RET

THE_END_SDB:
DmaMode		EQU	0D240h		;:	db RECV_MODE
SDBUF_PTR	EQU	DmaMode+1	;:	ds  2
SDBUF_SIZE	EQU	SDBUF_PTR+2	;:	ds  1
SDBBUF		EQU	SDBUF_SIZE+2	;:	ds  32
;End
