; Tms9918 test program
VDP_LINE	EQU	14

@SYSREG	MACRO	VAL
	IN	-1
	MVI	A,VAL
	OUT	-1
	ENDM

	.phase 100h
_START:
	LXI	SP,100h
	.Z80
	im	1
	.8080
	MVI	A,0C9h
	STA	38h

	CALL	setVdpPort
	CALL	T_ReadStatus

	CALL	T_InitialiseGfxII

	MVI	B, T_REG_FG_BG_COLOR
	MVI	C, (T_WHITE shl 4) or T_BLACK
	CALL	T_WriteRegValue

	LXI	B, T_DEF_VRAM_SPR_PATT_ADDRESS + 32 * 8
	CALL	T_SetAddrWrite

	LXI	H, tmsFont
	LXI	D, tmsFontEnd - tmsFont ; tmsFontBytes
	CALL	T_WriteBytes

	LXI	B, T_DEF_VRAM_COLOR_ADDRESS
	CALL	T_SetAddrWrite
	LXI	H, BREAKOUT_TIAC
	LXI	D, 6144
	CALL	T_WriteBytes

	LXI	B, T_DEF_VRAM_PATT_ADDRESS
	CALL	T_SetAddrWrite
	LXI	H, BREAKOUT_TIAP
	LXI	D, 6144
	CALL	T_WriteBytes

	LXI	B, T_DEF_VRAM_SPR_ATTR_ADDRESS
	CALL	T_SetAddrWrite

	LXI	D,0
	LXI	H,str+strLen-1
@loop01:
	MOV	A,E
	ADI	22
	OUT	VDP

	MOV	A,E
	SUI	2
	OUT	VDP

	MOV	A,M
	OUT	VDP

	MOV	A,D
	INR	A
	INR	A
	OUT	VDP


	MOV	A,E
	ADI	24
	OUT	VDP

	MOV	A,E
	OUT	VDP

	MOV	A,M
	OUT	VDP

	MVI	A,1
	OUT	VDP

	DCX	H
	MOV	A,E
	ADI 10
	MOV	E,A

	INR	D
	MOV	A,D
	CPI	strLen
	JNZ	@loop01

	MVI	C, strLen
@loop02:
	MVI	A,0D0h
	OUT	VDP
	XRA	A
	OUT	VDP
	OUT	VDP
	OUT	VDP

	MVI	A,0D2h
	OUT	VDP
	XRA	A
	OUT	VDP
	OUT	VDP
	OUT	VDP
	INR	C
	MOV	A,C
	CPI	16
	JNZ	@loop02
	;jmp	$

	lxi	h,onTms9918Interrupt
	shld	39h
	mvi	a,0c3h
	sta	38h
	.Z80
	im	1
	.8080
	EI
	JMP	$;0f86ch

setVdpPort:
	DI
	@SYSREG	0C0h ; Turn on external device programming mode (for in/out commands)
	MVI	A,VDP_LINE
	OUT	VDP
	OUT	VDP+1
	@SYSREG	80h
	RET


frameNumber:	DW	0

onTms9918InterruptS:
	PUSH	PSW
	PUSH	H
	PUSH	D
	PUSH	B
	MVI	B, T_REG_FG_BG_COLOR
	MVI	C, (T_WHITE SHL 4) OR T_CYAN
	CALL	T_WriteRegValue
	CALL	animateSprites
	LHLD	frameNumber
	INX	H
	SHLD	frameNumber
	MVI	B, T_REG_FG_BG_COLOR
	MVI	C, (T_WHITE SHL 4) OR T_BLACK
	CALL	T_WriteRegValue
	CALL	T_ReadStatus
	POP	B
	POP	D
	POP	H
	POP	PSW
	EI
	RET

i_8:	DB	0

animateSprites:
	LXI	B,0
	MOV	A,C
	STA	i_8
as02:
	LHLD	frameNumber
	MOV	A,L
	ADC	C
	MOV	L,A
	JNC	$+4
	INR	H
CheckTbl:
	LXI	D, sinEnd - sinTbl
	MOV	A,L
	SUB	E
	MOV	E,A
	MOV	A,H
	SBB	D
	JC	as01
	MOV	H,A
	MOV	L,E
	JMP	CheckTbl
	;SHLD	frameNumber
as01:	XCHG
	LXI	H,sinTbl
	DAD	D
	PUSH	B

	LXI	B, T_DEF_VRAM_SPR_ATTR_ADDRESS
	LDA	i_8
	ADD	C
	MOV	C,A
	JNC	$+4
	INR	B
	MOV	D,B
	MOV	E,C
	MVI	A,4
	ADD	C
	MOV	C,A
	JNC	$+4
	INR	B
	CALL	T_SetAddrWrite

	LDA	frameNumber+1
	RAR
	LDA	frameNumber
	RAR
	POP	B
	PUSH	B
	ADD	B
	ADI	24
	CPI	0D0h
	JNZ	$+4
	INR	A
	OUT	VDP ; WriteData
	PUSH	PSW
	MOV	A,M
	OUT	VDP

	MOV	B,D
	MOV	C,E
	CALL	T_SetAddrWrite
	POP	PSW

	CPI	0D2h
	JNZ	$+4
	INR	A
	SUI	2
	OUT	VDP
	MOV	A,M
	SUI	2
	OUT	VDP

	MOV	B,D
	MOV	C,E
	INX	B
	INX	B
	CALL	T_SetAddrRead
	IN	VDP
	PUSH	PSW
	CALL	T_SetAddrWrite
	POP	PSW
	OUT	VDP

	POP	B
	LDA	i_8
	ADI	8
	STA	i_8
	MOV	A,C
	ADI	7
	MOV	C,A
	MOV	A,B
	ADI	10
	MOV	B,A
	CPI	130
	JNZ	as02
	RET

str:	DB 'Hello, World!'
strLen  EQU 13
include 9918.asm

T_InitialiseGfxII:
	MVI	B, T_REG_0
	MVI	C, T_R0_EXT_VDP_DISABLE OR T_R0_MODE_GR_II
	CALL	T_WriteRegValue

	MVI	B, T_REG_1
	MVI	C, T_R1_RAM_16K or T_R1_MODE_GRAPHICS_II OR T_R1_DISP_ACTIVE OR T_R1_INT_ENABLE OR T_R1_SPR_MAG2
	CALL	T_WriteRegValue

	; T_SetNameTableAddr
	MVI	B, T_REG_NAME_TABLE
	MVI	C, (T_DEF_VRAM_NAME_ADDRESS SHR 10) 
	CALL	T_WriteRegValue

	MVI	B, T_REG_COLOR_TABLE
	MVI	C, 7fh
	CALL	T_WriteRegValue

	MVI	B, T_REG_PATTERN_TABLE
	MVI	C, 7
	CALL	T_WriteRegValue

	; T_SetSpriteAttrTableAddr
	MVI	B, T_REG_SPRITE_ATTR_TABLE
	MVI	C, T_DEF_VRAM_SPR_ATTR_ADDRESS SHR 7
	CALL	T_WriteRegValue

	; T_SetSpritePattTableAddr
	MVI	B, T_REG_SPRITE_PATT_TABLE
	MVI	C, T_DEF_VRAM_SPR_PATT_ADDRESS SHR 11
	CALL	T_WriteRegValue

	MVI	B, T_REG_FG_BG_COLOR
	MVI	C, (T_BLACK shl 4) or T_CYAN
	CALL	T_WriteRegValue

	LXI	B, T_DEF_VRAM_NAME_ADDRESS
	CALL	T_SetAddrWrite

	LXI	D,0
@20:	MOV	C,E
	CALL	T_WriteData
	INX	D
	MOV	A,D
	CPI	768 / 256
	JNZ	@20
	RET

include 9918font.asm

