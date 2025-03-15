; Tms9918 test program

	LXI	SP,100h

	CALL	setVdpPort
	CALL	T_ReadStatus

	;LXI	H,tmsFont
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

	JMP	$

str:	Db	"hello, world",0
str1:	Db	"         1",0
str2:	Db	"1234567890",0

T_InitialiseText80:
	CALL	T_Reset

	LXI	B, T_T80_VRAM_PATT_ADDRESS; + 32 * 8 ; load font from address in bc
	CALL	T_SetAddrWrite

	LXI	H, tmsFont
	LXI	D, tmsFontEnd - tmsFont ; tmsFontBytes
	CALL	T_WriteBytes
	; fallthrough to TmsInitNonBitmap

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
	MVI	C, (T_T80_VRAM_NAME_ADDRESS / 400h) AND 7Ch OR 3 
	CALL	T_WriteRegValue

	MVI	B, T_REG_0
	MVI	C, T_R0_EXT_VDP_DISABLE OR T_R0_MODE_TEXT80
	CALL	T_WriteRegValue

	MVI	B, T_REG_1
	MVI	C, T_R1_MODE_TEXT OR T_R1_DISP_ACTIVE OR T_R1_INT_ENABLE
	CALL	T_WriteRegValue

	RET

include 9918.asm
tmsFont:
include tmsfont.asm
tmsFontEnd:
	end
