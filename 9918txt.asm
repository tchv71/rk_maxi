; Tms9918 test program
@SYSREG	MACRO	VAL
	IN	-1
	MVI	A,VAL
	OUT	-1
	ENDM

	LXI	SP,100h

	CALL	setVdpPort
L01:
	CALL	T_ReadStatus
	;OUT	VDP
	;JMP	L01

	;LXI	H,tmsFont
	CALL	T_Reset
	CALL	T_InitialiseText80

	MVI	B, T_REG_FG_BG_COLOR
	MVI	C, T_DK_BLUE OR (T_WHITE SHL 4)
	CALL	T_WriteRegValue

	LXI	H,0
	CALL	T_TextPos

	;LXI	H,str
	;CALL	T_StrOut

	MVI	B,8
@l01:	LXI	H,str1
	CALL	T_StrOut
	DCX	H
	INR	M
	DCR	B
	JNZ	@l01

	MVI	B,8
@l02:	LXI	H,str2
	CALL	T_StrOut
	DCR	B
	JNZ	@l02

	;CALL	DELLIN
	LXI	B,50
	CALL	T_SetAddrRead
	IN	VDP
	PUSH	PSW
	LXI	B,0
	CALL	T_SetAddrWrite
	POP	PSW
	;MVI	A,'2'
	OUT	VDP
	JMP	$

setVdpPort:
	DI
	@SYSREG	0C0h ; Turn on external device programming mode (for in/out commands)
	MVI	A,14
	OUT	VDP
	OUT	VDP+1
	@SYSREG	80h
	RET

ENDSCR	EQU	80*24
PHYS_W	EQU	80

DELLIN:	PUSH	H
	LXI	H,0;LHLD	STRADR
DL01:
	MOV	D,H
	MOV	E,L
	CALL	NXT_S
	PUSH	H
	PUSH	D

	PUSH	D
	XCHG
	LXI	H,STRBUF
	MVI	B,PHYS_W
	PUSH	H
	CALL	T_ShAddrReadBytes
	POP	H
	POP	D
	MVI	B, PHYS_W
	CALL	T_ShAddrWriteBytes
	POP	D
	POP	H
	MOV	A,H
	CPI	high(ENDSCR)
	JNZ	DL01
	MOV	A,L
	CPI	low(ENDSCR)
	JNZ	DL01
	XRA	A
	LXI	B,PHYS_W
	CALL	T_Fill

	POP	H
	RET

NXT_S:	PUSH	B
	LXI	B,PHYS_W
	DAD	B
	POP	B
	RET

STRBUF:	DS	80

str:	Db	"hello, world",0
str1:	Db	"         1",0
str2:	Db	"1234567890",0

include 9918.asm
tmsFont:
include tmsfont.asm
tmsFontEnd:
	end