BREAKOUT_TIAC:
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 0d1h, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh
 DB 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 01fh, 01eh, 01eh, 011h, 011h, 011h, 018h, 01bh
 DB 0f1h, 01eh, 01eh, 01eh, 0e1h, 01eh, 018h, 01bh, 01fh, 01eh, 01eh, 011h, 011h, 011h, 018h, 01bh
 DB 0f1h, 01eh, 01eh, 01eh, 0e1h, 01eh, 018h, 01bh, 01fh, 01eh, 01eh, 0e1h, 0e1h, 0e1h, 018h, 01bh
 DB 01fh, 01eh, 01eh, 011h, 011h, 011h, 018h, 01bh, 0f1h, 0e1h, 01eh, 0e1h, 01eh, 0e1h, 081h, 01bh
 DB 0f1h, 0e1h, 0e1h, 0e1h, 0e1h, 0e1h, 081h, 01bh, 0f1h, 0e1h, 0e1h, 0e1h, 01eh, 01eh, 018h, 01bh
 DB 01fh, 01eh, 01eh, 0e1h, 0e1h, 0e1h, 081h, 011h, 0f1h, 01eh, 01eh, 01eh, 0e1h, 0e1h, 081h, 0b1h
 DB 0f1h, 0e1h, 01eh, 01eh, 0e1h, 01eh, 081h, 0b1h, 0f1h, 0e1h, 0e1h, 0e1h, 0e1h, 0e1h, 081h, 0b1h
 DB 0f1h, 0e1h, 0e1h, 0e1h, 0e1h, 0e1h, 081h, 0b1h, 01fh, 01eh, 01eh, 0e1h, 0e1h, 0e1h, 081h, 0b1h
 DB 01fh, 01eh, 01eh, 0e1h, 0e1h, 0e1h, 081h, 0b1h, 011h, 011h, 011h, 011h, 011h, 011h, 018h, 01bh
 DB 011h, 011h, 011h, 011h, 011h, 011h, 081h, 0b1h, 01fh, 01eh, 01eh, 0e1h, 0e1h, 0e1h, 018h, 01bh
 DB 01fh, 01eh, 01eh, 011h, 011h, 011h, 018h, 01bh, 0f1h, 01eh, 01eh, 01eh, 01eh, 0e1h, 018h, 01bh
 DB 01fh, 01eh, 01eh, 011h, 011h, 011h, 081h, 01bh, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh
 DB 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 0fdh, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 012h, 051h, 051h, 051h, 015h, 015h, 014h, 011h
 DB 012h, 015h, 051h, 015h, 015h, 015h, 014h, 011h, 012h, 015h, 051h, 051h, 051h, 051h, 041h, 011h
 DB 021h, 051h, 051h, 051h, 015h, 015h, 014h, 011h, 012h, 051h, 051h, 051h, 015h, 015h, 014h, 011h
 DB 012h, 011h, 011h, 011h, 015h, 015h, 014h, 011h, 021h, 051h, 015h, 051h, 015h, 015h, 014h, 011h
 DB 021h, 051h, 015h, 051h, 015h, 015h, 014h, 011h, 012h, 015h, 015h, 051h, 051h, 051h, 041h, 011h
 DB 021h, 051h, 051h, 051h, 015h, 015h, 014h, 011h, 021h, 051h, 051h, 015h, 015h, 015h, 041h, 011h
 DB 021h, 015h, 051h, 015h, 015h, 051h, 041h, 011h, 021h, 051h, 015h, 015h, 015h, 015h, 041h, 011h
 DB 012h, 015h, 015h, 015h, 015h, 051h, 041h, 011h, 021h, 051h, 051h, 051h, 051h, 051h, 041h, 011h
 DB 021h, 051h, 051h, 051h, 051h, 051h, 041h, 011h, 012h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 021h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 012h, 011h, 011h, 011h, 015h, 015h, 014h, 011h
 DB 012h, 015h, 015h, 015h, 015h, 015h, 014h, 011h, 012h, 051h, 015h, 015h, 015h, 015h, 041h, 011h
 DB 012h, 015h, 051h, 015h, 015h, 015h, 041h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 0f1h, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh
 DB 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 01fh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h
 DB 0dfh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 0d1h, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh
 DB 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh
 DB 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh
 DB 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 019h, 098h, 098h, 098h, 098h, 098h, 016h, 011h
 DB 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h, 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h
 DB 019h, 098h, 098h, 098h, 098h, 098h, 016h, 011h, 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h
 DB 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h, 019h, 098h, 098h, 098h, 098h, 098h, 016h, 011h
 DB 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h, 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h
 DB 019h, 098h, 098h, 098h, 098h, 098h, 016h, 011h, 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h
 DB 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h, 019h, 098h, 098h, 098h, 098h, 098h, 016h, 011h
 DB 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h, 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h
 DB 019h, 098h, 098h, 098h, 098h, 098h, 016h, 011h, 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h
 DB 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h, 019h, 098h, 098h, 098h, 098h, 098h, 016h, 011h
 DB 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h, 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h
 DB 019h, 098h, 098h, 098h, 098h, 098h, 016h, 011h, 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h
 DB 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h, 019h, 098h, 098h, 098h, 098h, 098h, 016h, 011h
 DB 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h, 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h
 DB 019h, 098h, 098h, 098h, 098h, 098h, 016h, 011h, 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h
 DB 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh
 DB 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 019h, 098h, 098h, 098h, 098h, 098h, 016h, 011h
 DB 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h, 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h
 DB 019h, 098h, 098h, 098h, 098h, 098h, 016h, 011h, 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h
 DB 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h, 019h, 098h, 098h, 098h, 098h, 098h, 016h, 011h
 DB 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h, 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h
 DB 019h, 098h, 098h, 098h, 098h, 098h, 016h, 011h, 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h
 DB 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h, 019h, 098h, 098h, 098h, 098h, 098h, 016h, 011h
 DB 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h, 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h
 DB 019h, 098h, 098h, 098h, 098h, 098h, 016h, 011h, 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h
 DB 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h, 019h, 098h, 098h, 098h, 098h, 098h, 016h, 011h
 DB 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h, 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h
 DB 019h, 098h, 098h, 098h, 098h, 098h, 016h, 011h, 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h
 DB 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h, 019h, 098h, 098h, 098h, 098h, 098h, 016h, 011h
 DB 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h, 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h
 DB 019h, 098h, 098h, 098h, 098h, 098h, 016h, 011h, 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h
 DB 019h, 018h, 018h, 018h, 018h, 018h, 016h, 011h, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh
 DB 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01fh, 0fbh, 0fbh, 0fbh, 0fbh, 0fbh, 01ah, 011h
 DB 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h, 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h
 DB 01fh, 0fbh, 0fbh, 0fbh, 0fbh, 0fbh, 01ah, 011h, 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h
 DB 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h, 01fh, 0fbh, 0fbh, 0fbh, 0fbh, 0fbh, 01ah, 011h
 DB 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h, 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h
 DB 01fh, 0fbh, 0fbh, 0fbh, 0fbh, 0fbh, 01ah, 011h, 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h
 DB 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h, 01fh, 0fbh, 0fbh, 0fbh, 0fbh, 0fbh, 01ah, 011h
 DB 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h, 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h
 DB 01fh, 0fbh, 0fbh, 0fbh, 0fbh, 0fbh, 01ah, 011h, 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h
 DB 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h, 01fh, 0fbh, 0fbh, 0fbh, 0fbh, 0fbh, 01ah, 011h
 DB 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h, 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h
 DB 01fh, 0fbh, 0fbh, 0fbh, 0fbh, 0fbh, 01ah, 011h, 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h
 DB 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h, 01fh, 0fbh, 0fbh, 0fbh, 0fbh, 0fbh, 01ah, 011h
 DB 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h, 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h
 DB 01fh, 0fbh, 0fbh, 0fbh, 0fbh, 0fbh, 01ah, 011h, 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h
 DB 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh
 DB 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01fh, 0fbh, 0fbh, 0fbh, 0fbh, 0fbh, 01ah, 011h
 DB 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h, 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h
 DB 01fh, 0fbh, 0fbh, 0fbh, 0fbh, 0fbh, 01ah, 011h, 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h
 DB 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h, 01fh, 0fbh, 0fbh, 0fbh, 0fbh, 0fbh, 01ah, 011h
 DB 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h, 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h
 DB 01fh, 0fbh, 0fbh, 0fbh, 0fbh, 0fbh, 01ah, 011h, 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h
 DB 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h, 01fh, 0fbh, 0fbh, 0fbh, 0fbh, 0fbh, 01ah, 011h
 DB 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h, 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h
 DB 01fh, 0fbh, 0fbh, 0fbh, 0fbh, 0fbh, 01ah, 011h, 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h
 DB 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h, 01fh, 0fbh, 0fbh, 0fbh, 0fbh, 0fbh, 01ah, 011h
 DB 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h, 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h
 DB 01fh, 0fbh, 0fbh, 0fbh, 0fbh, 0fbh, 01ah, 011h, 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h
 DB 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h, 01fh, 0fbh, 0fbh, 0fbh, 0fbh, 0fbh, 01ah, 011h
 DB 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h, 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h
 DB 01fh, 0fbh, 0fbh, 0fbh, 0fbh, 0fbh, 01ah, 011h, 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h
 DB 01fh, 01bh, 01bh, 01bh, 01bh, 01bh, 01ah, 011h, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh
 DB 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 013h, 032h, 032h, 032h, 032h, 032h, 01ch, 011h
 DB 013h, 012h, 0c2h, 0c2h, 0c2h, 0c2h, 01ch, 011h, 013h, 012h, 012h, 012h, 012h, 012h, 01ch, 011h
 DB 013h, 032h, 032h, 032h, 032h, 032h, 01ch, 011h, 013h, 012h, 0c2h, 0c2h, 0c2h, 0c2h, 01ch, 011h
 DB 013h, 012h, 012h, 012h, 012h, 012h, 01ch, 011h, 013h, 032h, 032h, 032h, 032h, 032h, 01ch, 011h
 DB 013h, 012h, 0c2h, 0c2h, 0c2h, 0c2h, 01ch, 011h, 013h, 012h, 012h, 012h, 012h, 012h, 01ch, 011h
 DB 013h, 032h, 032h, 032h, 032h, 032h, 01ch, 011h, 013h, 012h, 0c2h, 0c2h, 0c2h, 0c2h, 01ch, 011h
 DB 013h, 012h, 012h, 012h, 012h, 012h, 01ch, 011h, 013h, 032h, 032h, 032h, 032h, 032h, 01ch, 011h
 DB 013h, 012h, 0c2h, 0c2h, 0c2h, 0c2h, 01ch, 011h, 013h, 012h, 012h, 012h, 012h, 012h, 01ch, 011h
 DB 013h, 032h, 032h, 032h, 032h, 032h, 01ch, 011h, 013h, 012h, 0c2h, 0c2h, 0c2h, 0c2h, 01ch, 011h
 DB 013h, 012h, 012h, 012h, 012h, 012h, 01ch, 011h, 013h, 032h, 032h, 032h, 032h, 032h, 01ch, 011h
 DB 013h, 012h, 0c2h, 0c2h, 0c2h, 0c2h, 01ch, 011h, 013h, 012h, 012h, 012h, 012h, 012h, 01ch, 011h
 DB 013h, 032h, 032h, 032h, 032h, 032h, 01ch, 011h, 013h, 012h, 0c2h, 0c2h, 0c2h, 0c2h, 01ch, 011h
 DB 013h, 012h, 012h, 012h, 012h, 012h, 01ch, 011h, 013h, 032h, 032h, 032h, 032h, 032h, 01ch, 011h
 DB 013h, 012h, 0c2h, 0c2h, 0c2h, 0c2h, 01ch, 011h, 013h, 012h, 012h, 012h, 012h, 012h, 01ch, 011h
 DB 013h, 032h, 032h, 032h, 032h, 032h, 01ch, 011h, 013h, 012h, 0c2h, 0c2h, 0c2h, 0c2h, 01ch, 011h
 DB 013h, 012h, 012h, 012h, 012h, 012h, 01ch, 011h, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh
 DB 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 013h, 032h, 032h, 032h, 032h, 032h, 01ch, 011h
 DB 013h, 012h, 0c2h, 0c2h, 0c2h, 0c2h, 01ch, 011h, 013h, 012h, 012h, 012h, 012h, 012h, 01ch, 011h
 DB 013h, 032h, 032h, 032h, 032h, 032h, 01ch, 011h, 013h, 012h, 0c2h, 0c2h, 0c2h, 0c2h, 01ch, 011h
 DB 013h, 012h, 012h, 012h, 012h, 012h, 01ch, 011h, 013h, 032h, 032h, 032h, 032h, 032h, 01ch, 011h
 DB 013h, 012h, 0c2h, 0c2h, 0c2h, 0c2h, 01ch, 011h, 013h, 012h, 012h, 012h, 012h, 012h, 01ch, 011h
 DB 013h, 032h, 032h, 032h, 032h, 032h, 01ch, 011h, 013h, 012h, 0c2h, 0c2h, 0c2h, 0c2h, 01ch, 011h
 DB 013h, 012h, 012h, 012h, 012h, 012h, 01ch, 011h, 013h, 032h, 032h, 032h, 032h, 032h, 01ch, 011h
 DB 013h, 012h, 0c2h, 0c2h, 0c2h, 0c2h, 01ch, 011h, 013h, 012h, 012h, 012h, 012h, 012h, 01ch, 011h
 DB 013h, 032h, 032h, 032h, 032h, 032h, 01ch, 011h, 013h, 012h, 0c2h, 0c2h, 0c2h, 0c2h, 01ch, 011h
 DB 013h, 012h, 012h, 012h, 012h, 012h, 01ch, 011h, 013h, 032h, 032h, 032h, 032h, 032h, 01ch, 011h
 DB 013h, 012h, 0c2h, 0c2h, 0c2h, 0c2h, 01ch, 011h, 013h, 012h, 012h, 012h, 012h, 012h, 01ch, 011h
 DB 013h, 032h, 032h, 032h, 032h, 032h, 01ch, 011h, 013h, 012h, 0c2h, 0c2h, 0c2h, 0c2h, 01ch, 011h
 DB 013h, 012h, 012h, 012h, 012h, 012h, 01ch, 011h, 013h, 032h, 032h, 032h, 032h, 032h, 01ch, 011h
 DB 013h, 012h, 0c2h, 0c2h, 0c2h, 0c2h, 01ch, 011h, 013h, 012h, 012h, 012h, 012h, 012h, 01ch, 011h
 DB 013h, 032h, 032h, 032h, 032h, 032h, 01ch, 011h, 013h, 012h, 0c2h, 0c2h, 0c2h, 0c2h, 01ch, 011h
 DB 013h, 012h, 012h, 012h, 012h, 012h, 01ch, 011h, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh
 DB 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 017h, 075h, 075h, 075h, 075h, 075h, 014h, 011h
 DB 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h, 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h
 DB 017h, 075h, 075h, 075h, 075h, 075h, 014h, 011h, 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h
 DB 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h, 017h, 075h, 075h, 075h, 075h, 075h, 014h, 011h
 DB 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h, 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h
 DB 017h, 075h, 075h, 075h, 075h, 075h, 014h, 011h, 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h
 DB 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h, 017h, 075h, 075h, 075h, 075h, 075h, 014h, 011h
 DB 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h, 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h
 DB 017h, 075h, 075h, 075h, 075h, 075h, 014h, 011h, 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h
 DB 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h, 017h, 075h, 075h, 075h, 075h, 075h, 014h, 011h
 DB 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h, 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h
 DB 017h, 075h, 075h, 075h, 075h, 075h, 014h, 011h, 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h
 DB 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h, 017h, 075h, 075h, 075h, 075h, 075h, 014h, 011h
 DB 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h, 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h
 DB 017h, 075h, 075h, 075h, 075h, 075h, 014h, 011h, 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h
 DB 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh
 DB 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 017h, 075h, 075h, 075h, 075h, 075h, 014h, 011h
 DB 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h, 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h
 DB 017h, 075h, 075h, 075h, 075h, 075h, 014h, 011h, 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h
 DB 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h, 017h, 075h, 075h, 075h, 075h, 075h, 014h, 011h
 DB 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h, 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h
 DB 017h, 075h, 075h, 075h, 075h, 075h, 014h, 011h, 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h
 DB 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h, 017h, 075h, 075h, 075h, 075h, 075h, 014h, 011h
 DB 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h, 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h
 DB 017h, 075h, 075h, 075h, 075h, 075h, 014h, 011h, 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h
 DB 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h, 017h, 075h, 075h, 075h, 075h, 075h, 014h, 011h
 DB 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h, 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h
 DB 017h, 075h, 075h, 075h, 075h, 075h, 014h, 011h, 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h
 DB 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h, 017h, 075h, 075h, 075h, 075h, 075h, 014h, 011h
 DB 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h, 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h
 DB 017h, 075h, 075h, 075h, 075h, 075h, 014h, 011h, 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h
 DB 017h, 015h, 015h, 015h, 015h, 015h, 014h, 011h, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh
 DB 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh
 DB 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 041h, 041h
 DB 011h, 011h, 011h, 011h, 011h, 041h, 041h, 041h, 011h, 011h, 011h, 011h, 011h, 041h, 041h, 014h
 DB 011h, 011h, 011h, 011h, 011h, 041h, 041h, 041h, 011h, 011h, 011h, 011h, 011h, 041h, 041h, 041h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 041h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 041h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh
 DB 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 041h
 DB 011h, 011h, 011h, 011h, 041h, 041h, 014h, 014h, 011h, 011h, 041h, 041h, 014h, 014h, 054h, 043h
 DB 041h, 041h, 041h, 014h, 034h, 035h, 0e5h, 0e5h, 041h, 014h, 054h, 035h, 053h, 0e5h, 045h, 0c4h
 DB 014h, 014h, 0c5h, 035h, 0c5h, 045h, 034h, 0c4h, 014h, 014h, 0c5h, 045h, 015h, 0c5h, 015h, 035h
 DB 014h, 014h, 0c5h, 035h, 0e5h, 0c5h, 0c5h, 0c5h, 014h, 014h, 0c5h, 035h, 035h, 015h, 035h, 035h
 DB 041h, 014h, 014h, 054h, 035h, 025h, 015h, 0c5h, 041h, 041h, 041h, 014h, 054h, 035h, 035h, 035h
 DB 011h, 041h, 041h, 041h, 041h, 014h, 014h, 045h, 011h, 011h, 011h, 011h, 041h, 041h, 041h, 014h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 041h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh
 DB 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 041h
 DB 011h, 011h, 041h, 041h, 041h, 014h, 014h, 014h, 041h, 014h, 014h, 014h, 034h, 034h, 0e5h, 045h
 DB 014h, 034h, 04eh, 0e5h, 035h, 0c4h, 014h, 014h, 05eh, 05eh, 0e5h, 054h, 0c5h, 0c5h, 0e5h, 0c4h
 DB 0c5h, 015h, 0c4h, 045h, 0c5h, 0d5h, 05eh, 05eh, 0c4h, 0c5h, 0c5h, 035h, 05eh, 03dh, 0e5h, 0c5h
 DB 054h, 0c5h, 0c5h, 05eh, 0deh, 0e5h, 0e5h, 0cdh, 0c5h, 015h, 0c5h, 0edh, 03eh, 05eh, 05eh, 0deh
 DB 0c5h, 0e5h, 0e5h, 05eh, 0aeh, 0deh, 0edh, 03dh, 05eh, 0deh, 0deh, 05eh, 0deh, 05eh, 03dh, 035h
 DB 054h, 0e5h, 05eh, 05eh, 0edh, 03dh, 03dh, 0cdh, 045h, 0c5h, 0e5h, 03dh, 0d5h, 0c5h, 02dh, 0cdh
 DB 035h, 035h, 035h, 05eh, 03dh, 03dh, 03dh, 03dh, 054h, 034h, 035h, 035h, 035h, 0e5h, 035h, 03dh
 DB 041h, 041h, 041h, 014h, 054h, 035h, 035h, 035h, 011h, 011h, 041h, 041h, 041h, 041h, 014h, 014h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 041h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh
 DB 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 041h
 DB 011h, 011h, 041h, 011h, 041h, 041h, 014h, 014h, 041h, 014h, 014h, 014h, 014h, 0c4h, 054h, 0c4h
 DB 034h, 054h, 0c4h, 014h, 014h, 0c4h, 0c4h, 0c4h, 034h, 014h, 0c4h, 0c4h, 0c4h, 0c4h, 0c4h, 0c4h
 DB 014h, 014h, 0c4h, 0c4h, 0c4h, 0c4h, 014h, 014h, 0c4h, 0c4h, 014h, 014h, 014h, 014h, 014h, 0c4h
 DB 0c5h, 0c4h, 014h, 0c4h, 014h, 014h, 014h, 0c4h, 0d5h, 0c4h, 014h, 014h, 014h, 014h, 0c4h, 064h
 DB 045h, 0c4h, 0c4h, 014h, 014h, 0c4h, 014h, 0c4h, 0deh, 01eh, 0deh, 0deh, 0ceh, 03dh, 04dh, 0c4h
 DB 03dh, 0deh, 02dh, 0cdh, 0d4h, 04ch, 0cdh, 0c4h, 0d4h, 0c4h, 0c4h, 0d4h, 0c4h, 014h, 014h, 014h
 DB 0cdh, 0cdh, 0cdh, 0c4h, 0c4h, 04ch, 046h, 04ch, 0cdh, 0cdh, 0d4h, 0c4h, 0cdh, 0dch, 0c4h, 0c6h
 DB 025h, 0cdh, 0cdh, 0cdh, 05ch, 0cdh, 0cdh, 0dch, 035h, 0d5h, 0c5h, 0c5h, 0c5h, 0cdh, 05ch, 0cdh
 DB 035h, 025h, 0c5h, 0c5h, 0c5h, 0cdh, 0c5h, 0cdh, 054h, 035h, 0c5h, 035h, 0c5h, 0c5h, 0c5h, 0c5h
 DB 041h, 041h, 014h, 014h, 0c4h, 054h, 0c5h, 0c5h, 011h, 011h, 011h, 041h, 011h, 041h, 041h, 041h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh
 DB 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 041h, 041h, 011h, 041h, 041h, 041h, 014h, 014h, 014h, 014h
 DB 014h, 014h, 0c4h, 0c4h, 0c4h, 0c4h, 014h, 014h, 0c4h, 0c4h, 0c4h, 0c4h, 014h, 0c4h, 054h, 04ch
 DB 0c4h, 0c4h, 0c4h, 014h, 0c4h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 041h
 DB 014h, 014h, 014h, 014h, 041h, 014h, 0c4h, 014h, 041h, 014h, 014h, 014h, 041h, 014h, 01ch, 064h
 DB 014h, 0c4h, 0c1h, 0c4h, 01ch, 0c4h, 046h, 0dch, 0c1h, 084h, 0c4h, 0cdh, 0d4h, 01ch, 064h, 01ch
 DB 014h, 041h, 014h, 041h, 014h, 041h, 014h, 04ch, 014h, 01ch, 064h, 01ch, 014h, 01ch, 064h, 06ch
 DB 01ch, 064h, 01ch, 0c4h, 041h, 0c4h, 06ch, 0c4h, 0c4h, 014h, 014h, 014h, 01ch, 0c4h, 0c6h, 0cdh
 DB 01ch, 064h, 0dch, 0dch, 0c4h, 0c6h, 04ch, 0c6h, 04ch, 0dch, 0c4h, 06ch, 0c4h, 0c6h, 0c4h, 0c6h
 DB 0cdh, 04ch, 0cdh, 0dch, 0dch, 0cdh, 0dch, 0cdh, 0dch, 0cdh, 0cdh, 0cdh, 0d3h, 0edh, 0dch, 0cdh
 DB 025h, 0cdh, 0dch, 0c5h, 0cdh, 03dh, 0cdh, 0dch, 025h, 0e5h, 0cdh, 0c5h, 0cdh, 0c5h, 0cdh, 0cdh
 DB 0c5h, 0c5h, 0c5h, 0c5h, 0c5h, 0c5h, 0c5h, 0cdh, 014h, 014h, 054h, 0c4h, 045h, 0c5h, 045h, 0c5h
 DB 011h, 041h, 011h, 041h, 041h, 041h, 014h, 014h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 041h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh
 DB 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 041h, 011h, 041h
 DB 041h, 041h, 041h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h
 DB 014h, 014h, 014h, 0c4h, 0d4h, 0c4h, 014h, 0c4h, 04dh, 0c5h, 0d5h, 0c5h, 064h, 0c4h, 014h, 014h
 DB 014h, 041h, 0c4h, 014h, 064h, 014h, 0c4h, 041h, 014h, 014h, 014h, 04ch, 014h, 0c4h, 041h, 041h
 DB 0c4h, 0d1h, 014h, 0c1h, 014h, 041h, 014h, 041h, 01ch, 04dh, 01ch, 014h, 0c1h, 014h, 041h, 041h
 DB 0cdh, 04ch, 014h, 01ch, 014h, 041h, 041h, 014h, 0c4h, 0c6h, 0c1h, 064h, 01ch, 014h, 01ch, 0c6h
 DB 01ch, 064h, 01ch, 046h, 06ch, 01ch, 064h, 01ch, 04ch, 0c6h, 01ch, 064h, 01ch, 0c4h, 016h, 04ch
 DB 0c6h, 04ch, 0c6h, 04ch, 06ch, 0c4h, 0c6h, 0c4h, 0dch, 0cdh, 0cdh, 06ch, 04ch, 0c6h, 0c1h, 0dch
 DB 04ch, 0c6h, 0c4h, 0c6h, 04ch, 0c6h, 0c4h, 01ch, 04ch, 06ch, 0c4h, 016h, 0dch, 0cdh, 0dch, 0cdh
 DB 0cdh, 0dch, 0cdh, 0dch, 0cdh, 0dch, 0cdh, 0dch, 0dch, 0dch, 0dch, 0cdh, 0dch, 0dch, 0dch, 0dch
 DB 0dch, 0dch, 0dch, 0dch, 0dch, 0dch, 0dch, 0cdh, 05ch, 0cdh, 0dch, 0cdh, 0cdh, 0cdh, 03dh, 0cdh
 DB 0c4h, 0cdh, 0c5h, 0cdh, 0cdh, 0cdh, 0cdh, 0cdh, 0d5h, 0c5h, 0cdh, 0cdh, 0d5h, 0cdh, 0cdh, 0cdh
 DB 014h, 0c4h, 045h, 054h, 0c5h, 0d5h, 0c5h, 05dh, 011h, 041h, 041h, 041h, 041h, 014h, 014h, 014h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 041h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh
 DB 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h
 DB 011h, 011h, 011h, 011h, 011h, 041h, 011h, 041h, 041h, 041h, 041h, 014h, 014h, 014h, 014h, 014h
 DB 014h, 0c4h, 014h, 014h, 014h, 0c4h, 014h, 014h, 0c4h, 0c4h, 014h, 0c4h, 014h, 041h, 014h, 041h
 DB 014h, 014h, 014h, 014h, 0c4h, 014h, 0c4h, 041h, 0c4h, 014h, 014h, 01ch, 014h, 041h, 0c4h, 041h
 DB 014h, 041h, 014h, 041h, 0c1h, 041h, 014h, 041h, 0c1h, 014h, 041h, 041h, 014h, 01ch, 014h, 0c1h
 DB 04ch, 014h, 0c1h, 014h, 0c1h, 014h, 01ch, 014h, 041h, 014h, 0c1h, 014h, 0c1h, 041h, 041h, 041h
 DB 01ch, 04ch, 046h, 01ch, 01dh, 01ch, 061h, 014h, 0c4h, 0c6h, 01ch, 046h, 01ch, 0c6h, 01ch, 064h
 DB 046h, 01ch, 064h, 01ch, 0c6h, 014h, 01ch, 0c6h, 0c6h, 01ch, 04ch, 016h, 04ch, 0c6h, 064h, 01ch
 DB 0c6h, 04ch, 0c6h, 0c1h, 0c4h, 016h, 01ch, 014h, 01dh, 01ch, 0c6h, 04ch, 01ch, 0c6h, 014h, 01ch
 DB 064h, 01ch, 046h, 01ch, 064h, 01ch, 064h, 01ch, 01dh, 06ch, 01dh, 01ch, 0c4h, 0c6h, 01ch, 0c4h
 DB 0dch, 0c6h, 0cdh, 0cdh, 06ch, 0c4h, 0c6h, 0dch, 0dch, 0cdh, 04ch, 0c6h, 04ch, 016h, 014h, 01ch
 DB 0dch, 0dch, 0c6h, 0c4h, 061h, 014h, 01ch, 0c4h, 0cdh, 0cdh, 0c6h, 0cdh, 0dch, 0c6h, 0c4h, 06ch
 DB 0cdh, 0cdh, 0cdh, 064h, 0c4h, 0d1h, 064h, 01ch, 0cdh, 03dh, 03dh, 01ch, 04dh, 01eh, 04dh, 013h
 DB 03dh, 0cdh, 03dh, 0d5h, 03dh, 0e4h, 0d3h, 0deh, 054h, 0c5h, 0d4h, 035h, 0d5h, 0cdh, 0e5h, 0cdh
 DB 041h, 041h, 041h, 041h, 041h, 014h, 014h, 0c4h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 041h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh
 DB 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 011h, 011h, 011h, 011h, 011h, 041h, 011h, 011h
 DB 041h, 041h, 041h, 041h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h
 DB 014h, 014h, 014h, 041h, 041h, 041h, 041h, 041h, 014h, 041h, 041h, 014h, 014h, 014h, 01ch, 041h
 DB 0c4h, 041h, 0c4h, 041h, 0c1h, 041h, 014h, 01ch, 0c1h, 041h, 041h, 041h, 041h, 014h, 041h, 041h
 DB 014h, 01ch, 014h, 01ch, 014h, 0c1h, 014h, 0c1h, 041h, 014h, 041h, 014h, 0c1h, 041h, 014h, 041h
 DB 0c1h, 041h, 041h, 041h, 041h, 0c1h, 041h, 01ch, 041h, 041h, 041h, 014h, 014h, 0c1h, 01dh, 06ch
 DB 0c1h, 014h, 061h, 014h, 01ch, 016h, 01ch, 064h, 0c1h, 01ch, 01dh, 01ch, 016h, 0c4h, 061h, 0c1h
 DB 014h, 06ch, 01ch, 046h, 0c1h, 041h, 041h, 041h, 0c6h, 0c4h, 016h, 0c1h, 014h, 0c1h, 041h, 041h
 DB 0c1h, 0d1h, 0c1h, 041h, 0c1h, 064h, 0c1h, 01ch, 01ch, 0d1h, 01ch, 014h, 01ch, 016h, 014h, 041h
 DB 046h, 01ch, 0c4h, 016h, 01ch, 0c1h, 0c4h, 061h, 016h, 04ch, 016h, 04ch, 0c6h, 01ch, 0c4h, 01ch
 DB 0dch, 0c4h, 016h, 04ch, 01ch, 01dh, 01ch, 0d1h, 041h, 041h, 041h, 041h, 041h, 041h, 041h, 041h
 DB 01ch, 041h, 041h, 041h, 041h, 041h, 041h, 041h, 0c4h, 016h, 04ch, 01dh, 014h, 041h, 041h, 014h
 DB 04dh, 0c6h, 0c4h, 06ch, 04ch, 064h, 01ch, 046h, 049h, 01eh, 014h, 041h, 0c1h, 014h, 0c1h, 064h
 DB 0edh, 0deh, 0deh, 03dh, 0deh, 04eh, 01dh, 034h, 04dh, 035h, 0cdh, 03dh, 02dh, 03dh, 03dh, 03dh
 DB 014h, 0c4h, 0c4h, 045h, 0c4h, 0d5h, 0c5h, 0d4h, 011h, 041h, 041h, 041h, 041h, 041h, 014h, 014h
 DB 011h, 011h, 011h, 011h, 011h, 011h, 011h, 011h, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh
 DB 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 0d1h, 041h, 041h, 041h, 041h, 041h, 041h, 041h, 014h
 DB 014h, 014h, 014h, 014h, 014h, 014h, 041h, 014h, 014h, 041h, 014h, 014h, 041h, 041h, 014h, 041h
 DB 041h, 014h, 041h, 014h, 041h, 041h, 041h, 014h, 041h, 041h, 014h, 014h, 01ch, 014h, 01ch, 014h
 DB 041h, 041h, 0c1h, 014h, 016h, 041h, 0c1h, 041h, 014h, 01ch, 014h, 01ch, 014h, 01ch, 014h, 0c1h
 DB 014h, 041h, 014h, 0c1h, 014h, 0c1h, 014h, 0d1h, 041h, 041h, 041h, 041h, 0c1h, 014h, 051h, 014h
 DB 014h, 016h, 01ch, 01dh, 0c1h, 046h, 01ch, 016h, 061h, 0cdh, 016h, 0c6h, 0d1h, 0c6h, 046h, 0c6h
 DB 061h, 06ch, 046h, 016h, 01ch, 0d1h, 0c1h, 061h, 041h, 061h, 041h, 041h, 041h, 011h, 041h, 041h
 DB 041h, 041h, 041h, 041h, 041h, 041h, 041h, 041h, 041h, 041h, 041h, 041h, 041h, 0c1h, 061h, 041h
 DB 01dh, 01ch, 014h, 0c1h, 041h, 041h, 041h, 041h, 041h, 041h, 061h, 01ch, 01dh, 01ch, 041h, 0c1h
 DB 01ch, 041h, 01ch, 014h, 01ch, 0d1h, 0c1h, 041h, 0c6h, 041h, 01ch, 064h, 0c1h, 0d1h, 0c1h, 0d1h
 DB 0c1h, 064h, 01ch, 016h, 041h, 01ch, 014h, 051h, 041h, 041h, 041h, 01ch, 014h, 0c6h, 016h, 0c6h
 DB 01ch, 0c4h, 016h, 06ch, 046h, 0c6h, 0c6h, 0cdh, 01ch, 0d4h, 01ch, 0c6h, 064h, 0c6h, 046h, 0c6h
 DB 06ch, 0cdh, 0c6h, 046h, 06ch, 046h, 0c6h, 064h, 06ch, 046h, 06ch, 046h, 06ch, 0cdh, 0c6h, 06dh
 DB 01dh, 01ch, 014h, 0d1h, 014h, 0c1h, 041h, 0d1h, 0adh, 03dh, 03dh, 03dh, 0cdh, 0cdh, 01dh, 04ch
 DB 0cdh, 0d4h, 0cdh, 0cdh, 0cdh, 0cdh, 0cdh, 0cdh, 0c4h, 014h, 054h, 0c4h, 045h, 0c4h, 0d4h, 0c5h
 DB 011h, 041h, 041h, 011h, 041h, 041h, 041h, 041h, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 01dh, 0d1h

