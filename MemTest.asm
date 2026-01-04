	include	9918def.asm
VDP_LINE	EQU	14
VDP	        EQU	98H
LineWidth	EQU	80

	.PHASE 100h
	LXI	SP,100h
	CALL	setVdpPort
	MVI	A,80h
	CALL	T_InitialiseText80

	LXI	H,STRBUF
	MVI	B,LineWidth * 2
	MVI	C,30
	LXI	D,0
	call	FillBuf
MT01:
	CALL	T_ShAddrWriteBytes
	CALL	T_SetAddrReadDE
DL80:
	IN	VDP
	CMP	M
	JNZ	FAIL
	INX	H
	DCR	B
	JNZ	DL80
	XCHG
	PUSH	B
	LXI	B,80
	DAD	B
	POP	B
	XCHG
	DCR	C
	JNZ	MT01
	LXI	H,TestOk
	call	0F818h
	jmp	0f86ch


Fail:
	PUSH	H
	LXI	H,TestFailed
	call	0F818h
	POP	H
	LXI	D,-STRBUF
	DAD	D
	MOV	A,H
	CALL	0F815h
	MOV	A,L
	CALL	0F815h
	LXI	H,TestFailed2
	call	0F818h
	jmp	0f86ch
TestFailed:
	DB	13,10,'TEST FAILED ',0
TestFailed2:
	DB	13,10,0
TESTOK:
	DB	13,10,'TEST OK',13,10,0

FILLBUF:
	PUSH	H
	PUSH	B
	MVI	A,' '
DL99:
	MOV	M,A
	INR	A
	INX	H
	MVI	M,0F4H
	INX	H
	DCR	B
	DCR	B
	JNZ	DL99
	POP	B
	POP	H
	RET

; DE - address to read
T_SetAddrReadDE:
	DI
	MOV	A,E
	OUT	VDP+1
	MOV	A,D
	OUT	VDP+1
	RET

; BC - address to write
T_SetAddrWrite:
	MOV	A,B
	ORI	40h
	MOV	B,A
; BC - address to read
T_SetAddrRead:
	DI
	MOV	A,C
	OUT	VDP+1
	MOV	A,B
	OUT	VDP+1
	RET

; HL - buffer in RAM
; DE - VRAM address
; B - byte count
T_ShAddrWriteBytes:
	PUSH	B
	MOV	B,D
	MOV	C,E
	CALL	T_SetAddrWrite
	POP	B
	PUSH	H
	PUSH	B
T_ShortWriteBytes:
	MOV	A,M
	OUT	VDP
	INX	H
	DCR	B
	JNZ	T_ShortWriteBytes
	POP	B
	POP	H
	RET


STRBUF:	DS	LineWidth * 2

@SYSREG	MACRO	VAL
	IN	-1
	MVI	A,VAL
	OUT	-1
	ENDM


setVdpPort:
	DI
	@SYSREG	0C0h ; Turn on external device programming mode (for in/out commands)
	MVI	A, VDP_LINE
	OUT	VDP
	OUT	VDP+1
	@SYSREG	80h
	RET

T_InitialiseText80:
	;CALL	T_Reset
	PUSH	PSW


; non-bitmap color and pattern table configuration
	MVI	B, T_REG_COLOR_TABLE
	MVI	C, T_T80_VRAM_COLOR_ADDRESS / 40h
	CALL	T_WriteRegValue

	; set up pattern table address (register = address / 800H)
	MVI	B, T_REG_PATTERN_TABLE
	MVI	C, T_T80_VRAM_PATT_ADDRESS / 800h
	CALL	T_WriteRegValue

	; set up name table address (register = address / 400H)
	MVI	B, T_REG_NAME_TABLE
	MVI	C, (T_T80_VRAM_NAME_ADDRESS / 400h) AND 0fh;7Ch OR 3 
	CALL	T_WriteRegValue

	LXI	B, T_T80_VRAM_PATT_ADDRESS ; load font from address in bc
	CALL	T_SetAddrWrite

	POP	PSW
	CPI	80H
	JZ	font16
	LXI	H, tmsFont8
	LXI	D, tmsFont8End - tmsFont8
	CALL	T_WriteBytes

	LXI	B, (T_REG_0 SHL 8) OR T_R0_EXT_VDP_DISABLE OR T_R0_MODE_TEXT80
	CALL	T_WriteRegValue
	JMP	Reg0Ok

font16:
	LXI	H, tmsFont
	LXI	D, tmsFontEnd - tmsFont ; tmsFontBytes
	CALL	T_WriteBytes

	LXI	B, (T_REG_0 SHL 8) OR T_R0_EXT_VDP_DISABLE OR T_R0_MODE_TEXT80 OR T_R0_MODE_TEXT8_80
	CALL	T_WriteRegValue

reg0ok:
	LXI	B, (T_REG_1 SHL 8) OR T_R1_MODE_TEXT OR T_R1_DISP_ACTIVE; OR T_R1_INT_ENABLE
	CALL	T_WriteRegValue

	LXI	B, (T_REG_FG_BG_COLOR SHL 8) OR T_DK_BLUE OR (T_WHITE SHL 4)
	JMP	T_WriteRegValue

; C - value
; B - reg
T_WriteRegValue:
	;CALL	T_WriteAddr
	DI
	MOV	A,C
	OUT	VDP+1
	MOV	A,B
	ORI	80H
	OUT	VDP+1
	RET

; HL - buffer in RAm
; DE - byte count
T_WriteBytes:
	MOV	A,M
	OUT	VDP
	INX	H
	DCX	D
	MOV	A,D
	ORA	E
	JNZ	T_WriteBytes
	RET
tmsFont:
include font8x16.asm
tmsFontEnd:
tmsFont8:
include fontMsx.asm
tmsFont8End:


        end
