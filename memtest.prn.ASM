	include	9918def.asm 
T_0_MODE_GRAPHICS_I	EQU	0 
T_1_MODE_GRAPHICS_II	EQU	1 
T_2_MODE_TEXT		EQU	2 
T_3_MODE_MULTICOLOR	EQU	3 
 
 
T_TRANSPARENT		EQU	0 
T_BLACK			EQU	1 
T_MED_GREEN		EQU	2 
T_LT_GREEN		EQU	3 
T_DK_BLUE		EQU	4 
T_LT_BLUE		EQU	5 
T_DK_RED		EQU	6 
T_CYAN			EQU	7 
T_MED_RED		EQU	8 
T_LT_RED		EQU	9 
T_DK_YELLOW		EQU	10 
T_LT_YELLOW		EQU	11 
T_DK_GREEN		EQU	12 
T_MAGENTA		EQU	13 
T_GREY			EQU	14 
T_WHITE			EQU	15 
 
T_REG_0			EQU	0 
T_REG_1			EQU	1 
T_REG_2			EQU	2 
T_REG_3			EQU	3 
T_REG_4			EQU	4 
T_REG_5			EQU	5 
T_REG_6			EQU	6 
T_REG_7			EQU	7 
T_NUM_REGISTERS		EQU	8 
T_REG_NAME_TABLE	EQU	T_REG_2 
T_REG_COLOR_TABLE	EQU	T_REG_3 
T_REG_PATTERN_TABLE	EQU	T_REG_4 
T_REG_SPRITE_ATTR_TABLE	EQU	T_REG_5 
T_REG_SPRITE_PATT_TABLE	EQU	T_REG_6 
T_REG_FG_BG_COLOR	EQU	T_REG_7 
 
T_R0_MODE_GR_I		EQU	00 
T_R0_MODE_GR_II		EQU	02 
T_R0_MODE_MULTICOLOR	EQU	00 
T_R0_MODE_TEXT		EQU	00 
T_R0_MODE_TEXT80	EQU	04 
T_R0_MODE_TEXT8_80	EQU	80h 
T_R0_EXT_VDP_ENABLE	EQU	01 
T_R0_EXT_VDP_DISABLE	EQU	00 
 
T_R1_RAM_16K		EQU	80h 
T_R1_RAM_4K		EQU	00 
T_R1_DISP_BLANK		EQU	00 
T_R1_DISP_ACTIVE	EQU	40h 
T_R1_INT_ENABLE		EQU	20h 
T_R1_INT_DISABLE	EQU	00 
T_R1_MODE_GRAPHICS_I	EQU	00 
T_R1_MODE_GRAPHICS_II	EQU	00 
T_R1_MODE_MULTICOLOR	EQU	08 
T_R1_MODE_TEXT		EQU	10h 
T_R1_SPR_8		EQU	00 
T_R1_SPR_16		EQU	02 
T_R1_SPR_MAG1		EQU	00 
T_R1_SPR_MAG2		EQU	01 
 
T_DEF_VRAM_NAME_ADDRESS		EQU	3800h 
T_DEF_VRAM_COLOR_ADDRESS	EQU	0000 
T_DEF_VRAM_PATT_ADDRESS		EQU	2000h 
T_DEF_VRAM_SPR_ATTR_ADDRESS	EQU	3B00h 
T_DEF_VRAM_SPR_PATT_ADDRESS	EQU	1800h 
 