;/* source: D:/GitHub/pico9918/test/host/res\BREAKOUT.TIAP
; * size  : 6144 bytes */
BREAKOUT_TIAP:
 DB 0c0h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h, 007h, 003h, 001h, 001h, 001h, 001h, 001h, 001h
 DB 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0c0h, 080h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 0f0h, 003h, 001h, 0e1h, 00eh, 0e1h, 003h, 007h, 0c0h, 080h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 0f0h, 003h, 001h, 0e1h, 00eh, 0e1h, 001h, 003h, 000h, 000h, 000h, 0e0h, 0e0h, 0e0h, 000h, 000h
 DB 001h, 003h, 007h, 000h, 000h, 000h, 001h, 003h, 003h, 007h, 0f0h, 00eh, 0e1h, 01ch, 01ch, 0c3h
 DB 080h, 0c0h, 0e0h, 0e0h, 0f0h, 070h, 070h, 087h, 070h, 070h, 070h, 070h, 08eh, 08ch, 080h, 080h
 DB 0e1h, 0c3h, 087h, 0f0h, 0e0h, 0c0h, 080h, 000h, 007h, 0e0h, 0c0h, 083h, 070h, 0f0h, 0e0h, 0e0h
 DB 0c0h, 0f0h, 007h, 083h, 01ch, 0e1h, 00eh, 00eh, 0e0h, 0e0h, 0e0h, 0e0h, 0e0h, 0e0h, 0e0h, 0e0h
 DB 00eh, 00eh, 00eh, 00eh, 00eh, 00eh, 00eh, 00eh, 0c0h, 080h, 000h, 007h, 007h, 007h, 007h, 007h
 DB 001h, 003h, 007h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 0f0h, 0e0h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 0f0h, 0e0h, 000h, 000h, 000h, 0e0h, 0e0h, 0e0h, 000h, 000h
 DB 001h, 003h, 007h, 000h, 000h, 000h, 007h, 003h, 007h, 0e0h, 0c0h, 083h, 087h, 0f0h, 000h, 000h
 DB 001h, 003h, 007h, 000h, 000h, 000h, 0f0h, 003h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h
 DB 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0e0h, 0e0h, 0e0h, 000h, 000h, 000h, 000h
 DB 003h, 0e1h, 00eh, 0e1h, 001h, 003h, 007h, 000h, 000h, 01ch, 0e1h, 0e0h, 0e0h, 0e0h, 0e0h, 000h
 DB 0f0h, 0c0h, 0e0h, 0f0h, 087h, 0c3h, 0e1h, 000h, 000h, 0e0h, 0e0h, 0e0h, 000h, 000h, 000h, 000h
 DB 007h, 000h, 000h, 000h, 001h, 003h, 007h, 000h, 038h, 038h, 087h, 070h, 008h, 018h, 010h, 000h
 DB 038h, 038h, 0c3h, 01ch, 001h, 001h, 001h, 000h, 080h, 08ch, 08eh, 070h, 070h, 070h, 070h, 000h
 DB 080h, 0c0h, 0e0h, 0f0h, 087h, 0c3h, 0e1h, 000h, 0e0h, 0f0h, 070h, 083h, 0c0h, 0e0h, 007h, 000h
 DB 00eh, 0e1h, 01ch, 083h, 007h, 0f0h, 0c0h, 000h, 0f0h, 0f0h, 087h, 080h, 0c0h, 0e0h, 007h, 000h
 DB 0e1h, 0e1h, 0c3h, 003h, 007h, 0f0h, 0c0h, 000h, 007h, 007h, 007h, 007h, 007h, 007h, 007h, 000h
 DB 080h, 080h, 080h, 080h, 080h, 080h, 080h, 000h, 0c0h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 0c0h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0c0h, 080h, 000h, 000h
 DB 003h, 0c1h, 0e1h, 0c1h, 003h, 003h, 007h, 000h, 000h, 0f0h, 087h, 083h, 0c0h, 0e0h, 007h, 000h
 DB 001h, 0e1h, 00eh, 0e1h, 003h, 007h, 0e0h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 001h, 000h, 000h, 000h, 000h, 000h, 000h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h
 DB 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h
 DB 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h
 DB 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h
 DB 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h
 DB 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h
 DB 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h
 DB 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 088h, 022h, 088h, 081h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 088h, 022h, 088h, 081h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 088h, 022h, 088h, 081h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 088h, 022h, 088h, 081h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 088h, 022h, 088h, 081h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 088h, 022h, 088h, 081h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 088h, 022h, 088h, 081h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 088h, 022h, 088h, 081h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 088h, 022h, 088h, 081h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 088h, 022h, 088h, 081h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h
 DB 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 088h, 022h, 088h, 081h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 088h, 022h, 088h, 081h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 088h, 022h, 088h, 081h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 088h, 022h, 088h, 081h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 088h, 022h, 088h, 081h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 088h, 022h, 088h, 081h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 088h, 022h, 088h, 081h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 088h, 022h, 088h, 081h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 088h, 022h, 088h, 081h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 088h, 022h, 088h, 081h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h
 DB 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h
 DB 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h
 DB 080h, 0c0h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 003h, 001h, 001h, 001h, 001h, 001h, 003h, 000h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h
 DB 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h
 DB 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h, 049h
 DB 000h, 000h, 000h, 000h, 000h, 001h, 024h, 024h, 000h, 000h, 000h, 000h, 000h, 011h, 044h, 02ch
 DB 000h, 000h, 000h, 000h, 000h, 008h, 062h, 019h, 000h, 000h, 000h, 000h, 000h, 080h, 025h, 091h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 048h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 040h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h
 DB 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 005h
 DB 000h, 000h, 000h, 000h, 004h, 011h, 0b8h, 0e0h, 000h, 000h, 004h, 093h, 068h, 0c0h, 007h, 0e1h
 DB 005h, 091h, 0a6h, 0c0h, 001h, 025h, 0b8h, 0c8h, 024h, 0c8h, 001h, 001h, 093h, 040h, 007h, 001h
 DB 064h, 000h, 088h, 020h, 001h, 0e0h, 001h, 024h, 041h, 000h, 088h, 088h, 000h, 049h, 000h, 010h
 DB 010h, 000h, 089h, 020h, 064h, 001h, 008h, 080h, 092h, 001h, 008h, 040h, 011h, 000h, 048h, 021h
 DB 023h, 013h, 000h, 0f0h, 008h, 041h, 000h, 008h, 010h, 044h, 031h, 012h, 0e0h, 020h, 021h, 008h
 DB 000h, 080h, 020h, 009h, 0e4h, 005h, 001h, 003h, 000h, 000h, 000h, 000h, 020h, 088h, 0a2h, 013h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h
 DB 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 002h
 DB 000h, 000h, 001h, 009h, 023h, 070h, 060h, 080h, 011h, 0b8h, 0e0h, 080h, 001h, 006h, 018h, 007h
 DB 080h, 002h, 0f0h, 038h, 0a0h, 001h, 000h, 000h, 0cch, 010h, 080h, 087h, 001h, 024h, 001h, 012h
 DB 001h, 000h, 048h, 006h, 024h, 0b2h, 029h, 0c9h, 008h, 020h, 084h, 011h, 0f0h, 0a4h, 003h, 049h
 DB 0e1h, 089h, 020h, 018h, 080h, 0d0h, 060h, 02ah, 044h, 000h, 022h, 0e8h, 004h, 088h, 0e2h, 088h
 DB 024h, 007h, 00eh, 0e4h, 040h, 080h, 0d2h, 013h, 0c1h, 028h, 022h, 089h, 00dh, 02ch, 058h, 081h
 DB 0e0h, 0f0h, 040h, 013h, 0e1h, 09ch, 044h, 011h, 0c0h, 020h, 080h, 0d2h, 001h, 024h, 089h, 020h
 DB 084h, 011h, 044h, 088h, 098h, 022h, 088h, 024h, 080h, 0a0h, 008h, 041h, 054h, 010h, 082h, 028h
 DB 020h, 0a9h, 0e8h, 001h, 0e0h, 0a0h, 028h, 082h, 000h, 000h, 040h, 040h, 010h, 0c4h, 006h, 001h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 040h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h
 DB 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h
 DB 000h, 000h, 001h, 000h, 00bh, 009h, 0d8h, 0d0h, 012h, 0b8h, 0e0h, 080h, 080h, 008h, 004h, 011h
 DB 001h, 007h, 024h, 000h, 000h, 008h, 002h, 010h, 0c1h, 000h, 008h, 022h, 080h, 014h, 041h, 088h
 DB 000h, 010h, 044h, 010h, 081h, 024h, 001h, 008h, 040h, 008h, 001h, 024h, 000h, 048h, 012h, 090h
 DB 088h, 003h, 020h, 088h, 080h, 025h, 090h, 089h, 098h, 030h, 004h, 091h, 024h, 004h, 050h, 041h
 DB 00eh, 045h, 010h, 010h, 0c0h, 012h, 090h, 025h, 001h, 000h, 001h, 083h, 002h, 048h, 007h, 024h
 DB 064h, 042h, 091h, 094h, 0c2h, 091h, 092h, 092h, 00eh, 04ch, 006h, 007h, 0c8h, 032h, 088h, 08ch
 DB 045h, 050h, 092h, 0a0h, 008h, 094h, 0c3h, 0e8h, 026h, 088h, 018h, 096h, 0d1h, 0d2h, 0a4h, 093h
 DB 091h, 044h, 012h, 058h, 0b8h, 034h, 0d2h, 0a4h, 020h, 0a8h, 0cch, 001h, 031h, 084h, 09ah, 049h
 DB 010h, 041h, 008h, 022h, 008h, 048h, 092h, 024h, 0e0h, 020h, 008h, 040h, 011h, 084h, 020h, 088h
 DB 010h, 0c4h, 00eh, 003h, 020h, 0e0h, 088h, 020h, 000h, 000h, 000h, 040h, 000h, 020h, 0c8h, 0e4h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h
 DB 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 001h, 001h, 000h, 002h, 009h, 007h, 0e8h, 0b0h, 0c0h, 080h
 DB 0a0h, 080h, 005h, 010h, 040h, 001h, 000h, 008h, 080h, 008h, 001h, 020h, 008h, 004h, 00eh, 0a5h
 DB 044h, 001h, 028h, 001h, 084h, 012h, 044h, 015h, 001h, 001h, 048h, 003h, 024h, 095h, 094h, 096h
 DB 022h, 009h, 045h, 054h, 0aah, 095h, 024h, 002h, 0b2h, 030h, 086h, 058h, 099h, 0b0h, 0e0h, 006h
 DB 068h, 007h, 00bh, 022h, 018h, 091h, 032h, 030h, 0e4h, 080h, 0c8h, 023h, 0f0h, 007h, 060h, 00eh
 DB 00ch, 08eh, 094h, 08ch, 04ah, 094h, 08ch, 0a8h, 093h, 040h, 018h, 0c5h, 041h, 020h, 01ah, 042h
 DB 024h, 02ah, 04ah, 090h, 0c8h, 064h, 0a4h, 092h, 060h, 09ch, 0e4h, 034h, 08ch, 08bh, 04ah, 04ah
 DB 020h, 0aah, 012h, 0cch, 0cch, 0a4h, 04ch, 04ch, 0a6h, 0b2h, 064h, 0cch, 0cch, 093h, 032h, 08ch
 DB 04ch, 0cch, 0cch, 0cch, 013h, 028h, 02ch, 0d4h, 025h, 030h, 0c5h, 014h, 018h, 0b1h, 0e1h, 0d2h
 DB 061h, 08ch, 04ch, 04ch, 060h, 032h, 0cah, 064h, 021h, 060h, 04ch, 049h, 0b2h, 0a4h, 04ch, 051h
 DB 004h, 010h, 042h, 008h, 020h, 085h, 090h, 022h, 00ah, 003h, 0f0h, 090h, 003h, 024h, 001h, 048h
 DB 000h, 040h, 000h, 060h, 0c8h, 0e8h, 005h, 001h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 080h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h
 DB 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h, 000h, 002h
 DB 008h, 00bh, 023h, 0f0h, 0b0h, 0c0h, 081h, 004h, 001h, 000h, 008h, 022h, 008h, 040h, 011h, 040h
 DB 022h, 008h, 0c0h, 00ah, 003h, 024h, 000h, 092h, 0a1h, 024h, 0b8h, 092h, 003h, 048h, 048h, 003h
 DB 001h, 0f0h, 0c4h, 01ah, 040h, 064h, 09ah, 084h, 068h, 024h, 0d0h, 0e8h, 0a0h, 0cah, 0b1h, 0e4h
 DB 052h, 0c9h, 00bh, 0a1h, 030h, 030h, 064h, 064h, 0e0h, 0e1h, 082h, 004h, 024h, 022h, 031h, 0c4h
 DB 024h, 068h, 034h, 0c0h, 08bh, 085h, 024h, 0b4h, 0cch, 026h, 0b8h, 020h, 038h, 0d0h, 0c0h, 0a2h
 DB 068h, 012h, 081h, 052h, 024h, 04ch, 092h, 010h, 099h, 052h, 024h, 052h, 0c8h, 0cch, 030h, 0c5h
 DB 0a6h, 096h, 04ch, 0ach, 0ach, 0ach, 0aah, 04ah, 04ch, 0ach, 08ah, 095h, 09ah, 095h, 099h, 094h
 DB 0a6h, 093h, 0b4h, 064h, 0b4h, 099h, 0b4h, 0d8h, 09ah, 0cch, 098h, 04ch, 089h, 098h, 018h, 024h
 DB 030h, 0b4h, 0cch, 04ch, 04ch, 028h, 034h, 034h, 025h, 0d4h, 013h, 096h, 08ch, 032h, 04ah, 04ah
 DB 01ah, 0cah, 02ah, 02ah, 0cah, 032h, 08dh, 09ah, 0aah, 054h, 0b4h, 048h, 062h, 008h, 031h, 0c5h
 DB 048h, 049h, 024h, 090h, 092h, 049h, 024h, 024h, 040h, 024h, 001h, 0c8h, 0cah, 024h, 088h, 022h
 DB 001h, 048h, 001h, 0f0h, 024h, 0a0h, 091h, 00bh, 000h, 040h, 090h, 0e0h, 0e8h, 005h, 001h, 003h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h
 DB 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
 DB 000h, 000h, 000h, 000h, 000h, 001h, 000h, 002h, 009h, 007h, 016h, 0b0h, 0d0h, 0c4h, 041h, 088h
 DB 010h, 001h, 024h, 000h, 090h, 004h, 020h, 082h, 00ah, 020h, 001h, 0a0h, 00ch, 0cch, 0cch, 04ah
 DB 024h, 088h, 031h, 044h, 048h, 092h, 096h, 099h, 0b4h, 025h, 08bh, 02ah, 024h, 08ah, 094h, 034h
 DB 04ch, 089h, 091h, 034h, 0c9h, 0c9h, 0cch, 086h, 049h, 0cch, 08bh, 0a6h, 0c2h, 0a4h, 019h, 096h
 DB 0a5h, 0c6h, 0d8h, 00dh, 0b1h, 018h, 070h, 043h, 013h, 0b2h, 019h, 024h, 0c1h, 024h, 026h, 088h
 DB 0d8h, 032h, 048h, 0c4h, 031h, 030h, 007h, 050h, 02ah, 04ah, 0a4h, 09ah, 012h, 026h, 064h, 025h
 DB 092h, 022h, 092h, 04ch, 09ah, 092h, 098h, 099h, 0cah, 0cch, 0b2h, 092h, 04ch, 0c8h, 08ch, 0c9h
 DB 052h, 0cah, 0a4h, 029h, 04ah, 018h, 042h, 00ch, 01ah, 042h, 0a5h, 0cch, 0a4h, 092h, 048h, 091h
 DB 058h, 024h, 058h, 090h, 058h, 002h, 0ach, 024h, 0a0h, 002h, 0d0h, 090h, 022h, 09ah, 098h, 099h
 DB 095h, 02ah, 0aah, 0aah, 094h, 04ah, 084h, 0cah, 096h, 0c9h, 048h, 092h, 095h, 0c8h, 030h, 0f0h
 DB 094h, 093h, 096h, 092h, 087h, 0d0h, 0d8h, 025h, 014h, 0e2h, 0a8h, 0a4h, 04ah, 050h, 04ah, 054h
 DB 089h, 020h, 0a6h, 0e8h, 0b8h, 0f0h, 0f0h, 007h, 088h, 022h, 001h, 080h, 0e0h, 0e0h, 0c0h, 0c0h
 DB 0c8h, 012h, 024h, 09ah, 098h, 087h, 09ah, 08ch, 0f0h, 048h, 0c0h, 020h, 0e0h, 092h, 080h, 024h
 DB 020h, 080h, 0d0h, 0e4h, 0e8h, 00dh, 003h, 090h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 080h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h
 DB 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 000h, 000h, 000h, 000h, 000h, 006h, 000h, 000h
 DB 001h, 005h, 013h, 006h, 0d0h, 0d1h, 064h, 0c1h, 022h, 008h, 042h, 010h, 044h, 011h, 045h, 013h
 DB 009h, 04ah, 012h, 0c9h, 032h, 04ah, 0c8h, 092h, 0b4h, 099h, 025h, 0d8h, 0b2h, 0a4h, 068h, 0b4h
 DB 029h, 032h, 0d4h, 068h, 061h, 0cch, 0e4h, 0c4h, 061h, 08ch, 021h, 088h, 023h, 0b4h, 013h, 045h
 DB 0c4h, 0d1h, 043h, 08eh, 01ah, 0c3h, 0e1h, 007h, 038h, 09ch, 0c4h, 0a8h, 0c4h, 098h, 0ach, 010h
 DB 070h, 0c5h, 011h, 044h, 049h, 019h, 032h, 0b4h, 020h, 025h, 008h, 09ch, 0d8h, 094h, 02ah, 0b2h
 DB 006h, 0b2h, 007h, 04ch, 0e0h, 0d2h, 052h, 0c8h, 064h, 064h, 093h, 012h, 04ch, 0d8h, 050h, 051h
 DB 030h, 09ah, 0b2h, 032h, 0b0h, 064h, 009h, 021h, 04ch, 052h, 0b2h, 00dh, 058h, 007h, 050h, 013h
 DB 0c8h, 084h, 0c4h, 0d2h, 060h, 0b0h, 0d8h, 093h, 024h, 095h, 04ah, 013h, 093h, 0e4h, 068h, 040h
 DB 025h, 093h, 02ah, 064h, 04ah, 025h, 049h, 0cah, 068h, 093h, 094h, 048h, 064h, 0e4h, 04ah, 09ch
 DB 068h, 0d8h, 087h, 093h, 026h, 026h, 086h, 0a8h, 0b2h, 083h, 028h, 022h, 049h, 049h, 024h, 091h
 DB 038h, 014h, 051h, 044h, 015h, 051h, 044h, 019h, 0b4h, 0d0h, 0d1h, 0f0h, 0d4h, 049h, 044h, 0e8h
 DB 007h, 096h, 0d4h, 0cch, 094h, 09ah, 020h, 09ah, 0e0h, 0f0h, 090h, 093h, 0c5h, 012h, 0f0h, 0b0h
 DB 0d1h, 007h, 042h, 0ach, 0c6h, 0e1h, 0b0h, 006h, 001h, 0d1h, 004h, 030h, 085h, 090h, 092h, 044h
 DB 001h, 020h, 088h, 045h, 024h, 060h, 090h, 0e0h, 000h, 040h, 090h, 0c0h, 0e8h, 0e8h, 00dh, 007h
 DB 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h, 001h, 001h, 001h, 001h, 001h, 001h, 001h
 DB 001h, 001h, 001h, 001h, 001h, 083h, 083h, 038h, 001h, 001h, 004h, 003h, 00bh, 023h, 00eh, 0e4h
 DB 089h, 088h, 022h, 008h, 092h, 012h, 0b8h, 018h, 00ch, 0d8h, 0b4h, 096h, 024h, 094h, 0ach, 048h
 DB 032h, 0b2h, 044h, 0cch, 088h, 0aah, 022h, 0a4h, 064h, 089h, 0cch, 0b1h, 0c0h, 008h, 029h, 04ch
 DB 0e4h, 095h, 0e1h, 015h, 01ch, 08ch, 08bh, 034h, 0a3h, 0cah, 08bh, 026h, 0c4h, 0c9h, 01ah, 049h
 DB 093h, 008h, 02ch, 019h, 052h, 08dh, 0cch, 04ah, 084h, 0a2h, 00ah, 048h, 004h, 0cah, 005h, 0cch
 DB 026h, 0c8h, 062h, 068h, 032h, 0d2h, 0d2h, 092h, 0b8h, 032h, 028h, 0cch, 099h, 092h, 093h, 0a4h
 DB 0f0h, 095h, 089h, 007h, 046h, 0d1h, 0c0h, 040h, 094h, 020h, 049h, 040h, 012h, 000h, 025h, 0a0h
 DB 084h, 091h, 004h, 020h, 088h, 022h, 008h, 040h, 048h, 020h, 025h, 080h, 0b2h, 0e1h, 060h, 0c9h
 DB 052h, 094h, 0c4h, 006h, 042h, 010h, 045h, 010h, 048h, 022h, 0c0h, 00eh, 043h, 0a4h, 050h, 010h
 DB 0c8h, 095h, 0e2h, 0a6h, 0e4h, 01ah, 084h, 0a5h, 09ah, 091h, 013h, 0b4h, 038h, 0c8h, 0e1h, 031h
 DB 0e8h, 0d8h, 049h, 043h, 099h, 0f0h, 0b4h, 013h, 084h, 025h, 092h, 0c2h, 098h, 0d2h, 0d0h, 0b4h
 DB 096h, 02ch, 068h, 032h, 093h, 024h, 024h, 089h, 0f0h, 007h, 068h, 064h, 0cah, 094h, 0c2h, 029h
 DB 008h, 014h, 0c9h, 024h, 0cah, 0c9h, 049h, 0d8h, 0c5h, 0a5h, 01ah, 058h, 0e4h, 049h, 024h, 001h
 DB 0e0h, 060h, 090h, 007h, 04ch, 081h, 0ach, 0c1h, 051h, 048h, 022h, 088h, 022h, 049h, 000h, 089h
 DB 04ah, 0f0h, 0a4h, 091h, 044h, 011h, 044h, 011h, 0a0h, 003h, 0f0h, 048h, 087h, 084h, 0c0h, 028h
 DB 000h, 080h, 020h, 000h, 040h, 090h, 0e0h, 0e8h, 001h, 001h, 001h, 001h, 001h, 083h, 083h, 038h

