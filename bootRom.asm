; Boot loader (SD BIOS) for Computer "Radio 86RK" / "Apogee BK01"
; (c) 10-05-2014 vinxru (aleksey.f.morozov@gmail.com)
; (c) 24-10-2024 - 08-06-2025 tchv aka Dmitry Tsvetkov (tchv71@mail.ru)
	.phase SD_MOD_ORG; 0F600h

MONITOR         EQU	0F86Ch    ; RK-86 warm start
CHANNEL0	EQU	1	  ; Use channel 0 of DMA
IFDEF	CHANNEL0
CHAN		EQU	0
ELSE
CHAN		EQU	1
ENDIF
;VT37		EQU	1

; MC codes
STA_START	EQU	040h ; MC switched to command receive mode
STA_WAIT	EQU	041h ; MC is executing command
STA_OK_DISK	EQU	042h ; The drive is working, MC is ready to receive command
STA_OK		EQU	043h ; Command is executed
STA_OK_READ	EQU	044h ; MC is ready to transfer next data block
STA_OK_ADDR	EQU	047h ; MC is ready to SendCh loading address
STA_OK_BLOCK	EQU	04Fh 
;BUF		EQU	0D8h
;----------------------------------------------------------------------------
; Entry point

Entry:
Boot:
;----------------------------------------------------------------------------
	; Start of any command (this is address bus)
Boot2:
	DI
	CALL	ClearRcvBuf
	
	;XRA	A	; BOOT command code
	MVI	A,2
	CALL	StartCommand
	RNZ
IF 1
	PUSH	H
	LXI	H,aShellRk
	CALL	SendString
	POP	H
ENDIF
	CALL	SwitchRecv
	; This is BOOT command answer
	;Rst	2
	CALL	Rst2
	CPI	STA_START
	JNZ	CMD01

	;Rst	2 
	CALL	SwitchRecvAndWait ; Rst2
CMD01:
	CPI	STA_OK_ADDR
	RNZ
	
	; Loading address in DE
	CALL	RecvWordCA
	MOV	E, C
	MOV	D, A
	
	;LXI	d,0A000h
	; Save starting address into stack
	PUSH   D
	
	; File may be broken into several parts
RecvLoop:
	; All parts are loaded, may execute the file
	;Rst	2
	CALL	Rst2
	CPI	STA_OK_READ
	JNZ	RL01
	;On exit: HL - run address, DE - entry point, A = 0
	POP	H
	PUSH	H
	INX	H
	INX	H
	INX	H
	MOV	E, M
	INX	H
	MOV	D, M
	POP	H
	XRA	A
	RET 
RL01:
	; If MC has readed block without errors, STA_OK_BLOCK will be SendCh
	CPI	STA_OK_BLOCK
	JNZ	ERRLOAD

	; Data block size
	CALL	RecvWordCA
	MOV	B,A
	PUSH	B
	ORI	40h
	MOV	B, A
	; Receive the data block
	;RST	3;
	CALL	SET_DMAW
	POP	B
	XCHG
	DAD	B
	XCHG
	JMP	RecvLoop
ERRLOAD:
	POP	B ; Clear start address on stack
	RET

; Receive word: C - low byte A - high byte
RecvWordCA:
	CALL	Rst1
	MOV	C,A
;----------------------------------------------------------------------------
; Byte SendCh and receive
Rst1:
;----------------------------------------------------------------------------
; Receive byte into À

RecvSD:
	PUSH	H
	PUSH	D
	PUSH	B
	LXI	H,SDBUF_SIZE
	MOV	A,M
	ORA	A
	JNZ	Recv01
; Read variable length DMA record - the first packet is 2 bytes length,
; the second - data with previosly transmitted length
;DmaReadVariable:
	LXI	B,4002H
	LXI	D,SDBBUF
	CALL	SET_DMAW
	LDAX	D
	INX	D
	MOV	C,A
	LDAX	D
	INX	D
	ORI	40H
	MOV	B,A
	CALL	SET_DMAW
	MOV	A,C
	STA	SDBUF_SIZE
	XCHG
	SHLD	SDBUF_PTR
	XCHG
Recv01:
	DCR	M
	LHLD	SDBUF_PTR
	MOV	A,M
	INX	H
	SHLD	SDBUF_PTR
	POP	B
	POP	D
	POP	H
	RET

ClearRcvBuf:
	XRA	A
	STA	SDBUF_SIZE
	RET
;----------------------------------------------------------------------------
; Wait for MC ready
Rst2:
	;Rst	1
	CALL	Rst1
	CPI	STA_WAIT
	JZ	Rst2
	RET
	;NOP
Rst3:
; Program DMA controller

; DE - start address
; BC - packet length with MSB:
;   10 - read cycle (transfer from memory to device)
;   01 - write cycle (thansfer from device to memory)
SET_DMAW:
	PUSH	H
	LXI	H,0C60Fh
	MOV	A,M
	INR	A
	JZ	_VT37
	MVI	L,8
	MVI	M,0F4h
	MVI	L,CHAN*2
	CALL	INIT_CHAN
	MVI	L,8
	MVI	M,0F5h+CHAN
	JMP	WAIT_DMA

_VT37:
	MOV	A,B
	PUSH	PSW
	ANI	3Fh
	MOV	B,A
	MVI	L,0Ch
	MOV	M,A
	MVI	L,0AH
	MVI	M,4+CHAN ; Stop channel
	MVI	L,CHAN*2
	CALL	INIT_CHAN
	MVI	L,0Bh
	POP	PSW
	ANI	0C0H
	RRC
	RRC
	RRC
	RRC
IFNDEF CHANNEL0
	ORI	1
ENDIF
	MOV	M,A
	MVI	L,8
	MVI	M,20h
	MVI	L,0Ah
	MVI	M,CHAN	; Start channel
	MVI	L,8
WAIT_DMA:
	MOV	A,M
	ANI	CHAN+1
	JZ	WAIT_DMA
	POP	H
	RET
INIT_CHAN:
	MOV	M,E
	MOV	M,D
	INR	L
	DCX	B
	MOV	M,C
	MOV	M,B
	INX	B
	RET
;----------------------------------------------------------------------------
; Print error code

;PrintError:
;	CALL	0F815h
;	JMP	MONITOR


IF 0;($ MOD 128) NE 0
	REPT	128 - (LOW($) MOD 128)
		DB 0FFh
	ENDM
ENDIF
;     DW 1
;OUTCH: DS 2
;Mode: db RECV_MODE
;RAM		EQU	0D200h
;BUF_PTR		EQU	RAM;:    ds  2
;BUF_SIZE	EQU	RAM+2;:   DW  0
;BUF		EQU	OUTCH;:        ds  2
OUTCH		EQU	SDBBUF;:
THE_END:
     ;End

