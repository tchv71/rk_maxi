; Tms9918 test program

	LXI	SP,100h

	CALL	setVdpPort
	CALL	T_ReadStatus

	LXI	H,tmsFont
	CALL	T_InitialiseText80

	MVI	B, T_REG_FG_BG_COLOR
	MVI	C, T_DK_BLUE OR (T_WHITE SHL 4)
	CALL	T_WriteRegValue

	LXI	H,0
	CALL	T_TextPos

	LXI	H,str
	CALL	T_StrOut
	JMP	$

str:	Db	"hello, world",0

T_InitialiseText80:
	CALL	T_Reset

	LXI	B, T_T80_VRAM_PATT_ADDRESS + 32 * 8 ; load font from address in hl
	CALL	T_SetAddrWrite

	;LXI	H, tmsFont
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
	MVI	C, T_T80_VRAM_NAME_ADDRESS / 400h
	CALL	T_WriteRegValue

	MVI	B, T_REG_1
	MVI	C, T_R1_RAM_16K or T_R1_MODE_TEXT OR T_R1_DISP_ACTIVE OR T_R1_INT_ENABLE
	CALL	T_WriteRegValue

	MVI	B, T_REG_0
	MVI	C, T_R0_EXT_VDP_DISABLE OR T_R0_MODE_GR_II
	JMP	T_WriteRegValue

include 9918.asm
include 9918font.asm
	end