sinTbl:
 DB 078h, 07bh, 07fh, 083h, 087h, 08ah, 08eh, 092h, 095h, 099h, 09ch, 0a0h, 0a3h, 0a6h, 0a9h, 0ach
 DB 0afh, 0b1h, 0b4h, 0b6h, 0b9h, 0bbh, 0bdh, 0bfh, 0c0h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h, 0c7h
 DB 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c6h, 0c5h, 0c4h, 0c3h, 0c2h, 0c0h, 0bfh, 0bdh, 0bbh, 0b9h, 0b6h
 DB 0b4h, 0b1h, 0afh, 0ach, 0a9h, 0a6h, 0a3h, 09fh, 09ch, 099h, 095h, 092h, 08eh, 08ah, 087h, 083h
 DB 07fh, 07bh, 077h, 074h, 070h, 06ch, 068h, 065h, 061h, 05dh, 05ah, 056h, 053h, 04fh, 04ch, 049h
 DB 046h, 043h, 040h, 03eh, 03bh, 039h, 036h, 034h, 032h, 030h, 02fh, 02dh, 02ch, 02bh, 02ah, 029h
 DB 028h, 028h, 028h, 028h, 028h, 028h, 028h, 029h, 02ah, 02bh, 02ch, 02dh, 02fh, 030h, 032h, 034h
 DB 036h, 039h, 03bh, 03eh, 040h, 043h, 046h, 049h, 04ch, 050h, 053h, 056h, 05ah, 05eh, 061h, 065h
 DB 069h, 06ch, 070h, 074h, 078h, 07ch, 07fh, 083h, 087h, 08bh, 08eh, 092h, 095h, 099h, 09ch, 0a0h
 DB 0a3h, 0a6h, 0a9h, 0ach, 0afh, 0b2h, 0b4h, 0b7h, 0b9h, 0bbh, 0bdh, 0bfh, 0c0h, 0c2h, 0c3h, 0c4h
 DB 0c5h, 0c6h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c6h, 0c5h, 0c4h, 0c3h, 0c2h, 0c0h, 0beh
 DB 0bdh, 0bbh, 0b9h, 0b6h, 0b4h, 0b1h, 0afh, 0ach, 0a9h, 0a6h, 0a3h, 09fh, 09ch, 098h, 095h, 091h
 DB 08eh, 08ah, 086h, 083h, 07fh, 07bh, 077h, 073h, 070h, 06ch, 068h, 064h, 061h, 05dh, 059h, 056h
 DB 053h, 04fh, 04ch, 049h, 046h, 043h, 040h, 03dh, 03bh, 038h, 036h, 034h, 032h, 030h, 02fh, 02dh
 DB 02ch, 02bh, 02ah, 029h, 028h, 028h, 028h, 028h, 028h, 028h, 028h, 029h, 02ah, 02bh, 02ch, 02dh
 DB 02fh, 031h, 032h, 034h, 037h, 039h, 03bh, 03eh, 041h, 043h, 046h, 049h, 04dh, 050h, 053h, 057h
 DB 05ah, 05eh, 061h, 065h, 069h, 06dh, 070h, 074h, 078h, 07ch, 080h, 083h, 087h, 08bh, 08eh, 092h
 DB 096h, 099h, 09dh, 0a0h, 0a3h, 0a6h, 0a9h, 0ach, 0afh, 0b2h, 0b4h, 0b7h, 0b9h, 0bbh, 0bdh, 0bfh
 DB 0c0h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c6h, 0c5h, 0c4h
 DB 0c3h, 0c2h, 0c0h, 0beh, 0bdh, 0bbh, 0b8h, 0b6h, 0b4h, 0b1h, 0aeh, 0ach, 0a9h, 0a6h, 0a2h, 09fh
 DB 09ch, 098h, 095h, 091h, 08eh, 08ah, 086h, 082h, 07fh, 07bh, 077h, 073h, 06fh, 06ch, 068h, 064h
 DB 060h, 05dh, 059h, 056h, 052h, 04fh, 04ch, 049h, 046h, 043h, 040h, 03dh, 03bh, 038h, 036h, 034h
 DB 032h, 030h, 02fh, 02dh, 02ch, 02bh, 02ah, 029h, 028h, 028h, 028h, 028h, 028h, 028h, 028h, 029h
 DB 02ah, 02bh, 02ch, 02dh, 02fh, 031h, 033h, 035h, 037h, 039h, 03bh, 03eh, 041h, 044h, 047h, 04ah
 DB 04dh, 050h, 053h, 057h, 05ah, 05eh, 062h, 065h, 069h, 06dh, 070h, 074h, 078h, 07ch, 080h, 083h
 DB 087h, 08bh, 08fh, 092h, 096h, 099h, 09dh, 0a0h, 0a3h, 0a6h, 0a9h, 0ach, 0afh, 0b2h, 0b4h, 0b7h
 DB 0b9h, 0bbh, 0bdh, 0bfh, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h
 DB 0c7h, 0c6h, 0c5h, 0c4h, 0c3h, 0c2h, 0c0h, 0beh, 0bch, 0bah, 0b8h, 0b6h, 0b4h, 0b1h, 0aeh, 0abh
 DB 0a8h, 0a5h, 0a2h, 09fh, 09ch, 098h, 095h, 091h, 08dh, 08ah, 086h, 082h, 07eh, 07bh, 077h, 073h
 DB 06fh, 06bh, 068h, 064h, 060h, 05dh, 059h, 056h, 052h, 04fh, 04ch, 049h, 045h, 043h, 040h, 03dh
 DB 03bh, 038h, 036h, 034h, 032h, 030h, 02eh, 02dh, 02ch, 02bh, 02ah, 029h, 028h, 028h, 028h, 028h
 DB 028h, 028h, 028h, 029h, 02ah, 02bh, 02ch, 02eh, 02fh, 031h, 033h, 035h, 037h, 039h, 03ch, 03eh
 DB 041h, 044h, 047h, 04ah, 04dh, 050h, 054h, 057h, 05bh, 05eh, 062h, 065h, 069h, 06dh, 071h, 075h
 DB 078h, 07ch, 080h, 084h, 087h, 08bh, 08fh, 092h, 096h, 099h, 09dh, 0a0h, 0a3h, 0a7h, 0aah, 0adh
 DB 0afh, 0b2h, 0b5h, 0b7h, 0b9h, 0bbh, 0bdh, 0bfh, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h, 0c7h
 DB 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c6h, 0c5h, 0c4h, 0c3h, 0c1h, 0c0h, 0beh, 0bch, 0bah, 0b8h, 0b6h
 DB 0b3h, 0b1h, 0aeh, 0abh, 0a8h, 0a5h, 0a2h, 09fh, 09bh, 098h, 094h, 091h, 08dh, 089h, 086h, 082h
 DB 07eh, 07ah, 077h, 073h, 06fh, 06bh, 067h, 064h, 060h, 05ch, 059h, 055h, 052h, 04fh, 04bh, 048h
 DB 045h, 042h, 040h, 03dh, 03ah, 038h, 036h, 034h, 032h, 030h, 02eh, 02dh, 02ch, 02ah, 02ah, 029h
 DB 028h, 028h, 028h, 028h, 028h, 028h, 028h, 029h, 02ah, 02bh, 02ch, 02eh, 02fh, 031h, 033h, 035h
 DB 037h, 039h, 03ch, 03eh, 041h, 044h, 047h, 04ah, 04dh, 050h, 054h, 057h, 05bh, 05eh, 062h, 066h
 DB 069h, 06dh, 071h, 075h, 079h, 07ch, 080h, 084h, 088h, 08bh, 08fh, 093h, 096h, 09ah, 09dh, 0a0h
 DB 0a4h, 0a7h, 0aah, 0adh, 0afh, 0b2h, 0b5h, 0b7h, 0b9h, 0bbh, 0bdh, 0bfh, 0c1h, 0c2h, 0c3h, 0c5h
 DB 0c5h, 0c6h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c6h, 0c5h, 0c4h, 0c3h, 0c1h, 0c0h, 0beh
 DB 0bch, 0bah, 0b8h, 0b6h, 0b3h, 0b1h, 0aeh, 0abh, 0a8h, 0a5h, 0a2h, 09fh, 09bh, 098h, 094h, 091h
 DB 08dh, 089h, 086h, 082h, 07eh, 07ah, 076h, 073h, 06fh, 06bh, 067h, 064h, 060h, 05ch, 059h, 055h
 DB 052h, 04fh, 04bh, 048h, 045h, 042h, 03fh, 03dh, 03ah, 038h, 036h, 034h, 032h, 030h, 02eh, 02dh
 DB 02ch, 02ah, 029h, 029h, 028h, 028h, 028h, 028h, 028h, 028h, 028h, 029h, 02ah, 02bh, 02ch, 02eh
 DB 02fh, 031h, 033h, 035h, 037h, 039h, 03ch, 03eh, 041h, 044h, 047h, 04ah, 04dh, 051h, 054h, 057h
 DB 05bh, 05eh, 062h, 066h, 06ah, 06dh, 071h, 075h, 079h, 07dh, 080h, 084h, 088h, 08ch, 08fh, 093h
 DB 096h, 09ah, 09dh, 0a1h, 0a4h, 0a7h, 0aah, 0adh, 0b0h, 0b2h, 0b5h, 0b7h, 0b9h, 0bbh, 0bdh, 0bfh
 DB 0c1h, 0c2h, 0c4h, 0c5h, 0c6h, 0c6h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c6h, 0c6h, 0c5h, 0c4h
 DB 0c3h, 0c1h, 0c0h, 0beh, 0bch, 0bah, 0b8h, 0b6h, 0b3h, 0b1h, 0aeh, 0abh, 0a8h, 0a5h, 0a2h, 09eh
 DB 09bh, 098h, 094h, 090h, 08dh, 089h, 085h, 082h, 07eh, 07ah, 076h, 072h, 06fh, 06bh, 067h, 063h
 DB 060h, 05ch, 059h, 055h, 052h, 04eh, 04bh, 048h, 045h, 042h, 03fh, 03dh, 03ah, 038h, 036h, 033h
 DB 032h, 030h, 02eh, 02dh, 02bh, 02ah, 029h, 029h, 028h, 028h, 028h, 028h, 028h, 028h, 029h, 029h
 DB 02ah, 02bh, 02ch, 02eh, 02fh, 031h, 033h, 035h, 037h, 039h, 03ch, 03fh, 041h, 044h, 047h, 04ah
 DB 04dh, 051h, 054h, 058h, 05bh, 05fh, 062h, 066h, 06ah, 06eh, 071h, 075h, 079h, 07dh, 081h, 084h
 DB 088h, 08ch, 08fh, 093h, 097h, 09ah, 09dh, 0a1h, 0a4h, 0a7h, 0aah, 0adh, 0b0h, 0b2h, 0b5h, 0b7h
 DB 0b9h, 0bch, 0bdh, 0bfh, 0c1h, 0c2h, 0c4h, 0c5h, 0c6h, 0c6h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h
 DB 0c6h, 0c6h, 0c5h, 0c4h, 0c3h, 0c1h, 0c0h, 0beh, 0bch, 0bah, 0b8h, 0b5h, 0b3h, 0b0h, 0aeh, 0abh
 DB 0a8h, 0a5h, 0a1h, 09eh, 09bh, 097h, 094h, 090h, 08dh, 089h, 085h, 081h, 07eh, 07ah, 076h, 072h
 DB 06eh, 06bh, 067h, 063h, 060h, 05ch, 058h, 055h, 051h, 04eh, 04bh, 048h, 045h, 042h, 03fh, 03dh
 DB 03ah, 038h, 035h, 033h, 031h, 030h, 02eh, 02dh, 02bh, 02ah, 029h, 029h, 028h, 028h, 028h, 028h
 DB 028h, 028h, 029h, 029h, 02ah, 02bh, 02ch, 02eh, 02fh, 031h, 033h, 035h, 037h, 03ah, 03ch, 03fh
 DB 041h, 044h, 047h, 04ah, 04eh, 051h, 054h, 058h, 05bh, 05fh, 063h, 066h, 06ah, 06eh, 072h, 075h
 DB 079h, 07dh, 081h, 084h, 088h, 08ch, 090h, 093h, 097h, 09ah, 09eh, 0a1h, 0a4h, 0a7h, 0aah, 0adh
 DB 0b0h, 0b3h, 0b5h, 0b7h, 0bah, 0bch, 0beh, 0bfh, 0c1h, 0c2h, 0c4h, 0c5h, 0c6h, 0c6h, 0c7h, 0c7h
 DB 0c7h, 0c7h, 0c7h, 0c7h, 0c6h, 0c6h, 0c5h, 0c4h, 0c3h, 0c1h, 0c0h, 0beh, 0bch, 0bah, 0b8h, 0b5h
 DB 0b3h, 0b0h, 0adh, 0abh, 0a8h, 0a5h, 0a1h, 09eh, 09bh, 097h, 094h, 090h, 08ch, 089h, 085h, 081h
 DB 07dh, 07ah, 076h, 072h, 06eh, 06ah, 067h, 063h, 05fh, 05ch, 058h, 055h, 051h, 04eh, 04bh, 048h
 DB 045h, 042h, 03fh, 03ch, 03ah, 038h, 035h, 033h, 031h, 030h, 02eh, 02dh, 02bh, 02ah, 029h, 029h
 DB 028h, 028h, 028h, 028h, 028h, 028h, 029h, 029h, 02ah, 02bh, 02dh, 02eh, 02fh, 031h, 033h, 035h
 DB 037h, 03ah, 03ch, 03fh, 042h, 044h, 047h, 04bh, 04eh, 051h, 054h, 058h, 05bh, 05fh, 063h, 066h
 DB 06ah, 06eh, 072h, 076h, 079h, 07dh, 081h, 085h, 088h, 08ch, 090h, 093h, 097h, 09ah, 09eh, 0a1h
 DB 0a4h, 0a7h, 0aah, 0adh, 0b0h, 0b3h, 0b5h, 0b8h, 0bah, 0bch, 0beh, 0bfh, 0c1h, 0c2h, 0c4h, 0c5h
 DB 0c6h, 0c6h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c6h, 0c6h, 0c5h, 0c4h, 0c2h, 0c1h, 0bfh, 0beh
 DB 0bch, 0bah, 0b8h, 0b5h, 0b3h, 0b0h, 0adh, 0aah, 0a7h, 0a4h, 0a1h, 09eh, 09ah, 097h, 093h, 090h
 DB 08ch, 088h, 085h, 081h, 07dh, 079h, 076h, 072h, 06eh, 06ah, 066h, 063h, 05fh, 05ch, 058h, 055h
 DB 051h, 04eh, 04bh, 048h, 045h, 042h, 03fh, 03ch, 03ah, 037h, 035h, 033h, 031h, 030h, 02eh, 02dh
 DB 02bh, 02ah, 029h, 029h, 028h, 028h, 028h, 028h, 028h, 028h, 029h, 029h, 02ah, 02bh, 02dh, 02eh
 DB 030h, 031h, 033h, 035h, 038h, 03ah, 03ch, 03fh, 042h, 045h, 048h, 04bh, 04eh, 051h, 055h, 058h
 DB 05ch, 05fh, 063h, 067h, 06ah, 06eh, 072h, 076h, 07ah, 07dh, 081h, 085h, 089h, 08ch, 090h, 094h
 DB 097h, 09bh, 09eh, 0a1h, 0a4h, 0a8h, 0abh, 0adh, 0b0h, 0b3h, 0b5h, 0b8h, 0bah, 0bch, 0beh, 0c0h
 DB 0c1h, 0c3h, 0c4h, 0c5h, 0c6h, 0c6h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c6h, 0c6h, 0c5h, 0c4h
 DB 0c2h, 0c1h, 0bfh, 0beh, 0bch, 0bah, 0b7h, 0b5h, 0b3h, 0b0h, 0adh, 0aah, 0a7h, 0a4h, 0a1h, 09eh
 DB 09ah, 097h, 093h, 090h, 08ch, 088h, 085h, 081h, 07dh, 079h, 075h, 072h, 06eh, 06ah, 066h, 063h
 DB 05fh, 05bh, 058h, 054h, 051h, 04eh, 04ah, 047h, 044h, 042h, 03fh, 03ch, 03ah, 037h, 035h, 033h
 DB 031h, 02fh, 02eh, 02ch, 02bh, 02ah, 029h, 029h, 028h, 028h, 028h, 028h, 028h, 028h, 029h, 029h
 DB 02ah, 02bh, 02dh, 02eh, 030h, 031h, 033h, 035h, 038h, 03ah, 03dh, 03fh, 042h, 045h, 048h, 04bh
 DB 04eh, 051h, 055h, 058h, 05ch, 05fh, 063h, 067h, 06bh, 06eh, 072h, 076h, 07ah, 07eh, 081h, 085h
 DB 089h, 08dh, 090h, 094h, 097h, 09bh, 09eh, 0a1h, 0a5h, 0a8h, 0abh, 0aeh, 0b0h, 0b3h, 0b5h, 0b8h
 DB 0bah, 0bch, 0beh, 0c0h, 0c1h, 0c3h, 0c4h, 0c5h, 0c6h, 0c6h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h
 DB 0c6h, 0c6h, 0c5h, 0c4h, 0c2h, 0c1h, 0bfh, 0beh, 0bch, 0bah, 0b7h, 0b5h, 0b2h, 0b0h, 0adh, 0aah
 DB 0a7h, 0a4h, 0a1h, 09dh, 09ah, 097h, 093h, 08fh, 08ch, 088h, 084h, 081h, 07dh, 079h, 075h, 071h
 DB 06eh, 06ah, 066h, 062h, 05fh, 05bh, 058h, 054h, 051h, 04dh, 04ah, 047h, 044h, 041h, 03fh, 03ch
 DB 03ah, 037h, 035h, 033h, 031h, 02fh, 02eh, 02ch, 02bh, 02ah, 029h, 029h, 028h, 028h, 028h, 028h
 DB 028h, 028h, 029h, 029h, 02ah, 02bh, 02dh, 02eh, 030h, 032h, 033h, 036h, 038h, 03ah, 03dh, 03fh
 DB 042h, 045h, 048h, 04bh, 04eh, 052h, 055h, 058h, 05ch, 060h, 063h, 067h, 06bh, 06fh, 072h, 076h
 DB 07ah, 07eh, 082h, 085h, 089h, 08dh, 090h, 094h, 097h, 09bh, 09eh, 0a2h, 0a5h, 0a8h, 0abh, 0aeh
 DB 0b0h, 0b3h, 0b6h, 0b8h, 0bah, 0bch, 0beh, 0c0h, 0c1h, 0c3h, 0c4h, 0c5h, 0c6h, 0c6h, 0c7h, 0c7h
 DB 0c7h, 0c7h, 0c7h, 0c7h, 0c6h, 0c6h, 0c5h, 0c4h, 0c2h, 0c1h, 0bfh, 0bdh, 0bch, 0b9h, 0b7h, 0b5h
 DB 0b2h, 0b0h, 0adh, 0aah, 0a7h, 0a4h, 0a1h, 09dh, 09ah, 096h, 093h, 08fh, 08ch, 088h, 084h, 080h
 DB 07dh, 079h, 075h, 071h, 06dh, 06ah, 066h, 062h, 05fh, 05bh, 057h, 054h, 051h, 04dh, 04ah, 047h
 DB 044h, 041h, 03eh, 03ch, 039h, 037h, 035h, 033h, 031h, 02fh, 02eh, 02ch, 02bh, 02ah, 029h, 028h
 DB 028h, 028h, 028h, 028h, 028h, 028h, 029h, 029h, 02ah, 02ch, 02dh, 02eh, 030h, 032h, 034h, 036h
 DB 038h, 03ah, 03dh, 03fh, 042h, 045h, 048h, 04bh, 04eh, 052h, 055h, 059h, 05ch, 060h, 063h, 067h
 DB 06bh, 06fh, 073h, 076h, 07ah, 07eh, 082h, 085h, 089h, 08dh, 091h, 094h, 098h, 09bh, 09eh, 0a2h
 DB 0a5h, 0a8h, 0abh, 0aeh, 0b1h, 0b3h, 0b6h, 0b8h, 0bah, 0bch, 0beh, 0c0h, 0c1h, 0c3h, 0c4h, 0c5h
 DB 0c6h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c6h, 0c6h, 0c5h, 0c3h, 0c2h, 0c1h, 0bfh, 0bdh
 DB 0bbh, 0b9h, 0b7h, 0b5h, 0b2h, 0afh, 0adh, 0aah, 0a7h, 0a4h, 0a0h, 09dh, 09ah, 096h, 093h, 08fh
 DB 08bh, 088h, 084h, 080h, 07ch, 079h, 075h, 071h, 06dh, 069h, 066h, 062h, 05eh, 05bh, 057h, 054h
 DB 050h, 04dh, 04ah, 047h, 044h, 041h, 03eh, 03ch, 039h, 037h, 035h, 033h, 031h, 02fh, 02eh, 02ch
 DB 02bh, 02ah, 029h, 028h, 028h, 028h, 028h, 028h, 028h, 028h, 029h, 02ah, 02ah, 02ch, 02dh, 02eh
 DB 030h, 032h, 034h, 036h, 038h, 03ah, 03dh, 040h, 042h, 045h, 048h, 04bh, 04fh, 052h, 055h, 059h
 DB 05ch, 060h, 064h, 067h, 06bh, 06fh, 073h, 077h, 07ah, 07eh, 082h, 086h, 089h, 08dh, 091h, 094h
 DB 098h, 09bh, 09fh, 0a2h, 0a5h, 0a8h, 0abh, 0aeh, 0b1h, 0b3h, 0b6h, 0b8h, 0bah, 0bch, 0beh, 0c0h
 DB 0c1h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c6h, 0c5h, 0c5h, 0c3h
 DB 0c2h, 0c1h, 0bfh, 0bdh, 0bbh, 0b9h, 0b7h, 0b5h, 0b2h, 0afh, 0adh, 0aah, 0a7h, 0a4h, 0a0h, 09dh
 DB 09ah, 096h, 093h, 08fh, 08bh, 088h, 084h, 080h, 07ch, 078h, 075h, 071h, 06dh, 069h, 065h, 062h
 DB 05eh, 05bh, 057h, 054h, 050h, 04dh, 04ah, 047h, 044h, 041h, 03eh, 03ch, 039h, 037h, 035h, 033h
 DB 031h, 02fh, 02eh, 02ch, 02bh, 02ah, 029h, 028h, 028h, 028h, 028h, 028h, 028h, 028h, 029h, 02ah
 DB 02bh, 02ch, 02dh, 02eh, 030h, 032h, 034h, 036h, 038h, 03bh, 03dh, 040h, 043h, 045h, 048h, 04ch
 DB 04fh, 052h, 056h, 059h, 05dh, 060h, 064h, 068h, 06bh, 06fh, 073h, 077h, 07bh, 07eh, 082h, 086h
 DB 08ah, 08dh, 091h, 095h, 098h, 09bh, 09fh, 0a2h, 0a5h, 0a8h, 0abh, 0aeh, 0b1h, 0b3h, 0b6h, 0b8h
 DB 0bah, 0bch, 0beh, 0c0h, 0c1h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h
 DB 0c6h, 0c5h, 0c4h, 0c3h, 0c2h, 0c1h, 0bfh, 0bdh, 0bbh, 0b9h, 0b7h, 0b4h, 0b2h, 0afh, 0ach, 0a9h
 DB 0a6h, 0a3h, 0a0h, 09dh, 099h, 096h, 092h, 08fh, 08bh, 087h, 084h, 080h, 07ch, 078h, 074h, 071h
 DB 06dh, 069h, 065h, 062h, 05eh, 05ah, 057h, 053h, 050h, 04dh, 04ah, 047h, 044h, 041h, 03eh, 03bh
 DB 039h, 037h, 035h, 033h, 031h, 02fh, 02dh, 02ch, 02bh, 02ah, 029h, 028h, 028h, 028h, 028h, 028h
 DB 028h, 028h, 029h, 02ah, 02bh, 02ch, 02dh, 02eh, 030h, 032h, 034h, 036h, 038h, 03bh, 03dh, 040h
 DB 043h, 046h, 049h, 04ch, 04fh, 052h, 056h, 059h, 05dh, 060h, 064h, 068h, 06ch, 06fh, 073h, 077h
 DB 07bh, 07fh, 082h, 086h, 08ah, 08dh, 091h, 095h, 098h, 09ch, 09fh, 0a2h, 0a5h, 0a9h, 0abh, 0aeh
 DB 0b1h, 0b4h, 0b6h, 0b8h, 0bbh, 0bdh, 0beh, 0c0h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h, 0c7h, 0c7h
 DB 0c7h, 0c7h, 0c7h, 0c7h, 0c6h, 0c5h, 0c4h, 0c3h, 0c2h, 0c0h, 0bfh, 0bdh, 0bbh, 0b9h, 0b7h, 0b4h
 DB 0b2h, 0afh, 0ach, 0a9h, 0a6h, 0a3h, 0a0h, 09dh, 099h, 096h, 092h, 08eh, 08bh, 087h, 083h, 080h
 DB 07ch, 078h, 074h, 070h, 06dh, 069h, 065h, 061h, 05eh, 05ah, 057h, 053h, 050h, 04dh, 049h, 046h
 DB 043h, 041h, 03eh, 03bh, 039h, 037h, 034h, 032h, 031h, 02fh, 02dh, 02ch, 02bh, 02ah, 029h, 028h
 DB 028h, 028h, 028h, 028h, 028h, 028h, 029h, 02ah, 02bh, 02ch, 02dh, 02fh, 030h, 032h, 034h, 036h
 DB 038h, 03bh, 03dh, 040h, 043h, 046h, 049h, 04ch, 04fh, 052h, 056h, 059h, 05dh, 061h, 064h, 068h
 DB 06ch, 070h, 073h, 077h, 07bh, 07fh, 083h, 086h, 08ah, 08eh, 091h, 095h, 098h, 09ch, 09fh, 0a2h
 DB 0a6h, 0a9h, 0ach, 0aeh, 0b1h, 0b4h, 0b6h, 0b8h, 0bbh, 0bdh, 0beh, 0c0h, 0c2h, 0c3h, 0c4h, 0c5h
 DB 0c6h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c6h, 0c5h, 0c4h, 0c3h, 0c2h, 0c0h, 0bfh, 0bdh
 DB 0bbh, 0b9h, 0b7h, 0b4h, 0b2h, 0afh, 0ach, 0a9h, 0a6h, 0a3h, 0a0h, 09ch, 099h, 095h, 092h, 08eh
 DB 08bh, 087h, 083h, 07fh, 07ch, 078h, 074h, 070h, 06ch, 069h, 065h, 061h, 05eh, 05ah, 056h, 053h
 DB 050h, 04ch, 049h, 046h, 043h, 040h, 03eh, 03bh, 039h, 036h, 034h, 032h, 031h, 02fh, 02dh, 02ch
 DB 02bh, 02ah, 029h, 028h, 028h, 028h, 028h, 028h, 028h, 028h, 029h, 02ah, 02bh, 02ch, 02dh, 02fh
 DB 030h, 032h, 034h, 036h, 038h, 03bh, 03dh, 040h, 043h, 046h, 049h, 04ch, 04fh, 053h, 056h, 05ah
 DB 05dh, 061h, 064h, 068h, 06ch, 070h, 074h, 077h, 07bh, 07fh, 083h, 086h, 08ah, 08eh, 092h, 095h
 DB 099h, 09ch, 09fh, 0a3h, 0a6h, 0a9h, 0ach, 0afh, 0b1h, 0b4h, 0b6h, 0b9h, 0bbh, 0bdh, 0bfh, 0c0h
 DB 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c7h, 0c6h, 0c5h, 0c4h, 0c3h
 DB 0c2h, 0c0h, 0bfh, 0bdh, 0bbh, 0b9h, 0b6h, 0b4h, 0b1h, 0afh, 0ach, 0a9h, 0a6h, 0a3h, 0a0h, 09ch
 DB 099h, 095h, 092h, 08eh, 08ah, 087h, 083h, 07fh, 07bh, 078h, 074h, 070h, 06ch, 068h, 065h, 061h
 DB 05dh, 05ah, 056h, 053h, 050h, 04ch, 049h, 046h, 043h, 040h, 03eh, 03bh, 039h, 036h, 034h, 032h
 DB 030h, 02fh, 02dh, 02ch, 02bh, 02ah, 029h, 028h, 028h, 028h, 028h, 028h, 028h, 028h, 029h, 02ah
 DB 02bh, 02ch, 02dh, 02fh, 030h, 032h, 034h, 036h, 039h, 03bh, 03eh, 040h, 043h, 046h, 049h, 04ch
 DB 050h, 053h, 056h, 05ah, 05dh, 061h, 065h, 068h, 06ch, 070h, 074h
sinEnd:
    end