T_T80_VRAM_COLOR_ADDRESS	EQU	0A00h 
T_T80_VRAM_NAME_ADDRESS		EQU	0000h 
T_T80_VRAM_PATT_ADDRESS		EQU	2000h 
T_T80_VRAM_ATTR_ADDRESS		EQU	3000h 
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
	IN	-1 
	MVI	A,0C0h 
	OUT	-1 
	MVI	A, VDP_LINE 
	OUT	VDP 
	OUT	VDP+1 
	@SYSREG	80h 
	IN	-1 
	MVI	A,80h 
	OUT	-1 
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
	;  char 0x00 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0x01 
	DB	000h, 000h, 000h, 07Eh, 081h, 0A5h, 081h, 081h, 0BDh, 099h, 081h, 081h, 07Eh, 000h, 000h, 000h 



	;  char 0x02 
	DB	000h, 000h, 000h, 07Eh, 0FFh, 0DBh, 0FFh, 0FFh, 0C3h, 0E7h, 0FFh, 0FFh, 07Eh, 000h, 000h, 000h 



	;  char 0x03 
	DB	000h, 000h, 000h, 066h, 0FFh, 0FFh, 0FFh, 0FFh, 07Eh, 07Eh, 03Ch, 03Ch, 018h, 018h, 000h, 000h 



	;  char 0x04 
	DB	000h, 000h, 018h, 018h, 03Ch, 03Ch, 07Eh, 07Eh, 0FFh, 07Eh, 07Eh, 03Ch, 03Ch, 018h, 018h, 000h 



	;  char 0x05 
	DB	000h, 000h, 000h, 018h, 03Ch, 03Ch, 018h, 066h, 0FFh, 0FFh, 066h, 018h, 03Ch, 07Eh, 000h, 000h 



	;  char 0x06 
	DB	000h, 000h, 018h, 018h, 03Ch, 03Ch, 07Eh, 0FFh, 0FFh, 0FFh, 07Eh, 018h, 03Ch, 07Eh, 000h, 000h 



	;  char 0x07 
	DB	000h, 000h, 000h, 000h, 000h, 018h, 03Ch, 03Ch, 03Ch, 018h, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0x08 
	DB	0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0E7h, 0C3h, 0C3h, 0C3h, 0E7h, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh 



	;  char 0x09 
	DB	000h, 000h, 000h, 000h, 03Ch, 066h, 042h, 042h, 042h, 066h, 03Ch, 000h, 000h, 000h, 000h, 000h 



	;  char 0x0a 
	DB	0FFh, 0FFh, 0FFh, 0FFh, 0C3h, 099h, 0BDh, 0BDh, 0BDh, 099h, 0C3h, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh 



	;  char 0x0b 
	DB	000h, 000h, 000h, 01Eh, 00Eh, 01Ah, 032h, 078h, 0CCh, 0CCh, 0CCh, 0CCh, 078h, 000h, 000h, 000h 



	;  char 0x0c 
	DB	000h, 000h, 000h, 03Ch, 066h, 066h, 066h, 066h, 03Ch, 018h, 07Eh, 018h, 018h, 000h, 000h, 000h 



	;  char 0x0d 
	DB	000h, 000h, 000h, 03Fh, 033h, 033h, 03Fh, 030h, 030h, 030h, 070h, 0F0h, 0E0h, 000h, 000h, 000h 



	;  char 0x0e 
	DB	000h, 000h, 000h, 07Fh, 063h, 063h, 07Fh, 063h, 063h, 063h, 067h, 0E7h, 0E6h, 0C0h, 000h, 000h 



	;  char 0x0f 
	DB	000h, 000h, 000h, 018h, 018h, 0DBh, 03Ch, 0E7h, 0E7h, 03Ch, 0DBh, 018h, 018h, 000h, 000h, 000h 



	;  char 0x10 
	DB	000h, 000h, 000h, 080h, 0C0h, 0E0h, 0F8h, 0FEh, 0FEh, 0F8h, 0E0h, 0C0h, 080h, 000h, 000h, 000h 



	;  char 0x11 
	DB	000h, 000h, 000h, 002h, 006h, 00Eh, 03Eh, 0FEh, 0FEh, 03Eh, 00Eh, 006h, 002h, 000h, 000h, 000h 



	;  char 0x12 
	DB	000h, 018h, 03Ch, 07Eh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 07Eh, 03Ch, 018h 



	;  char 0x13 
	DB	000h, 000h, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 000h, 066h, 066h, 000h, 000h 



	;  char 0x14 
	DB	000h, 000h, 07Fh, 0DBh, 0DBh, 0DBh, 0DBh, 0DBh, 07Bh, 01Bh, 01Bh, 01Bh, 01Bh, 01Bh, 000h, 000h 



	;  char 0x15 
	DB	000h, 000h, 07Ch, 0C6h, 060h, 038h, 06Ch, 0C6h, 0C6h, 06Ch, 038h, 00Ch, 0C6h, 07Ch, 000h, 000h 



	;  char 0x16 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 000h, 000h 



	;  char 0x17 
	DB	000h, 000h, 018h, 03Ch, 07Eh, 018h, 018h, 018h, 018h, 018h, 07Eh, 03Ch, 018h, 07Eh, 000h, 000h 



	;  char 0x18 
	DB	000h, 018h, 03Ch, 07Eh, 0FFh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h 



	;  char 0x19 
	DB	018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0FFh, 07Eh, 03Ch, 018h, 000h 



	;  char 0x1a 
	DB	000h, 000h, 000h, 000h, 000h, 008h, 00Ch, 00Eh, 0FFh, 00Eh, 00Ch, 008h, 000h, 000h, 000h, 000h 



	;  char 0x1b 
	DB	000h, 000h, 000h, 000h, 000h, 010h, 030h, 070h, 0FFh, 070h, 030h, 010h, 000h, 000h, 000h, 000h 



	;  char 0x1c 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 0C0h, 0C0h, 0C0h, 0C0h, 0FEh, 0FEh, 000h, 000h, 000h, 000h 



	;  char 0x1d 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 024h, 066h, 0FFh, 066h, 024h, 000h, 000h, 000h, 000h, 000h 



	;  char 0x1e 
	DB	000h, 000h, 000h, 000h, 010h, 010h, 038h, 038h, 07Ch, 07Ch, 0FEh, 0FEh, 000h, 000h, 000h, 000h 



	;  char 0x1f 
	DB	000h, 000h, 000h, 000h, 0FEh, 0FEh, 07Ch, 07Ch, 038h, 038h, 010h, 010h, 000h, 000h, 000h, 000h 



	;  char 0x20 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0x21 
	DB	000h, 018h, 03Ch, 03Ch, 03Ch, 03Ch, 018h, 018h, 018h, 018h, 000h, 018h, 018h, 000h, 000h, 000h 



	;  char 0x22 
	DB	000h, 063h, 063h, 0C6h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0x23 
	DB	000h, 06Ch, 06Ch, 06Ch, 0FEh, 0FEh, 06Ch, 06Ch, 06Ch, 0FEh, 0FEh, 06Ch, 06Ch, 06Ch, 000h, 000h 



	;  char 0x24 
	DB	000h, 018h, 07Eh, 0DBh, 0DBh, 0E8h, 078h, 03Ch, 01Eh, 017h, 0DBh, 0DBh, 07Eh, 018h, 018h, 000h 



	;  char 0x25 
	DB	000h, 0E6h, 0A6h, 0ECh, 00Ch, 018h, 018h, 030h, 030h, 060h, 06Eh, 0CAh, 0CEh, 000h, 000h, 000h 



	;  char 0x26 
	DB	000h, 038h, 06Ch, 06Ch, 06Ch, 038h, 038h, 06Dh, 0CDh, 0C6h, 0C6h, 0CBh, 073h, 000h, 000h, 000h 



	;  char 0x27 
	DB	000h, 018h, 018h, 030h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0x28 
	DB	000h, 00Ch, 018h, 018h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 018h, 018h, 00Ch, 000h, 000h 



	;  char 0x29 
	DB	000h, 030h, 018h, 018h, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 018h, 018h, 030h, 000h, 000h 



	;  char 0x2a 
	DB	000h, 000h, 000h, 000h, 066h, 066h, 03Ch, 0FFh, 0FFh, 03Ch, 066h, 066h, 000h, 000h, 000h, 000h 



	;  char 0x2b 
	DB	000h, 000h, 000h, 000h, 000h, 018h, 018h, 07Eh, 07Eh, 018h, 018h, 000h, 000h, 000h, 000h, 000h 



	;  char 0x2c 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 018h, 018h, 030h, 000h, 000h 



	;  char 0x2d 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Eh, 07Eh, 000h, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0x2e 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 018h, 018h, 000h, 000h, 000h 



	;  char 0x2f 
	DB	000h, 006h, 006h, 00Ch, 00Ch, 018h, 018h, 030h, 030h, 060h, 060h, 0C0h, 0C0h, 000h, 000h, 000h 



	;  char 0x30 
	DB	000h, 07Ch, 0C6h, 0C6h, 0C6h, 0CEh, 0DEh, 0F6h, 0E6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h 



	;  char 0x31 
	DB	000h, 018h, 038h, 078h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 07Eh, 000h, 000h, 000h 



	;  char 0x32 
	DB	000h, 03Ch, 066h, 0C3h, 0C3h, 003h, 006h, 00Ch, 018h, 030h, 060h, 0C3h, 0FFh, 000h, 000h, 000h 



	;  char 0x33 
	DB	000h, 0FEh, 0C6h, 00Ch, 018h, 03Ch, 006h, 003h, 003h, 003h, 0C3h, 066h, 03Ch, 000h, 000h, 000h 



	;  char 0x34 
	DB	000h, 01Ch, 01Ch, 03Ch, 03Ch, 06Ch, 06Ch, 0CCh, 0CDh, 0FFh, 00Dh, 00Ch, 01Eh, 000h, 000h, 000h 



	;  char 0x35 
	DB	000h, 0FEh, 0C0h, 0C0h, 0C0h, 0FCh, 0E6h, 0C3h, 003h, 003h, 0C3h, 066h, 03Ch, 000h, 000h, 000h 



	;  char 0x36 
	DB	000h, 03Ch, 066h, 0C6h, 0C0h, 0FCh, 0E6h, 0C3h, 0C3h, 0C3h, 0C3h, 066h, 03Ch, 000h, 000h, 000h 



	;  char 0x37 
	DB	000h, 0FEh, 0C6h, 006h, 00Ch, 00Ch, 018h, 018h, 030h, 030h, 030h, 030h, 030h, 000h, 000h, 000h 



	;  char 0x38 
	DB	000h, 03Ch, 066h, 0C3h, 0C3h, 066h, 03Ch, 066h, 0C3h, 0C3h, 0C3h, 066h, 03Ch, 000h, 000h, 000h 



	;  char 0x39 
	DB	000h, 03Ch, 066h, 0C3h, 0C3h, 0C3h, 0C3h, 067h, 03Fh, 003h, 063h, 066h, 03Ch, 000h, 000h, 000h 



	;  char 0x3a 
	DB	000h, 000h, 000h, 000h, 000h, 018h, 018h, 000h, 000h, 000h, 000h, 018h, 018h, 000h, 000h, 000h 



	;  char 0x3b 
	DB	000h, 000h, 000h, 000h, 000h, 018h, 018h, 000h, 000h, 000h, 000h, 018h, 018h, 030h, 000h, 000h 



	;  char 0x3c 
	DB	000h, 000h, 003h, 006h, 00Ch, 018h, 030h, 070h, 030h, 018h, 00Ch, 006h, 003h, 000h, 000h, 000h 



	;  char 0x3d 
	DB	000h, 000h, 000h, 000h, 000h, 07Eh, 07Eh, 000h, 07Eh, 07Eh, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0x3e 
	DB	000h, 000h, 0C0h, 060h, 030h, 018h, 00Ch, 006h, 00Ch, 018h, 030h, 060h, 0C0h, 000h, 000h, 000h 



	;  char 0x3f 
	DB	000h, 03Ch, 066h, 0C3h, 0C3h, 003h, 006h, 00Ch, 018h, 018h, 000h, 018h, 018h, 000h, 000h, 000h 



	;  char 0x40 
	DB	000h, 000h, 000h, 07Eh, 0C3h, 0C3h, 0DFh, 0DBh, 0DBh, 0DEh, 0C0h, 0C0h, 07Ch, 000h, 000h, 000h 



	;  char 0x41 
	DB	000h, 010h, 038h, 07Ch, 0EEh, 0C6h, 0C6h, 0C6h, 0C6h, 0FEh, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h 



	;  char 0x42 
	DB	000h, 0FEh, 063h, 063h, 063h, 063h, 07Eh, 063h, 063h, 063h, 063h, 063h, 0FEh, 000h, 000h, 000h 



	;  char 0x43 
	DB	000h, 03Ch, 066h, 0C3h, 0C3h, 0C0h, 0C0h, 0C0h, 0C0h, 0C3h, 0C3h, 066h, 03Ch, 000h, 000h, 000h 



	;  char 0x44 
	DB	000h, 0FCh, 066h, 063h, 063h, 063h, 063h, 063h, 063h, 063h, 063h, 066h, 0FCh, 000h, 000h, 000h 



	;  char 0x45 
	DB	000h, 0FFh, 063h, 061h, 060h, 064h, 07Ch, 064h, 060h, 060h, 061h, 063h, 0FFh, 000h, 000h, 000h 



	;  char 0x46 
	DB	000h, 0FFh, 063h, 061h, 060h, 064h, 07Ch, 064h, 060h, 060h, 060h, 060h, 0F8h, 000h, 000h, 000h 



	;  char 0x47 
	DB	000h, 03Ch, 066h, 0C3h, 0C3h, 0C0h, 0C0h, 0CFh, 0C3h, 0C3h, 0C3h, 067h, 03Dh, 000h, 000h, 000h 



	;  char 0x48 
	DB	000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0FEh, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h 



	;  char 0x49 
	DB	000h, 03Ch, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h 



	;  char 0x4a 
	DB	000h, 00Fh, 006h, 006h, 006h, 006h, 006h, 006h, 006h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h 



	;  char 0x4b 
	DB	000h, 0E3h, 063h, 066h, 066h, 06Ch, 07Ch, 06Ch, 066h, 066h, 063h, 063h, 0E3h, 000h, 000h, 000h 



	;  char 0x4c 
	DB	000h, 0F0h, 060h, 060h, 060h, 060h, 060h, 060h, 060h, 060h, 061h, 063h, 0FFh, 000h, 000h, 000h 



	;  char 0x4d 
	DB	000h, 0C3h, 0E7h, 0FFh, 0FFh, 0DBh, 0DBh, 0DBh, 0C3h, 0C3h, 0C3h, 0C3h, 0C3h, 000h, 000h, 000h 



	;  char 0x4e 
	DB	000h, 0C6h, 0C6h, 0E6h, 0E6h, 0F6h, 0F6h, 0DEh, 0DEh, 0CEh, 0CEh, 0C6h, 0C6h, 000h, 000h, 000h 



	;  char 0x4f 
	DB	000h, 03Ch, 066h, 0C3h, 0C3h, 0C3h, 0C3h, 0C3h, 0C3h, 0C3h, 0C3h, 066h, 03Ch, 000h, 000h, 000h 



	;  char 0x50 
	DB	000h, 0FEh, 063h, 063h, 063h, 063h, 063h, 07Eh, 060h, 060h, 060h, 060h, 0F0h, 000h, 000h, 000h 



	;  char 0x51 
	DB	000h, 03Ch, 066h, 0C3h, 0C3h, 0C3h, 0C3h, 0C3h, 0C3h, 0CBh, 0CFh, 07Eh, 03Ch, 006h, 007h, 000h 



	;  char 0x52 
	DB	000h, 0FEh, 063h, 063h, 063h, 063h, 063h, 07Eh, 06Ch, 066h, 066h, 066h, 0F7h, 000h, 000h, 000h 



	;  char 0x53 
	DB	000h, 07Eh, 0C3h, 0C3h, 0C0h, 0C0h, 07Eh, 003h, 003h, 003h, 0C3h, 0C3h, 07Eh, 000h, 000h, 000h 



	;  char 0x54 
	DB	000h, 0FFh, 0DBh, 099h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h 



	;  char 0x55 
	DB	000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h 



	;  char 0x56 
	DB	000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 038h, 010h, 000h, 000h, 000h 



	;  char 0x57 
	DB	000h, 0C3h, 0C3h, 0C3h, 0C3h, 0DBh, 0DBh, 0DBh, 0DBh, 0DBh, 0FFh, 066h, 066h, 000h, 000h, 000h 



	;  char 0x58 
	DB	000h, 0C6h, 0C6h, 06Ch, 06Ch, 038h, 038h, 038h, 038h, 06Ch, 06Ch, 0C6h, 0C6h, 000h, 000h, 000h 



	;  char 0x59 
	DB	000h, 0C3h, 0C3h, 0C3h, 0C3h, 0E7h, 07Eh, 03Ch, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h 



	;  char 0x5a 
	DB	000h, 0FEh, 0C6h, 08Ch, 00Ch, 018h, 018h, 030h, 030h, 060h, 062h, 0C6h, 0FEh, 000h, 000h, 000h 



	;  char 0x5b 
	DB	000h, 03Ch, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 03Ch, 000h, 000h, 000h 



	;  char 0x5c 
	DB	000h, 0C0h, 0C0h, 060h, 060h, 030h, 030h, 018h, 018h, 00Ch, 00Ch, 006h, 006h, 000h, 000h, 000h 



	;  char 0x5d 
	DB	000h, 03Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 03Ch, 000h, 000h, 000h 



	;  char 0x5e 
	DB	000h, 018h, 03Ch, 066h, 0C3h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0x5f 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 000h 



	;  char 0x60 
	DB	000h, 030h, 030h, 018h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0x61 
	DB	000h, 000h, 000h, 000h, 000h, 03Ch, 006h, 03Eh, 066h, 066h, 066h, 066h, 03Bh, 000h, 000h, 000h 



	;  char 0x62 
	DB	000h, 0E0h, 060h, 060h, 060h, 07Eh, 063h, 063h, 063h, 063h, 063h, 063h, 0DEh, 000h, 000h, 000h 



	;  char 0x63 
	DB	000h, 000h, 000h, 000h, 000h, 07Ch, 0C6h, 0C0h, 0C0h, 0C0h, 0C0h, 0C6h, 07Ch, 000h, 000h, 000h 



	;  char 0x64 
	DB	000h, 00Eh, 006h, 006h, 006h, 07Eh, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Bh, 000h, 000h, 000h 



	;  char 0x65 
	DB	000h, 000h, 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0FEh, 0C0h, 0C0h, 0C6h, 07Ch, 000h, 000h, 000h 



	;  char 0x66 
	DB	000h, 03Ch, 066h, 066h, 060h, 0F0h, 060h, 060h, 060h, 060h, 060h, 060h, 0F0h, 000h, 000h, 000h 



	;  char 0x67 
	DB	000h, 000h, 000h, 000h, 000h, 07Bh, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Eh, 006h, 0C6h, 07Ch 



	;  char 0x68 
	DB	000h, 0E0h, 060h, 060h, 060h, 07Ch, 066h, 066h, 066h, 066h, 066h, 066h, 0E6h, 000h, 000h, 000h 



	;  char 0x69 
	DB	000h, 000h, 018h, 018h, 000h, 038h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h 



	;  char 0x6a 
	DB	000h, 000h, 006h, 006h, 000h, 00Eh, 006h, 006h, 006h, 006h, 006h, 006h, 006h, 066h, 066h, 03Ch 



	;  char 0x6b 
	DB	000h, 0E0h, 060h, 060h, 060h, 066h, 066h, 06Ch, 078h, 06Ch, 066h, 066h, 0E6h, 000h, 000h, 000h 



	;  char 0x6c 
	DB	000h, 038h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h 



	;  char 0x6d 
	DB	000h, 000h, 000h, 000h, 000h, 0E6h, 0FFh, 0DBh, 0DBh, 0DBh, 0C3h, 0C3h, 0C3h, 000h, 000h, 000h 



	;  char 0x6e 
	DB	000h, 000h, 000h, 000h, 000h, 0DCh, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 000h, 000h, 000h 



	;  char 0x6f 
	DB	000h, 000h, 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h 



	;  char 0x70 
	DB	000h, 000h, 000h, 000h, 000h, 0DEh, 063h, 063h, 063h, 063h, 063h, 063h, 07Eh, 060h, 060h, 0F0h 



	;  char 0x71 
	DB	000h, 000h, 000h, 000h, 000h, 07Bh, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Eh, 006h, 006h, 00Fh 



	;  char 0x72 
	DB	000h, 000h, 000h, 000h, 000h, 0DEh, 073h, 063h, 060h, 060h, 060h, 060h, 0F0h, 000h, 000h, 000h 



	;  char 0x73 
	DB	000h, 000h, 000h, 000h, 000h, 07Ch, 0C6h, 0C0h, 070h, 01Ch, 006h, 0C6h, 07Ch, 000h, 000h, 000h 



	;  char 0x74 
	DB	000h, 000h, 010h, 030h, 030h, 0FCh, 030h, 030h, 030h, 030h, 030h, 036h, 01Ch, 000h, 000h, 000h 



	;  char 0x75 
	DB	000h, 000h, 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Bh, 000h, 000h, 000h 



	;  char 0x76 
	DB	000h, 000h, 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0EEh, 07Ch, 038h, 010h, 000h, 000h, 000h 



	;  char 0x77 
	DB	000h, 000h, 000h, 000h, 000h, 0C3h, 0C3h, 0DBh, 0DBh, 0DBh, 0DBh, 0FFh, 066h, 000h, 000h, 000h 



	;  char 0x78 
	DB	000h, 000h, 000h, 000h, 000h, 0C6h, 0EEh, 07Ch, 038h, 038h, 07Ch, 0EEh, 0C6h, 000h, 000h, 000h 



	;  char 0x79 
	DB	000h, 000h, 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Eh, 00Ch, 018h, 070h 



	;  char 0x7a 
	DB	000h, 000h, 000h, 000h, 000h, 0FEh, 0C6h, 00Ch, 018h, 030h, 060h, 0C6h, 0FEh, 000h, 000h, 000h 



	;  char 0x7b 
	DB	000h, 00Eh, 018h, 018h, 018h, 018h, 070h, 070h, 018h, 018h, 018h, 018h, 00Eh, 000h, 000h, 000h 



	;  char 0x7c 
	DB	000h, 018h, 018h, 018h, 018h, 018h, 000h, 000h, 018h, 018h, 018h, 018h, 018h, 000h, 000h, 000h 



	;  char 0x7d 
	DB	000h, 070h, 018h, 018h, 018h, 018h, 01Eh, 01Eh, 018h, 018h, 018h, 018h, 070h, 000h, 000h, 000h 



	;  char 0x7e 
	DB	000h, 000h, 076h, 0DCh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0x7f 
	DB	000h, 000h, 000h, 000h, 000h, 010h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0FEh, 000h, 000h, 000h, 000h 



	;  char 0x80 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0x81 
	DB	018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h 



	;  char 0x82 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 01Fh, 018h, 018h, 018h, 018h, 018h, 018h, 018h 



	;  char 0x83 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0F8h, 018h, 018h, 018h, 018h, 018h, 018h, 018h 



	;  char 0x84 
	DB	018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 01Fh, 000h, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0x85 
	DB	018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0F8h, 000h, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0x86 
	DB	018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 01Fh, 018h, 018h, 018h, 018h, 018h, 018h, 018h 



	;  char 0x87 
	DB	018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0F8h, 018h, 018h, 018h, 018h, 018h, 018h, 018h 



	;  char 0x88 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 018h, 018h, 018h, 018h, 018h, 018h, 018h 



	;  char 0x89 
	DB	018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0x8a 
	DB	018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0FFh, 018h, 018h, 018h, 018h, 018h, 018h, 018h 



	;  char 0x8b 
	DB	0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0x8c 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh 



	;  char 0x8d 
	DB	0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh 



	;  char 0x8e 
	DB	0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h 



	;  char 0x8f 
	DB	00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh 



	;  char 0x90 
	DB	082h, 010h, 082h, 010h, 082h, 010h, 082h, 010h, 082h, 010h, 082h, 010h, 082h, 010h, 082h, 010h 



	;  char 0x91 
	DB	0C3h, 018h, 0C3h, 018h, 0C3h, 018h, 0C3h, 018h, 0C3h, 018h, 0C3h, 018h, 0C3h, 018h, 0C3h, 018h 



	;  char 0x92 
	DB	0D8h, 083h, 0DAh, 013h, 0D8h, 083h, 0DAh, 013h, 0D8h, 083h, 0DAh, 013h, 0D8h, 083h, 0DAh, 013h 



	;  char 0x93 
	DB	000h, 000h, 00Eh, 01Bh, 01Bh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h 



	;  char 0x94 
	DB	000h, 000h, 000h, 000h, 07Ch, 07Ch, 07Ch, 07Ch, 07Ch, 07Ch, 07Ch, 000h, 000h, 000h, 000h, 000h 



	;  char 0x95 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 000h, 018h, 018h, 000h, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0x96 
	DB	000h, 00Fh, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 0ECh, 06Ch, 03Ch, 01Ch, 000h, 000h, 000h 



	;  char 0x97 
	DB	000h, 000h, 000h, 000h, 000h, 076h, 0DCh, 000h, 076h, 0DCh, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0x98 
	DB	000h, 000h, 00Ch, 018h, 030h, 060h, 0C0h, 060h, 030h, 018h, 00Ch, 000h, 07Ch, 000h, 000h, 000h 



	;  char 0x99 
	DB	000h, 000h, 060h, 030h, 018h, 00Ch, 006h, 00Ch, 018h, 030h, 060h, 000h, 07Eh, 000h, 000h, 000h 



	;  char 0x9a 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 042h, 042h, 07Eh, 000h, 000h, 000h 



	;  char 0x9b 
	DB	018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0D8h, 0F8h, 070h, 000h, 000h, 000h 



	;  char 0x9c 
	DB	000h, 000h, 038h, 06Ch, 06Ch, 06Ch, 038h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0x9d 
	DB	000h, 070h, 088h, 010h, 060h, 088h, 0F8h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0x9e 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 018h, 000h, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0x9f 
	DB	000h, 000h, 000h, 000h, 018h, 018h, 000h, 07Eh, 07Eh, 000h, 018h, 018h, 000h, 000h, 000h, 000h 



	;  char 0xa0 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0xa1 
	DB	036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h 



	;  char 0xa2 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 01Fh, 018h, 01Fh, 018h, 018h, 018h, 018h, 018h, 018h, 018h 



	;  char 0xa3 
	DB	000h, 000h, 000h, 0C6h, 000h, 000h, 07Ch, 0C6h, 0FEh, 0C0h, 0C0h, 0C6h, 07Ch, 000h, 000h, 000h 



	;  char 0xa4 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 03Fh, 036h, 036h, 036h, 036h, 036h, 036h, 036h 



	;  char 0xa5 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 03Fh, 030h, 037h, 036h, 036h, 036h, 036h, 036h, 036h, 036h 



	;  char 0xa6 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 0F8h, 018h, 0F8h, 018h, 018h, 018h, 018h, 018h, 018h, 018h 



	;  char 0xa7 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 036h, 036h, 036h, 036h, 036h, 036h, 036h 



	;  char 0xa8 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 006h, 0F6h, 036h, 036h, 036h, 036h, 036h, 036h, 036h 



	;  char 0xa9 
	DB	018h, 018h, 018h, 018h, 018h, 018h, 01Fh, 018h, 01Fh, 000h, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0xaa 
	DB	036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 03Fh, 000h, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0xab 
	DB	036h, 036h, 036h, 036h, 036h, 036h, 037h, 030h, 03Fh, 000h, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0xac 
	DB	018h, 018h, 018h, 018h, 018h, 018h, 0F8h, 018h, 0F8h, 000h, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0xad 
	DB	036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0xae 
	DB	036h, 036h, 036h, 036h, 036h, 036h, 0F6h, 006h, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0xaf 
	DB	018h, 018h, 018h, 018h, 018h, 018h, 01Fh, 018h, 01Fh, 018h, 018h, 018h, 018h, 018h, 018h, 018h 



	;  char 0xb0 
	DB	036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 037h, 036h, 036h, 036h, 036h, 036h, 036h, 036h 



	;  char 0xb1 
	DB	036h, 036h, 036h, 036h, 036h, 036h, 037h, 030h, 037h, 036h, 036h, 036h, 036h, 036h, 036h, 036h 



	;  char 0xb2 
	DB	018h, 018h, 018h, 018h, 018h, 018h, 0F8h, 018h, 0F8h, 018h, 018h, 018h, 018h, 018h, 018h, 018h 



	;  char 0xb3 
	DB	000h, 000h, 06Ch, 06Ch, 000h, 0FEh, 066h, 060h, 07Ch, 060h, 060h, 066h, 0FEh, 000h, 000h, 000h 



	;  char 0xb4 
	DB	036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0F6h, 036h, 036h, 036h, 036h, 036h, 036h, 036h 



	;  char 0xb5 
	DB	036h, 036h, 036h, 036h, 036h, 036h, 0F6h, 006h, 0F6h, 036h, 036h, 036h, 036h, 036h, 036h, 036h 



	;  char 0xb6 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 0FFh, 018h, 018h, 018h, 018h, 018h, 018h, 018h 



	;  char 0xb7 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 036h, 036h, 036h, 036h, 036h, 036h, 036h 



	;  char 0xb8 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 0F7h, 036h, 036h, 036h, 036h, 036h, 036h, 036h 



	;  char 0xb9 
	DB	018h, 018h, 018h, 018h, 018h, 018h, 0FFh, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0xba 
	DB	036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0xbb 
	DB	036h, 036h, 036h, 036h, 036h, 036h, 0F7h, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h 



	;  char 0xbc 
	DB	018h, 018h, 018h, 018h, 018h, 018h, 0FFh, 018h, 0FFh, 018h, 018h, 018h, 018h, 018h, 018h, 018h 



	;  char 0xbd 
	DB	036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0FFh, 036h, 036h, 036h, 036h, 036h, 036h, 036h 



	;  char 0xbe 
	DB	036h, 036h, 036h, 036h, 036h, 036h, 0F7h, 000h, 0F7h, 036h, 036h, 036h, 036h, 036h, 036h, 036h 



	;  char 0xbf 
	DB	000h, 000h, 000h, 03Ch, 042h, 099h, 0A1h, 0A1h, 099h, 042h, 03Ch, 000h, 000h, 000h, 000h, 000h 



	;  char 0xc0 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 0CEh, 0DBh, 0DBh, 0FBh, 0DBh, 0DBh, 0CEh, 000h, 000h, 000h 



	;  char 0xc1 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 078h, 00Ch, 07Ch, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h 



	;  char 0xc2 
	DB	000h, 000h, 002h, 006h, 03Ch, 060h, 060h, 07Ch, 066h, 066h, 066h, 066h, 03Ch, 000h, 000h, 000h 



	;  char 0xc3 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0FEh, 006h, 006h, 000h 



	;  char 0xc4 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 01Eh, 036h, 036h, 066h, 066h, 066h, 0FFh, 0C3h, 0C3h, 000h 



	;  char 0xc5 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 07Ch, 0C6h, 0FEh, 0C0h, 0C0h, 0C6h, 07Ch, 000h, 000h, 000h 



	;  char 0xc6 
	DB	000h, 000h, 000h, 000h, 000h, 03Ch, 018h, 07Eh, 0DBh, 0DBh, 0DBh, 0DBh, 07Eh, 018h, 018h, 03Ch 



	;  char 0xc7 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 07Eh, 032h, 032h, 030h, 030h, 030h, 078h, 000h, 000h, 000h 



	;  char 0xc8 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 0C6h, 06Ch, 038h, 038h, 038h, 06Ch, 0C6h, 000h, 000h, 000h 



	;  char 0xc9 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 0C6h, 0C6h, 0CEh, 0D6h, 0E6h, 0C6h, 0C6h, 000h, 000h, 000h 



	;  char 0xca 
	DB	000h, 000h, 000h, 000h, 038h, 038h, 0C6h, 0C6h, 0CEh, 0D6h, 0E6h, 0C6h, 0C6h, 000h, 000h, 000h 



	;  char 0xcb 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 0E6h, 06Ch, 078h, 078h, 06Ch, 066h, 0E6h, 000h, 000h, 000h 



	;  char 0xcc 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 01Eh, 036h, 066h, 066h, 066h, 066h, 066h, 000h, 000h, 000h 



	;  char 0xcd 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 0C6h, 0EEh, 0FEh, 0FEh, 0D6h, 0D6h, 0C6h, 000h, 000h, 000h 



	;  char 0xce 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0FEh, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h 



	;  char 0xcf 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h 



	;  char 0xd0 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h 



	;  char 0xd1 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 07Eh, 0CCh, 0CCh, 0FCh, 06Ch, 0CCh, 0CEh, 000h, 000h, 000h 



	;  char 0xd2 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 0DCh, 066h, 066h, 066h, 066h, 066h, 07Ch, 060h, 060h, 0F0h 



	;  char 0xd3 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 07Ch, 0C6h, 0C0h, 0C0h, 0C0h, 0C6h, 07Ch, 000h, 000h, 000h 



	;  char 0xd4 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 07Eh, 05Ah, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h 



	;  char 0xd5 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Eh, 006h, 006h, 0C6h, 07Ch 



	;  char 0xd6 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 0D6h, 0D6h, 054h, 07Ch, 054h, 0D6h, 0D6h, 000h, 000h, 000h 



	;  char 0xd7 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 0FCh, 066h, 066h, 07Ch, 066h, 066h, 0FCh, 000h, 000h, 000h 



	;  char 0xd8 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 0F0h, 060h, 060h, 07Ch, 066h, 066h, 0FCh, 000h, 000h, 000h 



	;  char 0xd9 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0F6h, 0DEh, 0DEh, 0F6h, 000h, 000h, 000h 



	;  char 0xda 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 03Ch, 066h, 006h, 00Ch, 006h, 066h, 03Ch, 000h, 000h, 000h 



	;  char 0xdb 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 0D6h, 0D6h, 0D6h, 0D6h, 0D6h, 0D6h, 0FEh, 000h, 000h, 000h 



	;  char 0xdc 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 03Eh, 067h, 003h, 01Fh, 003h, 067h, 03Eh, 000h, 000h, 000h 



	;  char 0xdd 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 0D6h, 0D6h, 0D6h, 0D6h, 0D6h, 0D6h, 0FEh, 003h, 003h, 000h 



	;  char 0xde 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 07Eh, 006h, 006h, 000h, 000h, 000h 



	;  char 0xdf 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 0F8h, 0B0h, 030h, 03Eh, 033h, 033h, 07Eh, 000h, 000h, 000h 



	;  char 0xe0 
	DB	000h, 000h, 000h, 0CEh, 0DBh, 0DBh, 0DBh, 0FBh, 0DBh, 0DBh, 0DBh, 0DBh, 0CEh, 000h, 000h, 000h 



	;  char 0xe1 
	DB	000h, 000h, 000h, 010h, 038h, 06Ch, 0C6h, 0C6h, 0FEh, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h 



	;  char 0xe2 
	DB	000h, 000h, 000h, 0FEh, 062h, 062h, 060h, 07Ch, 066h, 066h, 066h, 066h, 0FCh, 000h, 000h, 000h 



	;  char 0xe3 
	DB	000h, 000h, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0FEh, 006h, 006h, 000h 



	;  char 0xe4 
	DB	000h, 000h, 000h, 01Eh, 036h, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 0FFh, 0C3h, 081h, 000h 



	;  char 0xe5 
	DB	000h, 000h, 000h, 0FEh, 066h, 062h, 068h, 078h, 068h, 060h, 062h, 066h, 0FEh, 000h, 000h, 000h 



	;  char 0xe6 
	DB	000h, 000h, 03Ch, 018h, 07Eh, 0DBh, 0DBh, 0DBh, 0DBh, 0DBh, 07Eh, 018h, 03Ch, 000h, 000h, 000h 



	;  char 0xe7 
	DB	000h, 000h, 000h, 0FEh, 062h, 062h, 060h, 060h, 060h, 060h, 060h, 060h, 0F0h, 000h, 000h, 000h 



	;  char 0xe8 
	DB	000h, 000h, 000h, 0C6h, 0C6h, 06Ch, 07Ch, 038h, 038h, 07Ch, 06Ch, 0C6h, 0C6h, 000h, 000h, 000h 



	;  char 0xe9 
	DB	000h, 000h, 000h, 0C6h, 0C6h, 0CEh, 0CEh, 0D6h, 0E6h, 0E6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h 



	;  char 0xea 
	DB	000h, 038h, 038h, 0C6h, 0C6h, 0CEh, 0CEh, 0D6h, 0E6h, 0E6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h 



	;  char 0xeb 
	DB	000h, 000h, 000h, 0E6h, 066h, 06Ch, 06Ch, 078h, 078h, 06Ch, 06Ch, 066h, 0E6h, 000h, 000h, 000h 



	;  char 0xec 
	DB	000h, 000h, 000h, 01Eh, 036h, 066h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h 



	;  char 0xed 
	DB	000h, 000h, 000h, 0C6h, 0EEh, 0FEh, 0FEh, 0D6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h 



	;  char 0xee 
	DB	000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0FEh, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h 



	;  char 0xef 
	DB	000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h 



	;  char 0xf0 
	DB	000h, 000h, 000h, 0FEh, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h 



	;  char 0xf1 
	DB	000h, 000h, 000h, 03Fh, 066h, 066h, 066h, 03Eh, 03Eh, 066h, 066h, 066h, 0E7h, 000h, 000h, 000h 



	;  char 0xf2 
	DB	000h, 000h, 000h, 0FCh, 066h, 066h, 066h, 07Ch, 060h, 060h, 060h, 060h, 0F0h, 000h, 000h, 000h 



	;  char 0xf3 
	DB	000h, 000h, 000h, 03Ch, 066h, 0C2h, 0C0h, 0C0h, 0C0h, 0C0h, 0C2h, 066h, 03Ch, 000h, 000h, 000h 



	;  char 0xf4 
	DB	000h, 000h, 000h, 07Eh, 05Ah, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h 



	;  char 0xf5 
	DB	000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Eh, 006h, 006h, 0C6h, 07Ch, 000h, 000h, 000h 



	;  char 0xf6 
	DB	000h, 000h, 000h, 0D6h, 0D6h, 054h, 054h, 07Ch, 07Ch, 054h, 0D6h, 0D6h, 0D6h, 000h, 000h, 000h 



	;  char 0xf7 
	DB	000h, 000h, 000h, 0FCh, 066h, 066h, 066h, 07Ch, 066h, 066h, 066h, 066h, 0FCh, 000h, 000h, 000h 



	;  char 0xf8 
	DB	000h, 000h, 000h, 0F0h, 060h, 060h, 060h, 07Ch, 066h, 066h, 066h, 066h, 0FCh, 000h, 000h, 000h 



	;  char 0xf9 
	DB	000h, 000h, 000h, 0C3h, 0C3h, 0C3h, 0C3h, 0F3h, 0DBh, 0DBh, 0DBh, 0DBh, 0F3h, 000h, 000h, 000h 



	;  char 0xfa 
	DB	000h, 000h, 000h, 07Ch, 0C6h, 006h, 006h, 03Ch, 006h, 006h, 006h, 0C6h, 07Ch, 000h, 000h, 000h 



	;  char 0xfb 
	DB	000h, 000h, 000h, 0DBh, 0DBh, 0DBh, 0DBh, 0DBh, 0DBh, 0DBh, 0DBh, 0DBh, 0FFh, 000h, 000h, 000h 



	;  char 0xfc 
	DB	000h, 000h, 000h, 078h, 0CCh, 006h, 026h, 03Eh, 026h, 006h, 006h, 0CCh, 078h, 000h, 000h, 000h 



	;  char 0xfd 
	DB	000h, 000h, 000h, 0DBh, 0DBh, 0DBh, 0DBh, 0DBh, 0DBh, 0DBh, 0DBh, 0DBh, 0FFh, 003h, 003h, 000h 



	;  char 0xfe 
	DB	000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Eh, 006h, 006h, 006h, 006h, 000h, 000h, 000h 



	;  char 0xff 
	DB	0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh 



