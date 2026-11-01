	 .phase 80H 
CHANNEL0 EQU 1 
STA_START	EQU 040h ; MC switched to command receive mode 
STA_WAIT	EQU 041h ; MC is executing command 
STA_OK_DISK	EQU 042h ; The drive is working, MC is ready to receive command 
 
	CALL	StartTest 
	JNZ	Err 
	LXI D,1200h 
	LXI B,4080h 
	CALL SET_DMAW 
	;JMP 0F86CH 
	LXI D,1200h 
	LXI B,8080h 
	CALL SET_DMAW 
 
	LXI D,1280h 
	LXI B,4080h 
	CALL SET_DMAW 
	JMP  0F86Ch 
Err:	LXI	H,ErrTxt 
	JMP	0F818h 
 
ErrTxt:	DB	'SD ERROR',13,10,0 


 
StartTest: 
	CALL	RecvByte 
	CPI	STA_START 
	RNZ 
	CALL	WaitForReady 
	CPI	STA_OK_DISK 
	RNZ 
	MVI	A,99 
	CALL	SendByte 
	XRA	A 
	RET 
 
WaitForReady: 
	;Rst	1 
	CALL	RecvByte 
	CPI	STA_WAIT 
	JZ	WaitForReady 
	RET 
 
; Receive byte into @ 
RecvByte: 
	PUSH	D 
	PUSH	B 
	LXI	D,BUF 
	LXI	B,4001h 
	;RST	3; 
	CALL	SET_DMAW 
	LDAX	D 
	POP	B 
	POP	D 
	RET 
 
SendByte: 
	LXI	D,BUF 
	STAX	D 
	LXI	B,8001H 
	;RST	3; 
	JMP	SET_DMAW 
 
 
	; HL - addr 
	; DE - size 
; Set DMA with waiting of the end of transfer 
SET_DMAW: 
	CALL	SET_DMA32 
WAIT_DMA: 
	LDA	0C608H 
IFDEF CHANNEL0 
	ANI	1 
ELSE 
	ANI	2 
ENDIF 
	JZ	 WAIT_DMA 
	RET 
; Program DMA controller 
 
; DE - start address 
; BC - packet length with MSB: 
;	10 - read cycle (transfer from memory to device) 
;	01 - write cycle (thansfer from device to memory) 
SET_DMA: 
	PUSH	D 
	PUSH	B 
	MOV	A,C 
	CPI	32 
	JC	SD01 
SD00: 
	PUSH	B 
	CALL	SET_DMA32W 
	POP	B 
	PUSH	H 
	LXI	H,32 
	DAD	D 
	XCHG 
	POP	H 
	MOV	A,C 
	SUI	32 
	MOV	C,A 
	JZ	SD02 
	JNC	SD00 
SD01: 
	CALL	SET_DMA32W 
SD02: 
	POP	B 
	POP	D 
	RET 
 
SET_DMA32W: 
	MOV	A,C 
	CPI	32+1 
	JC	$+5 
	MVI	C,32 
	CALL	SET_DMA32 
	JMP	WAIT_DMA 
 
SET_DMA32: 
	PUSH  H 
	LXI	H,0C60Fh 
	MOV	A,M 
	INR	A 
	JZ	VT37 
	MVI	L,8 
	MVI	M,0F4h 
IFDEF CHANNEL0 
	MVI	L,0 
ELSE 
	MVI	L,2 
ENDIF 
	MOV	M,E 
	MOV	M,D 
	INR	L 
	DCX	B 
	MOV	M,C 
	MOV	M,B 
	INX	B 
	MVI	L,8 
IFDEF CHANNEL0 
	MVI	M,0F5h 
ELSE 
	MVI	M,0F6h 
ENDIF 
	POP	H 
	RET 
 
VT37: 
	MOV	A,B 
	PUSH	PSW 
	ANI	3Fh 
	MOV	B,A 
	MVI	L,0Ch 
	MOV	M,A 
	MVI	L,0Ah 
IFDEF CHANNEL0 
	MVI	M,4 ; Stop channel 0 
	MVI	L,0 
ELSE 
	MVI	M,5 ; Stop channel 1 
	MVI	L,2 
ENDIF 
	MOV	M,E 
	MOV	M,D 
	INR	L 
	DCX	B 
	MOV	M,C 
	MOV	M,B 
	INX	B 
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
IFDEF CHANNEL0 
	MVI	M,0 
ELSE 
	MVI	M,1 ; Start channel 1 
ENDIF 
	POP	H 
	RET 
 
BUF:	DS	1 
	 END 