tmsFontEnd: 
tmsFont8: 
include fontMsx.asm 
	;  char 0x00 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h 

	;  char 0x01 
	DB	03Ch, 042h, 0A5h, 081h, 0A5h, 099h, 042h, 03Ch 

	;  char 0x02 
	DB	03Ch, 07Eh, 0DBh, 0FFh, 0FFh, 0DBh, 066h, 03Ch 

	;  char 0x03 
	DB	06Ch, 0FEh, 0FEh, 0FEh, 07Ch, 038h, 010h, 000h 

	;  char 0x04 
	DB	010h, 038h, 07Ch, 0FEh, 07Ch, 038h, 010h, 000h 

	;  char 0x05 
	DB	010h, 038h, 054h, 0FEh, 054h, 010h, 038h, 000h 

	;  char 0x06 
	DB	010h, 038h, 07Ch, 0FEh, 0FEh, 010h, 038h, 000h 

	;  char 0x07 
	DB	000h, 000h, 000h, 030h, 030h, 000h, 000h, 000h 

	;  char 0x08 
	DB	0FFh, 0FFh, 0FFh, 0E7h, 0E7h, 0FFh, 0FFh, 0FFh 

	;  char 0x09 
	DB	038h, 044h, 082h, 082h, 082h, 044h, 038h, 000h 

	;  char 0x0a 
	DB	0C7h, 0BBh, 07Dh, 07Dh, 07Dh, 0BBh, 0C7h, 0FFh 

	;  char 0x0b 
	DB	00Fh, 003h, 005h, 079h, 088h, 088h, 088h, 070h 

	;  char 0x0c 
	DB	038h, 044h, 044h, 044h, 038h, 010h, 07Ch, 010h 

	;  char 0x0d 
	DB	030h, 028h, 024h, 024h, 028h, 020h, 0E0h, 0C0h 

	;  char 0x0e 
	DB	03Ch, 024h, 03Ch, 024h, 024h, 0E4h, 0DCh, 018h 

	;  char 0x0f 
	DB	010h, 054h, 038h, 0EEh, 038h, 054h, 010h, 000h 

	;  char 0x10 
	DB	010h, 010h, 010h, 07Ch, 010h, 010h, 010h, 010h 

	;  char 0x11 
	DB	010h, 010h, 010h, 0FFh, 000h, 000h, 000h, 000h 

	;  char 0x12 
	DB	000h, 000h, 000h, 0FFh, 010h, 010h, 010h, 010h 

	;  char 0x13 
	DB	010h, 010h, 010h, 0F0h, 010h, 010h, 010h, 010h 

	;  char 0x14 
	DB	010h, 010h, 010h, 01Fh, 010h, 010h, 010h, 010h 

	;  char 0x15 
	DB	010h, 010h, 010h, 0FFh, 010h, 010h, 010h, 010h 

	;  char 0x16 
	DB	010h, 010h, 010h, 010h, 010h, 010h, 010h, 010h 

	;  char 0x17 
	DB	000h, 000h, 000h, 0FFh, 000h, 000h, 000h, 000h 

	;  char 0x18 
	DB	000h, 000h, 000h, 01Fh, 010h, 010h, 010h, 010h 

	;  char 0x19 
	DB	000h, 000h, 000h, 0F0h, 010h, 010h, 010h, 010h 

	;  char 0x1a 
	DB	010h, 010h, 010h, 01Fh, 000h, 000h, 000h, 000h 

	;  char 0x1b 
	DB	010h, 010h, 010h, 0F0h, 000h, 000h, 000h, 000h 

	;  char 0x1c 
	DB	081h, 042h, 024h, 018h, 018h, 024h, 042h, 081h 

	;  char 0x1d 
	DB	001h, 002h, 004h, 008h, 010h, 020h, 040h, 080h 

	;  char 0x1e 
	DB	080h, 040h, 020h, 010h, 008h, 004h, 002h, 001h 

	;  char 0x1f 
	DB	000h, 010h, 010h, 0FFh, 010h, 010h, 000h, 000h 

	;  char 0x20 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h 

	;  char 0x21 
	DB	020h, 020h, 020h, 020h, 000h, 000h, 020h, 000h 

	;  char 0x22 
	DB	050h, 050h, 050h, 000h, 000h, 000h, 000h, 000h 

	;  char 0x23 
	DB	050h, 050h, 0F8h, 050h, 0F8h, 050h, 050h, 000h 

	;  char 0x24 
	DB	020h, 078h, 0A0h, 070h, 028h, 0F0h, 020h, 000h 

	;  char 0x25 
	DB	0C0h, 0C8h, 010h, 020h, 040h, 098h, 018h, 000h 

	;  char 0x26 
	DB	040h, 0A0h, 040h, 0A8h, 090h, 098h, 060h, 000h 

	;  char 0x27 
	DB	010h, 020h, 040h, 000h, 000h, 000h, 000h, 000h 

	;  char 0x28 
	DB	010h, 020h, 040h, 040h, 040h, 020h, 010h, 000h 

	;  char 0x29 
	DB	040h, 020h, 010h, 010h, 010h, 020h, 040h, 000h 

	;  char 0x2a 
	DB	088h, 050h, 020h, 0F8h, 020h, 050h, 088h, 000h 

	;  char 0x2b 
	DB	000h, 020h, 020h, 0F8h, 020h, 020h, 000h, 000h 

	;  char 0x2c 
	DB	000h, 000h, 000h, 000h, 000h, 020h, 020h, 040h 

	;  char 0x2d 
	DB	000h, 000h, 000h, 078h, 000h, 000h, 000h, 000h 

	;  char 0x2e 
	DB	000h, 000h, 000h, 000h, 000h, 060h, 060h, 000h 

	;  char 0x2f 
	DB	000h, 000h, 008h, 010h, 020h, 040h, 080h, 000h 

	;  char 0x30 
	DB	070h, 088h, 098h, 0A8h, 0C8h, 088h, 070h, 000h 

	;  char 0x31 
	DB	020h, 060h, 0A0h, 020h, 020h, 020h, 0F8h, 000h 

	;  char 0x32 
	DB	070h, 088h, 008h, 010h, 060h, 080h, 0F8h, 000h 

	;  char 0x33 
	DB	070h, 088h, 008h, 030h, 008h, 088h, 070h, 000h 

	;  char 0x34 
	DB	010h, 030h, 050h, 090h, 0F8h, 010h, 010h, 000h 

	;  char 0x35 
	DB	0F8h, 080h, 0E0h, 010h, 008h, 010h, 0E0h, 000h 

	;  char 0x36 
	DB	030h, 040h, 080h, 0F0h, 088h, 088h, 070h, 000h 

	;  char 0x37 
	DB	0F8h, 088h, 010h, 020h, 020h, 020h, 020h, 000h 

	;  char 0x38 
	DB	070h, 088h, 088h, 070h, 088h, 088h, 070h, 000h 

	;  char 0x39 
	DB	070h, 088h, 088h, 078h, 008h, 010h, 060h, 000h 

	;  char 0x3a 
	DB	000h, 000h, 020h, 000h, 000h, 020h, 000h, 000h 

	;  char 0x3b 
	DB	000h, 000h, 020h, 000h, 000h, 020h, 020h, 040h 

	;  char 0x3c 
	DB	018h, 030h, 060h, 0C0h, 060h, 030h, 018h, 000h 

	;  char 0x3d 
	DB	000h, 000h, 0F8h, 000h, 0F8h, 000h, 000h, 000h 

	;  char 0x3e 
	DB	0C0h, 060h, 030h, 018h, 030h, 060h, 0C0h, 000h 

	;  char 0x3f 
	DB	070h, 088h, 008h, 010h, 020h, 000h, 020h, 000h 

	;  char 0x40 
	DB	070h, 088h, 008h, 068h, 0A8h, 0A8h, 070h, 000h 

	;  char 0x41 
	DB	020h, 050h, 088h, 088h, 0F8h, 088h, 088h, 000h 

	;  char 0x42 
	DB	0F0h, 048h, 048h, 070h, 048h, 048h, 0F0h, 000h 

	;  char 0x43 
	DB	030h, 048h, 080h, 080h, 080h, 048h, 030h, 000h 

	;  char 0x44 
	DB	0E0h, 050h, 048h, 048h, 048h, 050h, 0E0h, 000h 

	;  char 0x45 
	DB	0F8h, 080h, 080h, 0F0h, 080h, 080h, 0F8h, 000h 

	;  char 0x46 
	DB	0F8h, 080h, 080h, 0F0h, 080h, 080h, 080h, 000h 

	;  char 0x47 
	DB	070h, 088h, 080h, 0B8h, 088h, 088h, 070h, 000h 

	;  char 0x48 
	DB	088h, 088h, 088h, 0F8h, 088h, 088h, 088h, 000h 

	;  char 0x49 
	DB	070h, 020h, 020h, 020h, 020h, 020h, 070h, 000h 

	;  char 0x4a 
	DB	038h, 010h, 010h, 010h, 090h, 090h, 060h, 000h 

	;  char 0x4b 
	DB	088h, 090h, 0A0h, 0C0h, 0A0h, 090h, 088h, 000h 

	;  char 0x4c 
	DB	080h, 080h, 080h, 080h, 080h, 080h, 0F8h, 000h 

	;  char 0x4d 
	DB	088h, 0D8h, 0A8h, 0A8h, 088h, 088h, 088h, 000h 

	;  char 0x4e 
	DB	088h, 0C8h, 0C8h, 0A8h, 098h, 098h, 088h, 000h 

	;  char 0x4f 
	DB	070h, 088h, 088h, 088h, 088h, 088h, 070h, 000h 

	;  char 0x50 
	DB	0F0h, 088h, 088h, 0F0h, 080h, 080h, 080h, 000h 

	;  char 0x51 
	DB	070h, 088h, 088h, 088h, 0A8h, 090h, 068h, 000h 

	;  char 0x52 
	DB	0F0h, 088h, 088h, 0F0h, 0A0h, 090h, 088h, 000h 

	;  char 0x53 
	DB	070h, 088h, 080h, 070h, 008h, 088h, 070h, 000h 

	;  char 0x54 
	DB	0F8h, 020h, 020h, 020h, 020h, 020h, 020h, 000h 

	;  char 0x55 
	DB	088h, 088h, 088h, 088h, 088h, 088h, 070h, 000h 

	;  char 0x56 
	DB	088h, 088h, 088h, 088h, 050h, 050h, 020h, 000h 

	;  char 0x57 
	DB	088h, 088h, 088h, 0A8h, 0A8h, 0D8h, 088h, 000h 

	;  char 0x58 
	DB	088h, 088h, 050h, 020h, 050h, 088h, 088h, 000h 

	;  char 0x59 
	DB	088h, 088h, 088h, 070h, 020h, 020h, 020h, 000h 

	;  char 0x5a 
	DB	0F8h, 008h, 010h, 020h, 040h, 080h, 0F8h, 000h 

	;  char 0x5b 
	DB	070h, 040h, 040h, 040h, 040h, 040h, 070h, 000h 

	;  char 0x5c 
	DB	000h, 000h, 080h, 040h, 020h, 010h, 008h, 000h 

	;  char 0x5d 
	DB	070h, 010h, 010h, 010h, 010h, 010h, 070h, 000h 

	;  char 0x5e 
	DB	020h, 050h, 088h, 000h, 000h, 000h, 000h, 000h 

	;  char 0x5f 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 0F8h, 000h 

	;  char 0x60 
	DB	040h, 020h, 010h, 000h, 000h, 000h, 000h, 000h 

	;  char 0x61 
	DB	000h, 000h, 070h, 008h, 078h, 088h, 078h, 000h 

	;  char 0x62 
	DB	080h, 080h, 0B0h, 0C8h, 088h, 0C8h, 0B0h, 000h 

	;  char 0x63 
	DB	000h, 000h, 070h, 088h, 080h, 088h, 070h, 000h 

	;  char 0x64 
	DB	008h, 008h, 068h, 098h, 088h, 098h, 068h, 000h 

	;  char 0x65 
	DB	000h, 000h, 070h, 088h, 0F8h, 080h, 070h, 000h 

	;  char 0x66 
	DB	010h, 028h, 020h, 0F8h, 020h, 020h, 020h, 000h 

	;  char 0x67 
	DB	000h, 000h, 068h, 098h, 098h, 068h, 008h, 070h 

	;  char 0x68 
	DB	080h, 080h, 0F0h, 088h, 088h, 088h, 088h, 000h 

	;  char 0x69 
	DB	020h, 000h, 060h, 020h, 020h, 020h, 070h, 000h 

	;  char 0x6a 
	DB	010h, 000h, 030h, 010h, 010h, 010h, 090h, 060h 

	;  char 0x6b 
	DB	040h, 040h, 048h, 050h, 060h, 050h, 048h, 000h 

	;  char 0x6c 
	DB	060h, 020h, 020h, 020h, 020h, 020h, 070h, 000h 

	;  char 0x6d 
	DB	000h, 000h, 0D0h, 0A8h, 0A8h, 0A8h, 0A8h, 000h 

	;  char 0x6e 
	DB	000h, 000h, 0B0h, 0C8h, 088h, 088h, 088h, 000h 

	;  char 0x6f 
	DB	000h, 000h, 070h, 088h, 088h, 088h, 070h, 000h 

	;  char 0x70 
	DB	000h, 000h, 0B0h, 0C8h, 0C8h, 0B0h, 080h, 080h 

	;  char 0x71 
	DB	000h, 000h, 068h, 098h, 098h, 068h, 008h, 008h 

	;  char 0x72 
	DB	000h, 000h, 0B0h, 0C8h, 080h, 080h, 080h, 000h 

	;  char 0x73 
	DB	000h, 000h, 078h, 080h, 0F0h, 008h, 0F0h, 000h 

	;  char 0x74 
	DB	040h, 040h, 0F0h, 040h, 040h, 048h, 030h, 000h 

	;  char 0x75 
	DB	000h, 000h, 090h, 090h, 090h, 090h, 068h, 000h 

	;  char 0x76 
	DB	000h, 000h, 088h, 088h, 088h, 050h, 020h, 000h 

	;  char 0x77 
	DB	000h, 000h, 088h, 0A8h, 0A8h, 0A8h, 050h, 000h 

	;  char 0x78 
	DB	000h, 000h, 088h, 050h, 020h, 050h, 088h, 000h 

	;  char 0x79 
	DB	000h, 000h, 088h, 088h, 098h, 068h, 008h, 070h 

	;  char 0x7a 
	DB	000h, 000h, 0F8h, 010h, 020h, 040h, 0F8h, 000h 

	;  char 0x7b 
	DB	018h, 020h, 020h, 040h, 020h, 020h, 018h, 000h 

	;  char 0x7c 
	DB	020h, 020h, 020h, 000h, 020h, 020h, 020h, 000h 

	;  char 0x7d 
	DB	0C0h, 020h, 020h, 010h, 020h, 020h, 0C0h, 000h 

	;  char 0x7e 
	DB	040h, 0A8h, 010h, 000h, 000h, 000h, 000h, 000h 

	;  char 0x7f 
	DB	000h, 000h, 020h, 050h, 0F8h, 000h, 000h, 000h 

	;  char 0x80 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 0FFh 

	;  char 0x81 
	DB	0F0h, 0F0h, 0F0h, 0F0h, 00Fh, 00Fh, 00Fh, 00Fh 

	;  char 0x82 
	DB	000h, 000h, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh 

	;  char 0x83 
	DB	0FFh, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h 

	;  char 0x84 
	DB	000h, 000h, 000h, 03Ch, 03Ch, 000h, 000h, 000h 

	;  char 0x85 
	DB	0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 000h, 000h 

	;  char 0x86 
	DB	0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h 

	;  char 0x87 
	DB	00Fh, 00Fh, 00Fh, 00Fh, 0F0h, 0F0h, 0F0h, 0F0h 

	;  char 0x88 
	DB	0FCh, 0FCh, 0FCh, 0FCh, 0FCh, 0FCh, 0FCh, 0FCh 

	;  char 0x89 
	DB	003h, 003h, 003h, 003h, 003h, 003h, 003h, 003h 

	;  char 0x8a 
	DB	03Fh, 03Fh, 03Fh, 03Fh, 03Fh, 03Fh, 03Fh, 03Fh 

	;  char 0x8b 
	DB	011h, 022h, 044h, 088h, 011h, 022h, 044h, 088h 

	;  char 0x8c 
	DB	088h, 044h, 022h, 011h, 088h, 044h, 022h, 011h 

	;  char 0x8d 
	DB	0FEh, 07Ch, 038h, 010h, 000h, 000h, 000h, 000h 

	;  char 0x8e 
	DB	000h, 000h, 000h, 000h, 010h, 038h, 07Ch, 0FEh 

	;  char 0x8f 
	DB	080h, 0C0h, 0E0h, 0F0h, 0E0h, 0C0h, 080h, 000h 

	;  char 0x90 
	DB	001h, 003h, 007h, 00Fh, 007h, 003h, 001h, 000h 

	;  char 0x91 
	DB	0FFh, 07Eh, 03Ch, 018h, 018h, 03Ch, 07Eh, 0FFh 

	;  char 0x92 
	DB	081h, 0C3h, 0E7h, 0FFh, 0FFh, 0E7h, 0C3h, 081h 

	;  char 0x93 
	DB	0F0h, 0F0h, 0F0h, 0F0h, 000h, 000h, 000h, 000h 

	;  char 0x94 
	DB	000h, 000h, 000h, 000h, 00Fh, 00Fh, 00Fh, 00Fh 

	;  char 0x95 
	DB	00Fh, 00Fh, 00Fh, 00Fh, 000h, 000h, 000h, 000h 

	;  char 0x96 
	DB	000h, 000h, 000h, 000h, 0F0h, 0F0h, 0F0h, 0F0h 

	;  char 0x97 
	DB	033h, 033h, 0CCh, 0CCh, 033h, 033h, 0CCh, 0CCh 

	;  char 0x98 
	DB	000h, 020h, 020h, 050h, 050h, 088h, 0F8h, 000h 

	;  char 0x99 
	DB	020h, 020h, 070h, 020h, 070h, 020h, 020h, 000h 

	;  char 0x9a 
	DB	000h, 000h, 000h, 050h, 088h, 0A8h, 050h, 000h 

	;  char 0x9b 
	DB	0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh 

	;  char 0x9c 
	DB	000h, 000h, 000h, 000h, 0FFh, 0FFh, 0FFh, 0FFh 

	;  char 0x9d 
	DB	0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h 

	;  char 0x9e 
	DB	00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh 

	;  char 0x9f 
	DB	0FFh, 0FFh, 0FFh, 0FFh, 000h, 000h, 000h, 000h 

	;  char 0xa0 
	DB	000h, 000h, 068h, 090h, 090h, 090h, 068h, 000h 

	;  char 0xa1 
	DB	030h, 048h, 048h, 070h, 048h, 048h, 070h, 0C0h 

	;  char 0xa2 
	DB	0F8h, 088h, 080h, 080h, 080h, 080h, 080h, 000h 

	;  char 0xa3 
	DB	0F8h, 050h, 050h, 050h, 050h, 050h, 098h, 000h 

	;  char 0xa4 
	DB	0F8h, 088h, 040h, 020h, 040h, 088h, 0F8h, 000h 

	;  char 0xa5 
	DB	000h, 000h, 078h, 090h, 090h, 090h, 060h, 000h 

	;  char 0xa6 
	DB	000h, 050h, 050h, 050h, 050h, 068h, 080h, 080h 

	;  char 0xa7 
	DB	000h, 050h, 0A0h, 020h, 020h, 020h, 020h, 000h 

	;  char 0xa8 
	DB	0F8h, 020h, 070h, 0A8h, 0A8h, 070h, 020h, 0F8h 

	;  char 0xa9 
	DB	020h, 050h, 088h, 0F8h, 088h, 050h, 020h, 000h 

	;  char 0xaa 
	DB	070h, 088h, 088h, 088h, 050h, 050h, 0D8h, 000h 

	;  char 0xab 
	DB	030h, 040h, 040h, 020h, 050h, 050h, 050h, 020h 

	;  char 0xac 
	DB	000h, 000h, 000h, 050h, 0A8h, 0A8h, 050h, 000h 

	;  char 0xad 
	DB	008h, 070h, 0A8h, 0A8h, 0A8h, 070h, 080h, 000h 

	;  char 0xae 
	DB	038h, 040h, 080h, 0F8h, 080h, 040h, 038h, 000h 

	;  char 0xaf 
	DB	070h, 088h, 088h, 088h, 088h, 088h, 088h, 000h 

	;  char 0xb0 
	DB	000h, 0F8h, 000h, 0F8h, 000h, 0F8h, 000h, 000h 

	;  char 0xb1 
	DB	020h, 020h, 0F8h, 020h, 020h, 000h, 0F8h, 000h 

	;  char 0xb2 
	DB	0C0h, 030h, 008h, 030h, 0C0h, 000h, 0F8h, 000h 

	;  char 0xb3 
	DB	018h, 060h, 080h, 060h, 018h, 000h, 0F8h, 000h 

	;  char 0xb4 
	DB	010h, 028h, 020h, 020h, 020h, 020h, 020h, 020h 

	;  char 0xb5 
	DB	020h, 020h, 020h, 020h, 020h, 020h, 0A0h, 040h 

	;  char 0xb6 
	DB	000h, 020h, 000h, 0F8h, 000h, 020h, 000h, 000h 

	;  char 0xb7 
	DB	000h, 050h, 0A0h, 000h, 050h, 0A0h, 000h, 000h 

	;  char 0xb8 
	DB	000h, 018h, 024h, 024h, 018h, 000h, 000h, 000h 

	;  char 0xb9 
	DB	000h, 030h, 078h, 078h, 030h, 000h, 000h, 000h 

	;  char 0xba 
	DB	000h, 000h, 000h, 000h, 030h, 000h, 000h, 000h 

	;  char 0xbb 
	DB	03Eh, 020h, 020h, 020h, 0A0h, 060h, 020h, 000h 

	;  char 0xbc 
	DB	0A0h, 050h, 050h, 050h, 000h, 000h, 000h, 000h 

	;  char 0xbd 
	DB	040h, 0A0h, 020h, 040h, 0E0h, 000h, 000h, 000h 

	;  char 0xbe 
	DB	000h, 038h, 038h, 038h, 038h, 038h, 038h, 000h 

	;  char 0xbf 
	DB	088h, 070h, 088h, 088h, 070h, 088h, 000h, 000h 

	;  char 0xc0 
	DB	000h, 000h, 090h, 0A8h, 0E8h, 0A8h, 090h, 000h 

	;  char 0xc1 
	DB	000h, 000h, 060h, 010h, 070h, 090h, 068h, 000h 

	;  char 0xc2 
	DB	000h, 000h, 0F0h, 080h, 0F0h, 088h, 0F0h, 000h 

	;  char 0xc3 
	DB	000h, 000h, 090h, 090h, 090h, 0F8h, 008h, 000h 

	;  char 0xc4 
	DB	000h, 000h, 030h, 050h, 050h, 070h, 088h, 000h 

	;  char 0xc5 
	DB	000h, 000h, 070h, 088h, 0F8h, 080h, 070h, 000h 

	;  char 0xc6 
	DB	000h, 020h, 070h, 0A8h, 0A8h, 070h, 020h, 000h 

	;  char 0xc7 
	DB	000h, 000h, 078h, 048h, 040h, 040h, 040h, 000h 

	;  char 0xc8 
	DB	000h, 000h, 088h, 050h, 020h, 050h, 088h, 000h 

	;  char 0xc9 
	DB	000h, 000h, 088h, 098h, 0A8h, 0C8h, 088h, 000h 

	;  char 0xca 
	DB	000h, 050h, 020h, 000h, 098h, 0A8h, 0C8h, 000h 

	;  char 0xcb 
	DB	000h, 000h, 090h, 0A0h, 0C0h, 0A0h, 090h, 000h 

	;  char 0xcc 
	DB	000h, 000h, 038h, 028h, 028h, 048h, 088h, 000h 

	;  char 0xcd 
	DB	000h, 000h, 088h, 0D8h, 0A8h, 088h, 088h, 000h 

	;  char 0xce 
	DB	000h, 000h, 088h, 088h, 0F8h, 088h, 088h, 000h 

	;  char 0xcf 
	DB	000h, 000h, 070h, 088h, 088h, 088h, 070h, 000h 

	;  char 0xd0 
	DB	000h, 000h, 078h, 048h, 048h, 048h, 048h, 000h 

	;  char 0xd1 
	DB	000h, 000h, 078h, 088h, 078h, 028h, 048h, 000h 

	;  char 0xd2 
	DB	000h, 000h, 0F0h, 088h, 0F0h, 080h, 080h, 000h 

	;  char 0xd3 
	DB	000h, 000h, 078h, 080h, 080h, 080h, 078h, 000h 

	;  char 0xd4 
	DB	000h, 000h, 0F8h, 020h, 020h, 020h, 020h, 000h 

	;  char 0xd5 
	DB	000h, 000h, 088h, 050h, 020h, 040h, 080h, 000h 

	;  char 0xd6 
	DB	000h, 000h, 0A8h, 070h, 020h, 070h, 0A8h, 000h 

	;  char 0xd7 
	DB	000h, 000h, 0F0h, 048h, 070h, 048h, 0F0h, 000h 

	;  char 0xd8 
	DB	000h, 000h, 040h, 040h, 070h, 048h, 070h, 000h 

	;  char 0xd9 
	DB	000h, 000h, 088h, 088h, 0C8h, 0A8h, 0C8h, 000h 

	;  char 0xda 
	DB	000h, 000h, 0F0h, 008h, 070h, 008h, 0F0h, 000h 

	;  char 0xdb 
	DB	000h, 000h, 0A8h, 0A8h, 0A8h, 0A8h, 0F8h, 000h 

	;  char 0xdc 
	DB	000h, 000h, 070h, 088h, 038h, 088h, 070h, 000h 

	;  char 0xdd 
	DB	000h, 000h, 0A8h, 0A8h, 0A8h, 0F8h, 008h, 000h 

	;  char 0xde 
	DB	000h, 000h, 048h, 048h, 078h, 008h, 008h, 000h 

	;  char 0xdf 
	DB	000h, 000h, 0C0h, 040h, 070h, 048h, 070h, 000h 

	;  char 0xe0 
	DB	090h, 0A8h, 0A8h, 0E8h, 0A8h, 0A8h, 090h, 000h 

	;  char 0xe1 
	DB	020h, 050h, 088h, 088h, 0F8h, 088h, 088h, 000h 

	;  char 0xe2 
	DB	0F8h, 088h, 080h, 0F0h, 088h, 088h, 0F0h, 000h 

	;  char 0xe3 
	DB	090h, 090h, 090h, 090h, 090h, 0F8h, 008h, 000h 

	;  char 0xe4 
	DB	038h, 028h, 028h, 048h, 048h, 0F8h, 088h, 000h 

	;  char 0xe5 
	DB	0F8h, 080h, 080h, 0F0h, 080h, 080h, 0F8h, 000h 

	;  char 0xe6 
	DB	020h, 070h, 0A8h, 0A8h, 0A8h, 070h, 020h, 000h 

	;  char 0xe7 
	DB	0F8h, 088h, 088h, 080h, 080h, 080h, 080h, 000h 

	;  char 0xe8 
	DB	088h, 088h, 050h, 020h, 050h, 088h, 088h, 000h 

	;  char 0xe9 
	DB	088h, 088h, 098h, 0A8h, 0C8h, 088h, 088h, 000h 

	;  char 0xea 
	DB	050h, 020h, 088h, 098h, 0A8h, 0C8h, 088h, 000h 

	;  char 0xeb 
	DB	088h, 090h, 0A0h, 0C0h, 0A0h, 090h, 088h, 000h 

	;  char 0xec 
	DB	018h, 028h, 048h, 048h, 048h, 048h, 088h, 000h 

	;  char 0xed 
	DB	088h, 0D8h, 0A8h, 0A8h, 088h, 088h, 088h, 000h 

	;  char 0xee 
	DB	088h, 088h, 088h, 0F8h, 088h, 088h, 088h, 000h 

	;  char 0xef 
	DB	070h, 088h, 088h, 088h, 088h, 088h, 070h, 000h 

	;  char 0xf0 
	DB	0F8h, 088h, 088h, 088h, 088h, 088h, 088h, 000h 

	;  char 0xf1 
	DB	078h, 088h, 088h, 078h, 028h, 048h, 088h, 000h 

	;  char 0xf2 
	DB	0F0h, 088h, 088h, 0F0h, 080h, 080h, 080h, 000h 

	;  char 0xf3 
	DB	070h, 088h, 080h, 080h, 080h, 088h, 070h, 000h 

	;  char 0xf4 
	DB	0F8h, 020h, 020h, 020h, 020h, 020h, 020h, 000h 

	;  char 0xf5 
	DB	088h, 088h, 088h, 050h, 020h, 040h, 080h, 000h 

	;  char 0xf6 
	DB	0A8h, 0A8h, 070h, 020h, 070h, 0A8h, 0A8h, 000h 

	;  char 0xf7 
	DB	0F0h, 048h, 048h, 070h, 048h, 048h, 0F0h, 000h 

	;  char 0xf8 
	DB	080h, 080h, 080h, 0F0h, 088h, 088h, 0F0h, 000h 

	;  char 0xf9 
	DB	088h, 088h, 088h, 0C8h, 0A8h, 0A8h, 0C8h, 000h 

	;  char 0xfa 
	DB	0F0h, 008h, 008h, 030h, 008h, 008h, 0F0h, 000h 

	;  char 0xfb 
	DB	0A8h, 0A8h, 0A8h, 0A8h, 0A8h, 0A8h, 0F8h, 000h 

	;  char 0xfc 
	DB	070h, 088h, 008h, 078h, 008h, 088h, 070h, 000h 

	;  char 0xfd 
	DB	0A8h, 0A8h, 0A8h, 0A8h, 0A8h, 0F8h, 008h, 000h 

	;  char 0xfe 
	DB	088h, 088h, 088h, 088h, 078h, 008h, 008h, 000h 

	;  char 0xff 
	DB	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h 

tmsFont8End: 
 
 
        end 
