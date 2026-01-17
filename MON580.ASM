;.xlist

; МОНИТОР РК "Северная Пальмира" v. 1.1
; Основан на Мониторе РК86 для КР580 совместимый с Z80 В. Чистякова

	.Z80
	aseg
	ORG     100H
VDP		EQU	98H
VDP_TEXT_SCROLL	EQU	1
USE_DMA		EQU	1
;MSX		EQU	1
;INT_ENABLE	EQU	1
;RAM		EQU	1
IFDEF	RAM
ORGB		EQU	08000H
ELSE
ORGB		EQU	0E000H
ENDIF

	BASE    EQU	0D700H		; служебные ячейки
	BASE_W	EQU	BASE-100h
IFNDEF VDP
	SA48	EQU	0B6D0H		; 76D0 начало экранной области в режиме 48K
	SA32	EQU	076D0H		; 76D0 начало экранной области в режиме 32K
	SA16	EQU	036D0H		; 36D0 начало экранной области в режиме 16K
ELSE
	SA48	EQU	0		; 0 начало экранной области в режиме 48K
	SA32	EQU	0		; 0 начало экранной области в режиме 32K
	SA16	EQU	0		; 0 начало экранной области в режиме 16K
ENDIF
	KBDPPA	EQU     0C200H
	DOPPPA	EQU	0C400H

	SDBUF	EQU	0D400H		; буфер обмена с SD-адаптером

	SIGVAL	EQU	55AAH


RABADR	EQU	ORGB+1800H

T9918_MOD_ORG	EQU	ORGB+103H
MON_MOD_ORG	EQU	ORGB+0A40H
SD_MOD_ORG	EQU	ORGB+15D0h

;SD_LDR	EQU	ORGB+1006H
DEBUG	EQU	ORGB+1009H

VG_75   EQU	0C000H
TM9	EQU	0CE00H
VT_57   EQU	0C600H
VI_53	EQU	0CC00H

SG	EQU	0D800H

K_ORIG	EQU	0		; если не 0, то оригинальный курсор

EK_ADR	EQU	BASE		; текущий адрес на экране
POSX	EQU	BASE+02H
POSY	EQU	BASE+03H
ESC_F	EQU	BASE+04H
KBDFLG	EQU	BASE+05H 	; если =0, то есть символ в SYMBUF
RUSLAT  EQU	BASE+06H	; допустимо только 0 или FF
LAST_K	EQU	BASE+09H	; эти 2 байта должны следовать подряд
COUNT	EQU	BASE+0AH	; счётчик опросов (вначале 15)
APVFLG	EQU	BASE+0BH	; флаг автоповтора
FRELOC	EQU	BASE+0CH	; эта ячейка не используется

TMPSTK  EQU	BASE+0DH	; временно храним стек при МГ п/п-ммах
CURSYM	EQU	BASE+10H
SYMADR	EQU	BASE+11H
POINT	EQU	BASE+14H	; адрес откуда произошёл RST_30H
R_HL	EQU	BASE+16H
R_BC	EQU	BASE+18H
R_SP	EQU	BASE+1CH
R_AF	EQU	BASE+1EH	; ниже откладываются AF,HL,DE,BC
STOP_A  EQU	BASE+23H
TMP_COD EQU	BASE+25H
P_JMP	EQU	BASE+26H        ; для байта C3H (JMP)
PAR_HL	EQU	BASE+27H
PAR_DE	EQU	BASE+29H
PAR_BC	EQU	BASE+2BH
FLG_P2	EQU	BASE+2DH	; флаг, что есть параметры 2 или 2,3
INV_MG	EQU	BASE+2EH
KNS_RD	EQU	BASE+2FH
KNS_WR	EQU	BASE+30H
RAMTOP	EQU	BASE+31H

SDB_JP	EQU	BASE+33H	; jmp в SD BIOS
SD_ENTR	EQU	BASE+34H	; точка входа в SD BIOS
SH_ENTR	EQU	BASE+36H	; точка запуска Shell
SD_ERR	EQU	BASE+38H	; код ошибки SD-контроллера либо 0

WRB_JP	EQU	BASE+39H
WRB_ADR	EQU	BASE+3AH
RDB_JP	EQU	BASE+3CH
RDB_ADR	EQU	BASE+3DH

SDBUFA	EQU	BASE+3FH	; текущий адрес (чтения/записи) в буфере магнитофона
SDBEND	EQU	BASE+41H	; для чтения: последний адрес данных буфере магнитофона
SDBLFT	EQU	BASE+43H	; 0, если в буфере чтения нет даных (файл весь прочитан)
EMU_MD	EQU	BASE+44H	; текущий режим эмулятора (0 - неакт., 1 - запись, 2 - чтение)
EMUCNL	EQU	BASE+45H	; признак ошибки или отмены операции эмуляции манитофона

; protected data
MODE	EQU	BASE+50H	; текущий режим (0-48K, 1-32K, 2-16K)
TM9VAL	EQU	BASE+51H	; текущее значение байта расширения конфигурации
SCRBEG	EQU	BASE+52H	; текущее начало экранной области (76D0/B6D0)
TEMU	EQU	BASE+54H	; текущий ражим эмуляции магнитофона
SIG	EQU	BASE+55H
; end of protected data, checksum:
CHSUM	EQU	BASE+57H

FLDR	EQU	BASE+6BH	; имя папки 'TAPE/'
COMBUF	EQU	BASE+70H        ; буфер ввода директивы

STACK	EQU	BASE;+100H	; стек монитора


PORT_A		EQU	KBDPPA
PORT_B		EQU	PORT_A+1
PORT_C		EQU	PORT_A+2
PORT_CTRL	EQU	PORT_A+3

PORT2_A		EQU	DOPPPA
PORT2_B		EQU	PORT2_A+1
PORT2_C		EQU	PORT2_A+2
PORT2_CTRL	EQU	PORT2_A+3


IFNDEF	VDP
SCR_WIDTH	EQU	78
SCR_VIS_WIDTH	EQU	64
SCR_XOFS	EQU	8
SCR_HEIGHT	EQU	25
SCR_YOFS	EQU	3
ELSE
SCR_WIDTH	EQU	80
SCR_VIS_WIDTH	EQU	80
SCR_XOFS	EQU	0
SCR_HEIGHT	EQU	30;24
SCR_YOFS	EQU	0
STRBUF		EQU	BASE+90h
ENDIF
; ??????????????????????????????????????????????

LOOP	MACRO	ADDR
	DEC	BC
	LD	A,B
	OR	C
	JP	NZ,ADDR
	ENDM

; ??????????????????????????????????????????????

	include init2R.asm
;*******************************************************************************
	.Z80
IF 0
	rept	200H
	if	$ ne T9918_MOD_ORG
		defb	255
	endif
	endm
ENDIF
;*******************************************************************************
NXT_S:	PUSH	BC
	LD	BC,SCR_WIDTH
	ADD	HL,BC
	POP	BC
	RET

T_ShAddrReadBytes:
	PUSH	HL
	PUSH	BC
	EX	DE,HL
	CALL	T_SetAddrReadHL
	EX	DE,HL
T_ShortReadBytes:
	IN	A,(VDP)
	LD	(HL),A
	INC	HL
	DEC	B
	JP	NZ, T_ShortReadBytes
	POP	BC
	POP	HL
	RET

T_ShAddrWriteBytes:
	PUSH	BC
	LD	B,D
	LD	C,E
	CALL	T_SetAddrWrite
	POP	BC

T_ShortWriteBytes:
	LD	A,(HL)
	OUT	(VDP), A
	INC	HL
	DEC	B
	JP	NZ, T_ShortWriteBytes
	RET

ReadHLEk:
	LD	HL,(EK_ADR)
ReadHL:
	CALL	T_SetAddrReadHL
	IN	A,(VDP)
	RET

T_SetAddrReadHL:
	DI
	LD	A,L
	OUT	(VDP+1),A
	LD	A,H
	OUT	(VDP+1),A
IFDEF INT_ENABLE
	EI
ENDIF
	RET

CursorSet:
	PUSH	BC
	PUSH	HL
	LD	B,H
	LD	C,L
	LD	HL,(SYMADR)
	PUSH	DE
	EX	DE,HL
	LD	HL,(EK_ADR)
	EX	DE,HL
	DEC	BC
	LD	A,C
	CP	E
	JP	NZ, WRH01
	LD	A,B
	CP	D
	JP	NZ, WRH01
WRH03:
	LD	A,E
	CP	L
	JP	NZ,WRH01
	LD	A,D
	CP	H
	JP	Z,WRH02
WRH01:
	LD	A,(CURSYM)
	CALL	WriteHL2
WRH02:
	POP	DE
	POP	HL
	POP	BC
	CALL	ReadHL
	LD	(CURSYM),A
	LD	A, 255 ; Cursor
	LD	(SYMADR),HL
WriteHL2:
	PUSH	AF
	DI
	LD	A,L
	OUT	(VDP+1),A
	LD	A,H
	OR	40h
	OUT	(VDP+1),A
IFDEF INT_ENABLE
	EI
ENDIF
	POP	AF
	OUT	(VDP),A
	RET
WriteHLMoveRight:
	DI
	LD	A,L
	OUT	(VDP+1),A
	LD	A,H
	OR	40h
	OUT	(VDP+1),A
IFDEF INT_ENABLE
	EI
ENDIF
	LD	A,C
	OUT	(VDP),A
IFNDEF	MSX
	LD	A,0F4h
	OUT	(VDP),A
ENDIF
	JP	COD_18


T_SetAddrWrite:
	LD	A,B
	OR	40h
	LD	B,A
T_SetAddrRead:
	DI
	LD	A,C
	OUT	(VDP+1),A
	LD	A,B
	OUT	(VDP+1),A
IFDEF INT_ENABLE
	EI
ENDIF
	RET
T_FillHL:
	PUSH	BC
	LD	B,H
	LD	C,L
	LD	E,A
	CALL	T_SetAddrWrite
	POP	BC
	JP	@loop40

T_FillWord:
	PUSH	BC
	LD	B,H
	LD	C,L
	CALL	T_SetAddrWrite
	POP	BC
TFW01:
	LD	A,D
	OUT	(VDP),A
	LD	A,E
	OUT	(VDP),A
	DEC	BC
	LD	A,B
	OR	C
	JP	NZ, TFW01
	RET

	include TMS_DEF.ASM

; reset registers and clear all 16KB of video memory
T_Reset:
	; blank the screen with 16KB enabled
	LD	B, T_REG_1
	LD	C, T_R1_RAM_16K
	CALL	T_WriteRegValue

	LD	B, T_REG_0
	LD	C, 0
	CALL	T_WriteRegValue

	LD	B, T_REG_FG_BG_COLOR
	LD	C, T_TRANSPARENT OR (T_TRANSPARENT SHL 4)
	CALL	T_WriteRegValue

	LD	DE, 0			; clear entire VRAM
	LD	BC, 4000h
	XOR	A
	;JMP	T_Fill ; fallthrough

T_Fill:
	PUSH	BC
	LD	B,D
	LD	C,E
	LD	E,A
	CALL	T_SetAddrWrite
	POP	BC
@loop40:
	LD	A,E
	OUT	(VDP),A
	DEC	BC
	LD	A,B
	OR	C
	JP	NZ, @loop40
	RET
T_FillSh:
	PUSH	BC
	LD	B,D
	LD	C,E
	LD	E,A
	CALL	T_SetAddrWrite
	POP	BC
	LD	A,E
FSH01:
	OUT	(VDP),A
	DEC	B
	JP	NZ, FSH01
	RET

T_WriteBytes:
	LD	A,(HL)
	OUT	(VDP),A
	INC	HL
	DEC	DE
	LD	A,D
	OR	E
	JP	NZ,T_WriteBytes
	RET

; C - value
; B - reg
T_WriteRegValue:
	;CALL	T_WriteAddr
	LD	A,C
	DI
	OUT	(VDP+1),A
	LD	A,B
	OR	80H
IFDEF INT_ENABLE
	EI
ENDIF
	OUT	(VDP+1),A
	RET

SetVDP:
	PUSH	DE
	PUSH	BC
	;CALL	T_Reset
	;CALL	CLS
	CALL	T_InitialiseText80
	;LD	HL,VG_75+1
	POP	BC
	POP	DE
	RET

T_InitialiseText80:
	;CALL	T_Reset
	PUSH	AF


	; non-bitmap color and pattern table configuration
	LD	HL,InitTbl11
	CALL	T_SetRegs

	LD	BC, T_T80_VRAM_PATT_ADDRESS ; load font from address in bc
	CALL	T_SetAddrWrite

	POP	AF
	;CP	80H
	;JP	Z,font16
	;LD	HL, tmsFont8
	;LD	DE, tmsFont8End - tmsFont8
	;CALL	T_WriteBytes

font16:
	LD	HL, tmsFont
	LD	DE, tmsFontEnd - tmsFont ; tmsFontBytes
	CALL	T_WriteBytes

IFNDEF	MSX
	LD	HL, T_T80_VRAM_PATT_ADDRESS + 255*16
	LD	A,255
	LD	BC,16
	CALL	T_FillHL
ELSE
	LD	HL, T_T80_VRAM_PATT_ADDRESS + 255*8
	LD	A,255
	LD	BC,8
	CALL	T_FillHL
ENDIF
	LD	HL, InitTbl12

T_SetRegs:
	LD	B,(HL)
	INC	B
	RET	Z
	DEC	B
	INC	HL
	LD	C,(HL)
	INC	HL
	CALL	T_WriteRegValue
	JP	T_SetRegs

InitTbl11:
	DB	39h, 1Ch 
	DB	39h, 1Ch 
	DB	T_REG_COLOR_TABLE,	T_T80_VRAM_COLOR_ADDRESS / 40h
	DB	T_REG_PATTERN_TABLE,	T_T80_VRAM_PATT_ADDRESS / 800h
	DB	T_REG_NAME_TABLE,	LOW ( (T_T80_VRAM_NAME_ADDRESS / 400h) AND 0fh);7Ch OR 3
	DB	T_REG_SPRITE_ATTR_TABLE, 20H
	db	T_REG_SPRITE_PATT_TABLE, 2
	DB	33h, 0
	DB	0FFh

InitTbl12:
IFDEF	MSX
	DB	T_REG_0,		T_R0_EXT_VDP_DISABLE OR T_R0_MODE_TEXT80; OR T_R0_MODE_TEXT8_80
	DB	T_REG_1,		T_R1_MODE_TEXT OR T_R1_RAM_16K; OR T_R1_INT_ENABLE
	DB	31h,			40h ; // set 30 row mode
	DB	32h,			2   ; // set Position-based tile attributes
ELSE
	DB	T_REG_0,		T_R0_EXT_VDP_DISABLE OR T_R0_MODE_TEXT80 OR T_R0_MODE_TEXT8_80
	DB	T_REG_1,		T_R1_MODE_TEXT OR T_R1_DISP_ACTIVE OR T_R1_INTERLEAVE_COLOR
ENDIF
	DB	T_REG_FG_BG_COLOR,	T_DK_BLUE OR (T_WHITE SHL 4)
	;DB	36h, 3fh
	;DB	37h, 0
	DB	0FFh

tmsFont:
IFDEF MSX
	include fMsx.ASM
ELSE
	include F8X16.ASM
	;include F8X16EN.ASM
ENDIF
tmsFontEnd:
	;rept	0E00H
	;if	(LOW($) MOD 16 ne 0)
	;	defb	255
	;endif
	;endm

	;.dephase
	.8080
	include MonRkRom.asm
	include sdbiosR.asm
	.z80
	rept	0400H
	if	$ ne ORGB+1000H
		defb	255
	endif
	endm
	.dephase
; ??????????????????????????????????????????????

	.phase  ORGB+1000H

	JP	ORGB+1800h
	JP	SYSCALL
SD_LDR:
	JP	SD_LDR2;SD_MOD_ORG
	JP	START_CODE;ORGB+0CB0h

	rept	6
	NOP
	endm

SD_LDR2:
	XOR	A
	RET
; ??????????????????????????????????????????????

PRMPT:
	CALL	RST_18
	defb	13,10+128
	LD	A,(MODE)
	OR	A
	LD	HL,PR48
	JP	Z,PRM1
	DEC	A
	LD	HL,PR32
	JP	Z,PRM1
	DEC	A
	LD	HL,PR16
	JP	Z,PRM1
	LD	HL,PRX
PRM1:	CALL	MSGH
	LD	A,(TM9VAL)
	AND	01H
	JP	Z,PRM2
	CALL	RST_18
	defb	'A' or 80H
PRM2:	LD	A,(TEMU)
	OR	A
	JP	Z,PRM3
	CALL	RST_18
	defb	'E' or 80H
PRM3:	CALL	RST_18
	defb	'>' or 80H
	RET

PR48:	defb	'.48',0
PR32:	defb	'.32',0
PR16:	defb	'.16',0
PRX:	defb	'.??',0

; ??????????????????????????????????????????????

CHK_KBD_CS:
	LD	A,(PORT_C)
	AND	0E0H
	CP	0E0H
	JP	NZ,MDINIT ; перезагрузка с СС/УС

CHK_CS:
	LD	HL,(SIG)
	LD	A,H
	CP	55H
	JP	NZ,MDINIT
	CPL
	XOR	L
	JP	NZ,MDINIT
	LD	HL,MODE
	LD	DE,CHSUM-1
	CALL	CHSUMM
	LD	HL,(CHSUM)
	LD	A,B
	CP	H
	JP	NZ,MDINIT
	LD	A,C
	CP	L
	RET	Z
MDINIT:	LD	A,80H
	LD	(TM9VAL),A
	XOR	A
	LD	(MODE),A
	LD	(TEMU),A
	LD	HL,SIGVAL
	LD	(SIG),HL
	LD	HL,SA48
	LD	(SCRBEG),HL
CALC_CS:	
	LD	HL,MODE
	LD	DE,CHSUM-1
	CALL	CHSUMM
	LD	H,B
	LD	L,C
	LD	(CHSUM),HL
	RET

SETTM9:
	LD	A,(TM9VAL)
	LD	(TM9),A
	RET

DIR_N:
	CALL	TRY_SD
	OR	A
	RET	NZ
	;EX	DE,HL
	;JP	(HL)
	JP	SdBiosEntry;Boot2

TRY_SD:
	CALL	SD_INIT
	OR	A
	CALL	NZ,SDERR
	RET

SD_INIT:
	JP	SI4
IF 0
	LD	HL,7EH
	LD	(PORT2_B),HL
	LD	BC,300H
SI2:	LD	A,(PORT2_A)
	CP	55H
	JP	Z,SI1
	DEC	BC
	LD	A,B
	OR	C
	JP	NZ,SI2
	LD	A,0FEH
	JP	SI3
SI1:	INC	L
	LD	(PORT2_B),HL
	LD	A,(PORT2_A)	
	CP	0AAH
	JP	Z,SI4
	LD	A,0FEH
	JP	SI3
ENDIF
SI4:
	;XOR	A
	;LD	(SDBUF_SIZE), A
	INC	A
	;LD	(DmaMode), A
	XOR	A
	;CALL	SD_LDR
	LD	HL, SdBiosEntry
	LD	DE, BiosEntry
	LD	(SH_ENTR),HL
	EX	DE,HL
	LD	(SD_ENTR),HL
SI3:	LD	(SD_ERR),A
	RET	

SDERR:
	OR	A
	RET	Z
	PUSH	AF
	CALL	RST_18
	defb	13,10,'o{ibka SD:', ' ' + 80H
	POP	AF
	CALL	HEX_A
	CALL	RST_18
	defb	13, 10 + 80H
	RET

SDBIOS:	PUSH	AF
	LD	A,(SD_ERR)
	OR	A
	JP	Z,SDB1
	PUSH	HL
	PUSH	DE
	PUSH	BC
	CALL	SD_INIT
	POP	BC
	POP	DE
	POP	HL
	OR	A
	JP	Z,SDB1
	POP	AF
	JP	SDERR
SDB1:	POP	AF
	JP	SDB_JP

; ??????????????????????????????????????????????

DIR_B:
	LD	HL,DEBUG
CHK_JP:	LD	A,(HL)
	CP	0C3H
	RET	NZ
	JP	(HL)
	
DIR_V:
	LD	A,H
	OR	A
	JP	NZ,ERROR
	LD	A,L
	LD	C,0
	OR	A
	JP	NZ,DV1
	LD	HL,CHSUM
	LD	A,M
	CPL
	LD	M,A
	JP	RABADR
DV1:	CP	48H
	JP	Z,SAVMOD
	INC	C
	CP	32H
	JP	Z,SAVMOD
	INC	C
	CP	16H
	JP	Z,SAVMOD
	JP	ERROR

SAVMOD:
	LD	HL,MODE
	LD	A,(HL)
	CP	C
	RET	Z
	LD	M,C

;	init mode
SETMOD:	LD	HL,TM9VAL
	LD	A,(HL)
	OR	80H
	LD	(TM9),A
	LD	A,(HL)
	AND	7FH
	LD	(HL),A
	LD	A,(MODE)
	OR	A
	JP	NZ,SM2
	LD	A,80H
	OR	(HL)
	LD	(HL),A

SM2:	LD	HL,(SCRBEG)
	LD	A,(MODE)

	LD	DE,SA48
	OR	A
	JP	Z,SM1
	LD	DE,SA32
	DEC	A
	JP	Z,SM1
	LD	DE,SA16

SM1:	EX	DE,HL
	LD	(SCRBEG),HL

	PUSH	HL
	PUSH	DE
	DEC	H
	LD	L,0FFH
	LD	(RAMTOP),HL
	CALL	CALC_CS
	POP	DE
	POP	HL

	LD	B,H
	LD	C,L
	EX	DE,HL
	LD	A,H
	OR	0FH
	LD	D,A
	LD	E,0FFH
	
	CALL	DIR_T
	CALL	SETTM9

	CALL	PUSK_VG

	LD	HL,EK_ADR+1
	LD	A,0FH
	AND	(HL)
	LD	(HL),A
	LD	A,(SCRBEG+1)
	AND	0F0H
	OR	(HL)
	LD	(HL),A

	RET

; ??????????????????????????????????????????????

DIR_A:
	LD	A,H
	OR	A
	JP	NZ,ERROR
	LD	A,L
	AND	0FEH
	JP	NZ,ERROR
	LD	A,L
	AND	01H
	LD	C,A
	LD	A,(TM9VAL)
	AND	0FEH
	OR	C
	LD	(TM9VAL),A
	CALL	CALC_CS
	CALL	SETTM9
	LD	A,(MODE)
	OR	A
	RET	Z
	LD	C,1FH
	CALL	COUT_C
	JP	PUSK_VG

; ??????????????????????????????????????????????

DIR_E:
	LD	A,H
	OR	A
	JP	NZ,ERROR
	LD	A,L
	AND	0FEH
	JP	NZ,ERROR
	LD	A,L
	AND	01H
	LD	(TEMU),A
	CALL	CALC_CS

UPDCALLS:
	LD	A,(TEMU)
	OR	A
	LD	HL,WRB_T
	LD	DE,LDB_T
	JP	Z,UC1
	LD	HL,EMU_WR
	LD	DE,EMU_RD
UC1:
	LD	(WRB_ADR),HL
	EX	DE,HL
	LD	(RDB_ADR),HL
	LD	A,0C3H
	LD	(WRB_JP),A
	LD	(RDB_JP),A
	RET

; ??????????????????????????????????????????????
SYSCALL:
	OR	A
	JP	NZ, SC1
	LD	BC, 0101H
	RET
SC1:	DEC	A
	JP	NZ, SC2
	PUSH	HL
	CALL	SAVMOD
	POP	HL
	RET
SC2:	DEC	A
	JP	NZ,SC3
	LD	A, (MODE)
	RET
SC3:	DEC	A
	RET	NZ
	JP	SD_INIT

; ??????????????????????????????????????????????

EMU_WR:
	PUSH	HL
	PUSH	DE
	PUSH	BC
	PUSH	AF

	LD	A,(EMUCNL)
	OR	A
	JP	NZ,EW3

	LD	A,(EMU_MD)
	CP	1 ; запись
	JP	Z, EW1

	CP	2
	JP	NZ, EW2
	CALL	EMU_CLS

EW2:	LD	A,C
	CP	0E6H
	JP	NZ,EW3

	; синхробайт
EW5:	CALL	GET_FN
	JP	C,EW6

	; create file
	LD	A,2
	LD	D,1
	LD	HL,FLDR
	CALL	SDBIOS
	CP	8 ; file exists
	JP	NZ,EW4

	CALL	RST_18
	defb	'perezapisatx? [Y/.]:', ' ' + 80H
	CALL	CONIN2
	CP	'Y'
	JP	NZ,EW5

	CALL	RST_18
	defb	'Y'+80H

	; delete file
	LD	A,2
	LD	D,100
	LD	HL,FLDR
	CALL	SDBIOS
	OR	A
	JP	NZ,EW4

	; create file again
	LD	A,2
	LD	D,1
	LD	HL,FLDR
	CALL	SDBIOS

EW4:	CALL	SDERR
	JP	NZ,EW6

	LD	A,1
	LD	(EMU_MD),A

	CALL	RST_18
	defb	13,10,'zapisx:', ' ' + 80H

	JP	EW3

EW1:	LD	HL,(SDBUFA)
	LD	(HL),C
	INC	HL
	LD	(SDBUFA),HL
	LD	A,L
	CP	low SDBUF
	CALL	Z,FLBUF
EW3:
	POP	AF
	POP	BC
	POP	DE
	POP	HL
	RET
EW6:	LD	A,0FFH
	LD	(EMUCNL),A
	JP	EW3


EMU_RD:
	PUSH	HL
	PUSH	DE
	PUSH	BC


	PUSH	AF

	LD	A,(EMUCNL)
	OR	A
	JP	NZ,ER3

	LD	A,(EMU_MD)
	CP	2 ; чтение
	JP	Z, ER6

	CP	1
	JP	NZ, ER1
	CALL	EMU_CLS

ER1:	LD	A,2
	LD	(EMU_MD),A
ER9:	CALL	GET_FN
	JP	C,ER3

	; open file
	LD	A,2
	LD	D,0
	LD	HL,FLDR
	CALL	SDBIOS
	CP	04
	JP	Z,ER8
	CALL	SDERR
	JP	NZ,ER3

	CALL	RST_18
	defb	'~tenie:', ' ' + 80H

	; read from file
	LD	A,4
	LD	DE,SDBUF
	LD	HL,0100H
	CALL	SDBIOS
	CALL	SDERR
	JP	NZ,ER3

	CALL	UPDBLK

	POP	AF
	JP	ER2

ER6:	POP	AF
	OR	A
	JP	P,ER2

	; searching synchrobyte
ER4:	CALL	RD_NXTB
	JP	C,ER7
	CP	0E6H
	JP	NZ,ER4

ER2:	; w/o searching synchrobyte
	CALL	RD_NXTB
	JP	C,ER7
	JP	ER5

ER3:	POP	AF
ER7:	LD	A,0FFH
	LD	(EMUCNL),A
ER5:	POP	BC
	POP	DE
	POP	HL
	RET
ER8:	CALL	RST_18
	defb	'net fajla', ' ' + 80H
	LD	HL,FLDR
	CALL	MSGH
	CALL	RST_18
	defb	13,10 + 80H
	JP	ER9


RD_NXTB:
	LD	A,(SDBLFT)
	OR	A
	JP	Z,RN1

	LD	HL,(SDBUFA)
	LD	C,(HL)
	INC	HL
	LD	(SDBUFA),HL
	DEC	HL
	EX	DE,HL
	LD	HL,(SDBEND)
	LD	A,L
	XOR	E
	LD	(SDBLFT),A
	JP	NZ,RN3

	; read from file
	PUSH	BC
	LD	A,4
	LD	DE,SDBUF
	LD	HL,0100H
TTT:	CALL	SDBIOS
	CALL	SDERR
	POP	BC
	JP	NZ,RN1

	CALL	UPDBLK

RN3:	LD	A,C
RN2:	OR	A
	RET
RN1:	SCF
	RET

UPDBLK:
	PUSH	BC
	LD	C,'*'
	CALL	COUT_C
	POP	BC

	EX	DE,HL
	LD	HL,SDBUF
	ADD	HL,DE
	DEC	HL
	LD	(SDBEND),HL
	LD	A,D
	OR	E
	LD	(SDBLFT),A
	LD	HL,SDBUF
	LD	(SDBUFA),HL
	RET

EMU_CLS:
	PUSH	AF
	PUSH	DE
	PUSH	BC
	PUSH	HL

	LD	A,(EMU_MD)
	CP	1
	JP	NZ,EC1

	CALL	FLBUF

	LD	A,5
	LD	HL,0
	CALL	SDBIOS
	CALL	SDERR

EC1:	CALL	EMU_INI
	POP	HL
	POP	BC
	POP	DE
	POP	AF
	RET

EMU_INI:
	LD	HL,SDBUF
	LD	(SDBUFA),HL
	XOR	A
	LD	(EMU_MD),A
	LD	(SDBLFT),A
	LD	(EMUCNL),A
	RET

FLBUF:
	LD	HL,(SDBUFA)

	LD	A,H
	CP	high SDBUF
	JP	NZ,FB2

	LD	A,L
	CP	low SDBUF
	JP	NZ,FB3

	RET

FB2:	PUSH	BC
	LD	C,'*'
	CALL	COUT_C
	POP	BC
FB3:	; write
	LD	A,5
	LD	DE,-SDBUF
	ADD	HL,DE
	LD	DE,SDBUF
	CALL	SDBIOS
	CALL	SDERR
	JP	Z,FB1

	LD	A,0FFH
	LD	(EMUCNL),A

FB1:	LD	HL,SDBUF
	LD	(SDBUFA),HL
	RET

GET_FN:
	PUSH	BC
	PUSH	DE
GF1:	CALL	RST_18
	defb	10,13,'imq fajla[.RKL] (wk-spisok, ar2-otmena):', 20H + 80H
	CALL	GETLN2
	JP	C,GF3
	LD	A,B
	OR	A
	JP	NZ,GF2
	CALL	LST_FN
	JP	GF1
GF2:	CALL	ADDEXT
	CALL	RST_18
	defb	13,10 + 80H
	OR	A
GF3:	POP	DE
	POP	BC
	RET

ADDEXT:	LD	HL,COMBUF
AE1:	LD	A,(HL)
	CP	2EH
	RET	Z
	OR	A
	JP	Z,AE2
	INC	HL
	LD	A,L
	CP	low COMBUF+8
	JP	NZ,AE1
	RET
AE2:	LD	DE,EXT
	LD	B,5
AE3:	LD	A,(DE)
	LD	(HL),A
	LD	C,A
	CALL	COUT_C
	INC	HL
	INC	DE
	DEC	B
	JP	NZ,AE3
	RET

EXT:	defb	'.RKL',0

LST_FN:
	PUSH	AF

	XOR	A
	LD	(COMBUF-1),A

	CALL	RST_18
	defb	10,13,'fajly w', 20H + 80H
	LD	HL,FLDR
	CALL	MSGH
	CALL	RST_18
	defb	':', 13, 10 + 80H

	LD	HL,FLDR
LF2:	LD	A,1
	LD	BC,SDBUF
	LD	DE,12
	CALL	SDBIOS
	PUSH	AF
	LD	A,'/'
	LD	(COMBUF-1),A
	POP	AF

	OR	A
	JP	NZ,LF3
	CALL	PRNFLS
	JP	LF1
LF3:	CP	0AH
	JP	NZ,LF4
	CALL	PRNFLS
	LD	HL,FNEXT
	JP	LF2

LF4:	CALL	SDERR
LF1:	POP	AF
	RET

FNEXT:	defb	':',0


PRNFLS:	EX	DE,HL
	LD	A,E
	OR	A
	RET	Z
	LD	HL,SDBUF
PF1:	PUSH	HL
	LD	BC,11
	ADD	HL,BC
	LD	A,(HL)
	AND	18H ; directory or volume label
	JP	NZ,PF2
	POP	HL
	PUSH	HL
	CALL	PRNFL
PF2:	POP	HL
	LD	BC,20
	ADD	HL,BC
	DEC	E
	JP	NZ,PF1
	RET

PRNFL:	PUSH	HL
	LD	D,11
PFL1:	LD	A,D
	CP	3
	JP	NZ,PFL2
	LD	C,'.'
	CALL	COUT_C
PFL2:	LD	C,(HL)
	CALL	COUT_C
	INC	HL
	DEC	D
	JP	NZ,PFL1
	CALL	RST_18
	defb	'   ',' ' or 80H
	POP	HL
	RET

GETLN2:	LD	HL,COMBUF
	LD	D,H
	LD	E,L
GL22:	XOR	A
	LD	B,A
GL23:	CALL	CONIN2
	CP	1BH
	JP	Z,GL26
	CP	8
	JP	Z,GL25
	CP	7FH
	JP	Z,GL25
	CP	13
	JP	Z,GL24
	CP	20H
	JP	C,GL23
	LD	C,A
	LD	A,low COMBUF+12
	CP	L
	LD	A,C
	JP	Z,GL23
GL21:	LD	(HL),A
	CALL	SCOUTA
;	CP	13
;	JP	Z,GL24
	LD	B,E			; B=76H --> бит D7=0
	INC	HL
	JP	GL23
GL25:	LD	A,E
	CP	L
	JP	Z,GL22
	CALL	RST_18
	defb	8,32,8+128
	DEC	HL
	JP	GL23
GL24:	LD	(HL),0
	OR	A	; C = 0
	RET
GL26:	SCF		; C = 1
	RET

; ??????????????????????????????????????????????

DIR_Z:	DEC	DE
DZ1:	LD	A,C
	CP	(HL)
	JP	NZ,DZ2
	INC	HL
	LD	A,B
	CP	(HL)
	DEC	HL
	CALL	Z,CHXHL@
DZ2:	CALL	AF996
	JP	DZ1

; ??????????????????????????????????????????????
; 9 bytes
CR2:	CALL	RST_18
	defb	0dh,0ah,'  ',' ' or 80H
	RET
; ??????????????????????????????????????????????

	rept	600H
	if	$ ne SD_MOD_ORG
		defb	255
	endif
	endm
	.dephase
	.8080
	include bootRom.asm
	include SendRcv.asm
	.z80
	rept	600H
	if	$ ne ORGB+1800H
		defb	255
	endif
	endm
	.dephase

; ??????????????????????????????????????????????

	.phase  ORGB+1800H

	JP	XF800		; +0
	JP	CONIN 		; +3
	JP	LDBYTE		; +6
	JP	COUT_C		; +9
	JP	WRBYTE		; +C
	JP	COUT_C		; +F   это д.быть PRINT
	JP	STATUS		; +12
	JP	HEX_A 		; +15
	JP	MSGH  		; +18
	JP	XF81B 		; +1B
	JP	ASKCUR		; +1E
	JP	RD_SCR		; +21
	JP	RD_BLK		; +24
	JP	WR_BLK		; +27
	JP	CHSUMM		; +2A
	JP	PUSK_VG		; +2D
ASKTOP: LD	HL,(RAMTOP)	; +30
SETTOP:	LD	(RAMTOP),HL	; +33
	RET

; ??????????????????????????????????????????????

ESCRES:	XOR	A			; 5 bytes
SETESC:	LD	(ESC_F),A
	RET

; ??????????????????????????????????????????????

XF800: ; +6
	LD	SP,STACK

	LD	A,8AH
	LD	(PORT_CTRL),A

	LD	HL, VI_53+3
	LD	(HL),36H
	LD	(HL),66H
	LD	(HL),0B6H

	CALL	CHK_KBD_CS
	CALL	SETTM9
	CALL	CLRMON
	CALL	UPDCALLS
;	CALL	SD_INIT

	LD	SP,SG+800H

	XOR	A
	LD	D,A
	DEC	D
	LD	E,D
CL_SG1:	PUSH	DE
	PUSH	DE
	PUSH	DE
	PUSH	DE
	DEC	A
	JP	NZ,CL_SG1
	
	LD	SP,STACK

	NOP

if	$ ne RABADR + 6CH
	if1
	.printx * Standard subroutine WARMST shifted ! *
	endif
endif
WARMST:				; Warm_BOOT
	LD	SP,STACK

	LD	A,90H
	LD	(PORT2_CTRL),A

	CALL	PRMPT

;	CALL	SET_RL
	CALL	GETLIN

	LD	HL,WARMST
	PUSH	HL

	LD	HL,COMBUF
	LD	A,(HL)
	CP	0DH
	RET	Z

	PUSH	AF
	CALL	GETPRM
	LD	HL,(PAR_BC)		; Z80: LD BC,(PAR_BC)
	LD	C,L
	LD	B,H
	LD	HL,(PAR_DE)		; Z80: LD BC,(PAR_DE)
	EX	DE,HL
	LD	HL,(PAR_HL)
	POP	AF

	CP	'D'
	JP	Z,DIR_D
	CP	'C'
	JP	Z,DIR_C
	CP	'S'
	JP	Z,DIR_S
	CP	'T'
	JP	Z,DIR_T
	CP	'M'
	JP	Z,DIR_M
	CP	'G'
	JP	Z,DIR_G
	CP	'I'
	JP	Z,DIR_I
	CP	'O'
	JP	Z,DIR_O
	CP	'N'
	JP	Z,DIR_N
	CP	'B'
	JP	Z,DIR_B
	CP	'L'
	JP	Z,DIR_L
	CP	'R'
	JP	Z,DIR_R
	CP	'F'
	JP	Z,DIR_F
	CP	'V'
	JP	Z,DIR_V
	CP	'A'
	JP	Z,DIR_A
	CP	'E'
	JP	Z,DIR_E
	CP	'Z'
	JP	Z,DIR_Z
	JP	ERROR

;  	rept	5
;	defb	0
;	endm

; ??????????????????????????????????????????????

;HEX_A:	PUSH	AF			; 24 bytes
;	RRCA
;	RRCA
;	RRCA
;	RRCA
;	CALL	NIBBLE
;	POP	AF
;NIBBLE: AND	0FH
;	CP	10
;	CCF
;	ADC	A,30H
;	DAA
;SCOUTA:
;	PUSH	BC
;	LD	C,A
;	CALL	COUT_C
;	POP	BC
;	RET
	
; ??????????????????????????????????????????????

if	$ ne RABADR + 0EEH
	if1
	.printx * Internal subroutine GETLIN shifted ! *
	endif
endif

GETLIN:	LD	HL,COMBUF
	LD	D,H
	LD	E,L
AF8F1:
	XOR	A
	LD	B,A		; чтобы на выходе получить флаг пустой строки
;	CALL	SET_RL
AF8F3:	CALL	CONIN		; используется в DIR_M
	CP	8
	JP	Z,BAKSTP
	CP	13
	JP	Z,GL1
	CP	20H
	JP	C,AF8F3
	CP	7FH
	JP	Z,BAKSTP
GL1:	LD	(HL),A
	CALL	SCOUTA
	CP	13
;	RET	Z
	JP	Z,AF91A
	CP	'.'
	JP	Z,WARMST
	LD	B,E			; B=76H --> бит D7=0
	LD	A,low COMBUF+15
	CP	L
	JP	Z,ERROR
	INC	HL
	JP	AF8F3

WRBYTE:	JP	WRB_JP
LDBYTE:	JP	RDB_JP

	NOP

; ??????????????????????????????????????????????

if	$ ne RABADR + 012CH
	if1
	.printx * Internal subroutine GETPRM shifted ! *
	endif
endif

GETPRM:	LD	HL,PAR_HL
	LD	DE,PAR_DE
	LD	C,0
	CALL	DIR_F

if	high (COMBUF+01H) eq high BASE
	LD	E,low COMBUF + 1
    else
	.printx *      Wrong BASE (Low BASE need be < 0E0H) !
endif
	CALL	GET_HL
	LD	(PAR_HL),HL
	LD	(PAR_DE),HL
	RET	C
	LD	(FLG_P2),A

	CALL	GET_HL
	LD	(PAR_DE),HL
	RET	C

	CALL	GET_HL
	LD	(PAR_BC),HL
	RET	C
	JP	ERROR

; ??????????????????????????????????????????????

AFE97:	PUSH	HL			; 27 bytes
	LD	HL,7 shl 8 + 1
AFE9C:	LD	A,L
	RRCA
	LD	L,A
	CPL
	LD	(PORT_A),A
	LD	A,(PORT_B)
	CPL
	OR	A
	JP	NZ,AFEB3
	DEC	H
	JP	P,AFE9C
AFEAF:	LD	A,0FFH
	POP	HL
	RET

; ??????????????????????????????????????????????

XF81B:	LD	A,(PORT_C)		; 30 bytes
	RLA
	LD	A,0FEH
	RET	NC
AFE7D:
	XOR	A
	LD	(PORT_A),A
	LD	A,(RUSLAT)
	AND	00000001B
	OR	00000110B	; зажигаем/гасим светодиод
	LD	(PORT_CTRL),A
	LD	A,(PORT_B)
	INC	A
	JP	NZ,AFE97
	DEC	A
	RET

; ??????????????????????????????????????????????

if	$ ne RABADR + 0190H
	if1
	  .printx * Internal subroutine CMPDH shifted ! *
	endif
endif

CMPDH:	LD	A,H
	CP	D
	RET	NZ
	LD	A,L
	CP	E
	RET

; ??????????????????????????????????????????????

BAKSTP:	LD	A,E			; 15 bytesCALL	
	CP	L			; начало буфера ввода ?
	JP	Z,AF8F1
	CALL	RST_18
TZABOJ:	defb	8,32,8+128
	DEC	HL
	JP	AF8F3

; ??????????????????????????????????????????????

DIR_S:	LD	A,C			; 11 bytes
	CP	(HL)
	CALL	Z,CHXHL@
	CALL	AF996
	JP	DIR_S

; ??????????????????????????????????????????????

if	$ ne RABADR + 01B0H
	if1
	.printx * Internal subroutine CR shifted ! *
	endif
endif

CR:	JP	CR2

; ??????????????????????????????????????????????

DIR_I:	LD	A,(FLG_P2)		; 46 bytes
	OR	A
	JP	Z,AFA91
	LD	A,E
	LD	(KNS_RD),A
AFA91:	CALL	RD_BLK

	CALL	JJJ2
	EX	DE,HL

	PUSH	BC
	CALL	CHSUMM
	CALL	DIRK1
	POP	DE

	CALL	CMPDH
	RET	Z
	CALL	CHXDE@
ERROR:	CALL	RST_18
	defb	'?'+80H
	JP	WARMST

; ??????????????????????????????????????????????

DIR_L:	CALL	CHXHL@			; 30 bytes
AFA0B:	LD	A,(HL)
	OR	A
	JP	M,AFA15
	CP	20H
	JP	NC,AFA17
AFA15:	LD	A,'.'
AFA17:	CALL	SCOUTA
	CALL	AF996
	LD	A,L
	AND	0FH
	JP	Z,DIR_L
	JP	AFA0B

; ??????????????????????????????????????????????

; ВХОД: E=POSX, D=POSY
;       HL= экранный адрес

COD_18:				; 29 bytes
	LD	A,E		; POSX
	INC	HL		; следующий экранный адрес
	INC	E		; POSX ++
	CP	SCR_XOFS+(SCR_VIS_WIDTH-1) 		; последняя колонка ?
	RET	NZ		; если была не последняя колонка
	LD	E,SCR_XOFS	; нач.позиция по X на новой строке
	LD	BC,-SCR_VIS_WIDTH
	ADD	HL,BC		; Вычесть SCR_VIS_WIDTH = экр.поз в начало строки
COD_1A:	LD	A,D
	CP	SCR_YOFS+(SCR_HEIGHT-1)		; последняя строка ?
	LD	BC,SCR_WIDTH
	JP	NZ,AFDD3	; если не последняя строка
	LD	D,SCR_YOFS-1	; если последняя строка, то на первую строку
	LD	BC,-(SCR_HEIGHT-1)*SCR_WIDTH
AFDD3:	INC	D
	ADD	HL,BC		; вычесть (SCR_HEIGHT-1)*SCR_WIDTH
	RET

; ??????????????????????????????????????????????

AFF3B:	LD	A,L			; 23 bytes
	AND	2FH
	LD	L,A
AFF3F:	LD	A,L
	CP	40H
	POP	HL
	RET	P
	PUSH	HL
	LD	L,A
	AND	00FH
	CP	00CH
	LD	A,L
	JP	M,AFF50
	XOR	10H
AFF50:	POP	HL
	RET

; ??????????????????????????????????????????????

CHSUMM:	LD	BC,0			; 23 bytes
AFB19:	LD	A,(HL)
	ADD	A,C
	LD	C,A
	PUSH	AF
	CALL	CMPDH
	JP	Z,POPAF
	POP	AF
	LD	A,B
	ADC	A,(HL)
	LD	B,A
	CALL	AF999
	JP	AFB19

; ??????????????????????????????????????????????

DIR_M:	CALL	JJJ_02			; 22 bytes
	PUSH	HL
	CALL	GETLIN
	POP	HL
	JP	NC,AFA3B
	PUSH	HL
	CALL	GET_HL
	LD	A,L
	POP	HL
	LD	(HL),A
AFA3B:	INC	HL
	JP	DIR_M

; ??????????????????????????????????????????????

DIR_R:
AFA6D:	LD	(PORT2_B),HL
	LD	A,(PORT2_A)
	LD	(BC),A
	INC	BC			; 19 bytes
	CALL	AF999
	JP	AFA6D

; ??????????????????????????????????????????????

DIR_D:	CALL	CHXHL@			; 18 bytes
AF9C8:	CALL	LDXHX@
	CALL	AF996
	LD	A,L
	AND	0FH
	JP	Z,DIR_D
	JP	AF9C8

; ??????????????????????????????????????????????

KEY_FE:	LD	A,(PORT_C)			; 17 bytes
	RLA
	JP	NC,KEY_FE		; ждём отпускания РУС/ЛАТ
	LD	A,(RUSLAT)
	CPL
	CALL	SET_RL
	JP	AFE1A

; ??????????????????????????????????????????????

BYTE3:	LD	A,C			; 18 bytes
	SUB	20H
	LD	C,A
AFD77:	DEC	C
	LD	A,4
	JP	M,SETESC
	PUSH	BC
	CALL	COD_1A
	POP	BC
	JP	AFD77

; ??????????????????????????????????????????????

MSGH:	LD	A,(HL)			; 11 bytes
	OR	A
	RET	Z
	CALL	SCOUTA
	INC	HL
	RET	M
	JP	MSGH

; ??????????????????????????????????????????????

AF996:	CALL	CHK_F4			; 11 bytes
AF999:	CALL	CMPDH
	INC	HL
	RET	NZ
	DEC	HL
POPAF:	POP	AF
	RET

; ??????????????????????????????????????????????

RD_BLK:	LD	A,0FFH
	CALL	@LD_BC
	PUSH	HL
	ADD	HL,BC
	EX	DE,HL
	CALL	LDBCBS
	POP	HL
	ADD	HL,BC
	EX	DE,HL
	PUSH	HL
	CALL	LD_BLK
	LD	A,0FFH		; с поиском СБ
	CALL	@LD_BC
	POP	HL		; БЫСТРЕЕ DB 06 -> LD B,NN

	NOP
	NOP
	NOP

if	$ ne RABADR + 02CEH	; FACE
	if1
	.printx * Internal subroutine PUSK_VG shifted ! *
	endif
endif

PUSK_VG:			; 1001.0011
				; 1100.0011

	PUSH	HL
IFNDEF VDP
	LD	HL,VG_75+1
ELSE
	CALL	SetVDP
	POP	hl
	RET
ENDIF

P_VG0:
	LD	(HL),0		; reset commando
	DEC	HL		; адрес VG_75
	LD	(HL),04DH	; 0.1001101  77+1 знакомест
	LD	(HL),05DH	; 00.011101  29+2 строк
	LD	(HL),0FFH	; 1111.1110  
				; 9+1 линий в знакоместе, 9 +1 линия подчерк.
 
	LD	(HL),0D8H	; 1.0.01.1000 без смещ.
				; курсор - мигающая линия подчеркивания
				; атрибуты отображать пробелом
	 			; 18 тактов - длина обр хода в стр.

	INC     HL		; адрес VG_75+1
	LD	(HL),27H	; start display command
	LD	A,(HL)		; read status
AFAE1:	LD	A,(HL)		; read status
	AND	20H		; mask 'Interrupt request flag'
	JP	Z,AFAE1		; ждем конца строки
	LD	HL,VT_57+8
	LD	(HL),80H
	LD	L,4		; VT_57+04
	LD	A,(SCRBEG)
	LD	(HL),A		; 0D0H
	LD	A,(SCRBEG+1)
	LD	(HL),A		; 076H
	INC	L		; адрес VT_57+5
	LD	(HL),23H
	LD	(HL),49H
	LD	L,8		; VT_57+8
	LD	(HL),0A4H
	POP	HL
	RET

; ??????????????????????????????????????????????

WR_BLK:
	PUSH	BC		; КС

	LD	BC,0		; выводим 256 байтов 00 (пилотон)
AFB4D:	CALL	WRBYTE
	EX	(SP),HL 	; это задержка 38 тактов
	EX	(SP),HL
	DEC	B
	JP	NZ,AFB4D

	LD	C,0E6H  	; выводим синхробайт E6
	CALL	WRBYTE

	CALL	WR_HL		; выводим НА
	EX	DE,HL
	CALL	WR_HL		; выводим КА

	EX	DE,HL
	CALL	AFB86		; выводим блок

	LD	HL,0
	CALL	WR_HL		; выводим 2 байта 00

	LD	C,0E6H  	; снова выводим с/байт E6
	CALL	WRBYTE

	POP	HL
	CALL	WR_HL		; выводим КС

	JP	PUSK_VG

; ??????????????????????????????????????????????

; Вводит в HL HEX-число из строки по (DE) до нажатия ВК

GET_HL:	LD	HL,0		; 48 bytes
AF95D:	LD	A,(DE)		; Выход: CY=1 если разделитель <ВК>
	INC	DE
	CP	13
	SCF
	RET	Z
	CP	','
	RET	Z
	CP	20H
	JP	Z,AF95D

	LD	BC,ERROR
	PUSH	BC

	SUB	'0'
	RET	C		; JP C,ERROR

	CP	9+1
	JP	C,AF982

	CP	'A'-'0'
	RET	C		; JP C,ERROR

	CP	'F'-'0'+1
	RET	NC		; JP NC,ERROR

	SUB	'A'-('9'+1)
AF982:
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	RET	C		; JP C,ERROR

	OR	L
	LD	L,A

	POP	AF
	JP	AF95D

; ??????????????????????????????????????????????

AF91A:	SUB	B			; 2 bytes
	RET

; ??????????????????????????????????????????????

SET_RL:	LD	(RUSLAT),A		; 6 bytes
	RET
;	JP	PUSK_VG

; ??????????????????????????????????????????????

	rept	12
	defb	0
	endm

JJJ2:	CALL	CHXHL@

if	$+1 ne RABADR + 0378H
	if1
	.printx * Internal subroutine CHXHL@ shifted ! *
	endif
endif

CHXDE@:	EX	DE,HL
CHXHL@: CALL	CR
HEXHL@:	LD	A,H
	CALL	HEX_A
	LD	A,L
	JP	HEXABL

; ??????????????????????????????????????????????

LDBS:	LD	A,8
	JP	LDBYTE

	rept	16
	defb	0
	endm

if	$ ne RABADR + 0398H
	if1
	.printx * LDBYTE for emulator B2M need be at FB98 ! *
	endif
endif

LDB_T:
	PUSH	HL
	PUSH	DE
	PUSH	BC
	LD	D,A
AFB9C:	LD	A,80H
	LD	(VT_57+8),A

	LD	HL,0
	LD	C,L
	ADD	HL,SP
	LD	(TMPSTK),HL

	LD	SP,0
	LD	A,(PORT_C)
	RRCA
	RRCA
	RRCA
	RRCA
	AND	1
	LD	E,A
AFBB7:	POP	AF
	LD	A,C
	AND	07FH
	RLCA
	LD	C,A
	LD	H,0
AFBBF:	DEC	H
	JP	Z,AFC34
	POP	AF		; Регенерация ОЗУ
	LD	A,(PORT_C)
	RRCA
	RRCA
	RRCA
	RRCA
	AND	1
	CP	E
	JP	Z,AFBBF
	OR	C
	LD	C,A
	DEC	D
	LD	A,(KNS_RD)
	JP	NZ,AFBDC
	SUB	012H
AFBDC:	LD	B,A
AFBDD:	POP	AF		; Регенерация ОЗУ
	DEC	B
	JP	NZ,AFBDD
	INC	D
	LD	A,(PORT_C)
	RRCA
	RRCA
	RRCA
	RRCA
	AND	001H
	LD	E,A
	LD	A,D
	OR	A
	JP	P,AFC0B
	LD	A,C
	CP	0E6H		; ПРЯМОЙ СИНХРО-БАЙТ ?
	JP	NZ,AFBFF
	XOR	A
	LD	(INV_MG),A	; ПРИЗНАК ИНВЕРСИИ МАГНИТОФОНА
	JP	AFC09

; ??????????????????????????????????????????????

AFBFF:	CP	19H		; ОБРАТНЫЙ С/БАЙТ
	JP	NZ,AFBB7	; 58 bytes
	LD	A,0FFH
	LD	(INV_MG),A 	; Tape inverse flag
AFC09:	LD	D,9
AFC0B:	DEC	D
	JP	NZ,AFBB7

;	LD	HL,VT_57+4
;	LD	(HL),low SA		; 0D0H
;	LD	(HL),high SA		; 076H
;	INC	HL
;	LD	(HL),023H
;	LD	(HL),049H
;	LD	A,27H			; start display commando
;	LD	(VG_75+1),A
	LD	A,0E0H			; reset count
	LD	(VG_75+1),A
;	LD	L,8
;	LD	(HL),0A4H

	LD	HL,(TMPSTK)
	LD	SP,HL

	LD	A,(INV_MG)
	XOR     C			; with Tape Inverse flag
	JP	POPREG

; ??????????????????????????????????????????????

BYTE2:	LD	A,C			; 14 bytes
	CP	'Y'
	JP	NZ,ESCRES
	CALL	HOME
	LD	A,2			; ПРИНЯТО 2 БАЙТА ESC,'Y'
	JP	SETESC

; ??????????????????????????????????????????????

COD_0D:	LD	A,L			; 12 bytes
	SUB	E
	JP	NC,AFDF9
	DEC	H
AFDF9:	LD	L,A
	LD	BC,SCR_XOFS
	LD	E,C
	ADD	HL,BC
	RET

; ??????????????????????????????????????????????

WR_HL:	LD	C,H
	CALL	WRBYTE
	LD	C,L
	JP	WRBYTE

	rept	5
	defb	0
	endm

if	$ ne RABADR + 0446H
	if1
	.printx * WRBYTE for emulator B2M need be at FC46 ! *
	endif
endif

WRB_T:
	PUSH	HL
	PUSH	DE
	PUSH	BC
	PUSH	AF
	LD	A,80H
	LD	(VT_57+8),A
	LD	HL,0
	ADD	HL,SP		; временно храним стек
	LD	SP,0		; для регенерации
	LD	D,8
AFC58:	POP	AF
	LD	A,C
	RLCA
	LD	C,A
	LD	A,1
	XOR	C
	LD	(PORT_C),A
	LD	A,(KNS_WR)
	LD	B,A
AFC66:	POP	AF
	DEC	B
	JP	NZ,AFC66
	LD	A,0		; XOR A = LD A,B (в данном случае незачем)
	XOR	C
	LD	(PORT_C),A
	DEC	D
	LD	A,(KNS_WR)
	JP	NZ,AFC7A
	SUB     14
AFC7A:	LD	B,A

AFC7B:	POP	AF            ; подъем стека на [рег.B] ячеек
	DEC	B
	JP	NZ,AFC7B
	INC	D
	DEC	D
	JP	NZ,AFC58
	
	LD	SP,HL
;	LD	HL,VT_57+4
;	LD	(HL),low SA	; 0D0H
;	LD	(HL),high SA	; 076H
;	INC	HL		; VT_57+5
;	LD	(HL),23H
;	LD	(HL),49H
;	LD	A,27H		; start display commando
;	LD	(VG_75+1),A	; 001.sss.bb    001.001.11
	LD	A,0E0H		; сброс счетчиков строк и знакомест ???
	LD	(VG_75+1),A
;	LD	L,8
;	LD	(HL),0A4H	; VT_57+8
	POP	AF
POPREG: POP	BC
	POP	DE
	POP	HL
	RET

DIR_F:
	LD	(HL),C
	CALL	AF999
	JP	DIR_F

	rept	13
	defb	0
	endm

LD_BAK:	RET

if	LD_BAK ne RABADR + 4A4H 
	if1
	.printx	* Internal point 0FCA4H (need for emulator B2M) shifted ! *
	endif
endif

; ??????????????????????????????????????????????

COUT_C:	PUSH	HL
	PUSH	DE
	PUSH	BC
	PUSH	AF

	CALL	STATUS
	LD	HL,TOBACK
	PUSH	HL
	LD	HL,(POSX)
	EX	DE,HL
	LD	HL,(EK_ADR)
	LD	A,(ESC_F)
	OR	A
	JP	Z,NO_ESC
	DEC	A
	JP	Z,BYTE2		; если второй байт ('Y')
	DEC	A
	JP	Z,BYTE3		; если третий байт
	LD	A,C		; четвёртый байт
	SUB	20H
	LD	C,A
AFCDD:	DEC	C
	JP	M,ESCRES	; СБРОС ESC_F И ВЫХОД
	PUSH	BC
	CALL	COD_18
	POP	BC
	JP	AFCDD

; ??????????????????????????????????????????????

NO_ESC:	LD	A,C
IFNDEF VDP
	AND	7FH
ELSE
	AND	7FH
ENDIF
	CP	7
	JP	Z,BEEP
	CP	8
	JP	Z,COD_08
	CP	10
	JP	Z,COD_0A
	CP	0CH
	JP	Z,HOME
	CP	13
	JP	Z,COD_0D
	CP	1FH
	JP	Z,CLS
	LD	C,A
	SUB	18H
	JP	Z,COD_18
	DEC	A
	JP	Z,COD_19
	DEC	A
	JP	Z,COD_1A
	DEC	A
	JP	Z,COD_1B

IFNDEF VDP
	LD	(HL),C		; Видимый на экране символ
	CALL	COD_18		; сместить на следующее знакоместо
ELSE
	NOP
	CALL	WriteHLMoveRight
ENDIF
	LD	A,D
	CP	SCR_YOFS		; мы на первой строке ?
	RET	NZ		; если не на первой строке
	LD	A,E
	CP	SCR_XOFS		; мы в первой колонке ?
	RET	NZ		; если не на первой колонке
	CALL	COD_19
COD_0A:	LD	A,D
	CP	SCR_YOFS+(SCR_HEIGHT-1)		; мы на последней строке ?
	JP	NZ,COD_1A	; если не на последней строке

	JP	SCROLL

; ??????????????????????????????????????????????


TABK2:	defb	09,0AH,0DH,7FH,08H,19H,18H,1AH	; 8 bytes

; ??????????????????????????????????????????????

AFEB3:	LD	L,20H			; 47 bytes
AFEB5:	LD	A,(PORT_B)
	CPL
	OR	A
	JP	Z,AFEAF
	DEC	L
	JP	NZ,AFEB5
	LD	L,8
AFEC3:	DEC	L
	RLCA
	JP	NC,AFEC3
	LD	A,H
	LD	H,L
	LD	L,A
	CP	1
	JP	Z,AFEFA
	JP	C,AFEF3
	RLCA
	RLCA
	RLCA
	ADD	A,20H
	OR	H
	CP	5FH
	JP	NZ,AFF06
	LD	A,20H
	POP	HL
	RET

; ??????????????????????????????????????????????

AFE2A:	DEC	H			; в рег.A=код клав, в рег.H- COUNT
	JP	NZ,AFE21		; 39 bytes
	INC	A
	JP	Z,AFE22			; если код FF, то сброс флагов
	INC	A
	JP	Z,KEY_FE		; если код FE (RUSLAT)

	PUSH	BC			; КЛИК
	LD	BC,0205H		; B - длительность, C - высота
	CALL	SND_BC
	POP	BC

	LD	A,(APVFLG)
	LD	H,0E0H
	DEC	A
	LD	(APVFLG),A
	JP	Z,AFE4C
	LD	H,18H			; скорость повтора
AFE4C:	LD	A,0FFH
	JP	AFE22

; ??????????????????????????????????????????????

; После 15 вызовов STATUS при нажатой клавише выставляется флаг KBDFLG

STATUS:
IF 0
	XOR	A
	RET
	NOP
ELSE
	LD	A,(PORT_C)		; 38 bytes
ENDIF
	RLA
	JP	NC,AFE0E	; если нажат RUS/LAT
	LD	A,(KBDFLG)
	OR	A
	RET	NZ		; если в SYMBUF уже есть символ
AFE0E:	PUSH	HL
	LD	HL,(LAST_K)
	CALL	XF81B
	CP	L
	LD	L,A
	JP	Z,AFE2A
AFE1A:	LD	A,1
	LD	(APVFLG),A
	LD	H,0CH		; число опросов, чтобы зафиксировать код
AFE21:	XOR	A
AFE22:	LD	(LAST_K),HL
	POP	HL
	LD	(KBDFLG),A
	RET

; ??????????????????????????????????????????????

AFF1A:	LD	A,(RUSLAT)		; 33 bytes
	OR	A
	JP	Z,AFF2A
	LD	A,L
	CP	40H
	JP	M,AFF2A
	OR	20H
	LD	L,A
AFF2A:	LD	A,H
	AND	20H
	JP	NZ,AFF3F
	LD	A,L
	CP	40H
	JP	M,AFF3B
	LD	A,L
	XOR	20H
	POP	HL
	RET

; ??????????????????????????????????????????????

AFEFA:	LD	A,H			; 32 bytes
	LD	HL,TABK2
AFEFE:	ADD	A,L
	LD	L,A
	LD	A,(HL)
	CP	40H
	POP	HL
AFF04:	RET	C
	PUSH	HL
AFF06:	LD	L,A
	LD	A,(PORT_C)
	LD	H,A
	AND	40H
	JP	NZ,AFF1A
	LD	A,L
	CP	40H
	JP	M,AFF3F
	AND	1FH
	POP	HL
	RET

; ??????????????????????????????????????????????

COD_08:					; ВХОД: E=POSX, D=POSY
					;       HL= экранный адрес

	LD	A,E			; 29 bytes
	DEC	HL
	DEC	E
	CP	SCR_XOFS		; были в первой колонке ?
	RET	NZ			; если были не в первой колонке
	LD	E,SCR_XOFS+(SCR_VIS_WIDTH-1)		; POSX последней колонки
	LD	BC,SCR_VIS_WIDTH
	ADD	HL,BC			; экр.адрес в последнюю колонку
COD_19:	LD	A,D
	CP	SCR_YOFS		; это первая строка ?
	LD	BC,-SCR_WIDTH
	JP	NZ,AFDF0
	LD	D,SCR_YOFS+SCR_HEIGHT
	LD	BC,(SCR_HEIGHT-1)*SCR_WIDTH
AFDF0:	DEC	D
	ADD	HL,BC			; Вычесть SCR_WIDTH или прибавить (SCR_HEIGHT-1)*28
	RET

; ??????????????????????????????????????????????

TOBACK:
IFDEF	VDP
	CALL	CursorSet
	REPT	13h-9
	NOP
	ENDM
ENDIF
	LD	(EK_ADR),HL	; 24 bytes
	EX	DE,HL
	LD	(POSX),HL
IFNDEF VDP
	LD	A,80H
	LD	(VG_75+1),A
	LD	A,L
	LD	(VG_75),A
	LD	A,H
	LD	(VG_75),A
ENDIF
	POP	AF
	JP	POPREG

; ??????????????????????????????????????????????

AFC34:	LD	HL,(TMPSTK)	; 18 bytes
	LD	SP,HL
	CALL	PUSK_VG
	LD	A,D
	OR	A
	JP	P,ERROR
	CALL	CHK_F4
	JP	AFB9C

; ??????????????????????????????????????????????

JJJ_02:	CALL	CHXHL@		; 12 bytes
LDXHX@:	LD	A,(HL)
HEXABL:	CALL	HEX_A
SPACE:	LD	A,20H
	JP	SCOUTA

; ??????????????????????????????????????????????

; загр.BC без поиска СБ                        
; без поиска СБ, если A=8, с поиском, если A=FF

LDBCBS:	LD	A,8		; 11 bytes	
@LD_BC:	CALL	LDBYTE		
	LD	B,A
	CALL	LDBS
	LD	C,A
	RET

; ??????????????????????????????????????????????

RST_18: EX	(SP),HL		; 6 bytes
	CALL	MSGH
	EX	(SP),HL
	RET

; ??????????????????????????????????????????????

LD_BLK:	CALL	LDBS		; 10 bytes
	LD	(HL),A
	CALL	AF999
	JP	LD_BLK

; ??????????????????????????????????????????????

CHK_F4:	CALL	XF81B			; 12 bytes
	CP	3
	RET	NZ
	CALL	PUSK_VG
	JP	ERROR

; ??????????????????????????????????????????????

	;NOP

if	$ ne RABADR + 663H
	if1
	.printx	* Internal point FE63 (need for emulator emu80) shifted ! *
	endif
endif

CONIN:	CALL	EMU_CLS
CONIN2:	CALL	STATUS
	OR	A
	JP	Z,CONIN2
	XOR	A
	LD	(KBDFLG),A
	LD	A,(LAST_K)
	RET

; ??????????????????????????????????????????????

;BEEP:	LD	BC,05F0H		; 20 bytes
;SND_BC:	LD	A,B
;BPLOO1:	EI
;	DEC	A
;	JP	NZ,BPLOO1
;	LD	A,B
;BPLOO2:	DI
;	DEC	A
;	JP	NZ,BPLOO2
;	DEC	C
;	JP	NZ,SND_BC
;	RET
BEEP:	LD	BC,0808H
SND_BC:	PUSH	HL
	LD	HL,VI_53+3
	LD	(HL),36H
	LD	L,0
	LD	(HL),C
	LD	(HL),C
BPL1:	LOOP	BPL1
	LD	L,3
	LD	(HL),36H
	POP	HL
	RET

; ??????????????????????????????????????????????

CLS:
IFNDEF	VDP
	LD	HL,(SCRBEG)		; 19 bytes +16
	LD	A,H
	AND	0F0H
	ADD	A,10H
	LD	C,A
CLSLOO:	LD	(HL),0
	INC	HL
	LD	A,H
	CP	C
	JP	C,CLSLOO
ELSE
IF 0
	LD	HL, T_T80_VRAM_NAME_ADDRESS
	LD	BC,SCR_WIDTH * SCR_HEIGHT
	LD	DE, 0F4h
	CALL	T_FillWord
ELSE
	LD	BC,0150h
	CALL	T_WriteRegValue

	LD	DE, T_T80_VRAM_NAME_ADDRESS
	LD	BC,SCR_WIDTH * SCR_HEIGHT
	XOR	A
	CALL	T_Fill

	LD	DE, T_T80_VRAM_ATTR_ADDRESS
	LD	BC,SCR_WIDTH * SCR_HEIGHT
	LD	A, 0F4h
	CALL	T_Fill

	LD	BC,0154h
	CALL	T_WriteRegValue
ENDIF
ENDIF
SCR_START	EQU	(SCR_YOFS SHL 8)+SCR_XOFS
HOME:	LD	DE, SCR_START
IFNDEF	VDP
	LD	HL,(SCRBEG)
ELSE
	LD	HL,T_T80_VRAM_NAME_ADDRESS
ENDIF
	LD	BC,SCR_WIDTH*SCR_YOFS+SCR_XOFS
	ADD	HL,BC
	RET

; ??????????????????????????????????????????????

AFB86:	LD	C,(HL)			; 10 bytes
	CALL	WRBYTE
	CALL	AF999
	JP	AFB86

; ??????????????????????????????????????????????

TABK1:	defb	0CH,1FH,1BH,0,1,2,3,4,5	  ; 9 bytes

; ??????????????????????????????????????????????

DIR_T:	LD	A,(HL)			; 9 bytes
	LD	(BC),A
	INC	BC
	CALL	AF999
	JP	DIR_T

; ??????????????????????????????????????????????

RD_SCR: PUSH	HL			; 7 bytes
IFNDEF VDP
	LD	HL,(EK_ADR)
	LD	A,(HL)
ELSE
	CALL	ReadHLEk
	NOP
ENDIF
	POP	HL
	RET

; ??????????????????????????????????????????????

AFEF3:	LD	A,H			; 7 bytes
	LD	HL,TABK1
	JP	AFEFE

; ??????????????????????????????????????????????

DIRK1:	LD	H,B			; 5 bytes
	LD	L,C
	JP	CHXHL@

; ??????????????????????????????????????????????

COD_1B:	INC	A			; 4 bytes LD A,1
	JP	SETESC

; ??????????????????????????????????????????????

ASKCUR:	LD	HL,(POSX)		; 4 bytes
	RET

; ??????????????????????????????????????????????

DIR_G:	JP	(HL)			; 1 bytes

; ??????????????????????????????????????????????


DIR_O:	LD	A,C
	OR	A
	JP	Z,AFB35
	LD	(KNS_WR),A
AFB35:	PUSH	HL
	CALL	CHSUMM
	POP	HL
	
	CALL	JJJ2
	EX	DE,HL
	
	PUSH	HL
	CALL	DIRK1
	POP	HL

	JP	WR_BLK

; ??????????????????????????????????????????????

CLRMON:
	CALL	PUSK_VG

	LD	HL,BASE
	LD	C,L			; 0
	LD	DE,BASE+4FH
	CALL	DIR_F

	LD	HL,BASE-1
	LD	(RAMTOP),HL

	LD	HL,(SCRBEG)
	LD	L,0FFH
	DEC	H
	LD	(RAMTOP),HL


	LD	HL,1D2AH
	LD	(KNS_RD),HL

	LD	A,0FFH
	LD	(SD_ERR),A

	LD	A,0C3H
	LD	(SDB_JP),A

	LD	BC,FLDR
	LD	HL,DFLDR
	LD	DE,DFLDR+4
	CALL	DIR_T

	CALL	RST_18
TITR:	defb	1FH,'sewernaq palxmira 1.','1' or 80H

	CALL	PUSK_VG

	RET

DFLDR:	defb	'TAPE/'
;DFLDR:	defb	'SOFT/'

; ??????????????????????????????????????????????

HEX_A:	PUSH	AF			; 24 bytes
	RRCA
	RRCA
	RRCA
	RRCA
	CALL	NIBBLE
	POP	AF
NIBBLE: AND	0FH
	CP	10
	CCF
	ADC	A,30H
	DAA
SCOUTA:
	PUSH	BC
	LD	C,A
	CALL	COUT_C
	POP	BC
	RET

; ??????????????????????????????????????????????

DIR_C:	LD	A,(BC)			; 19 bytes
	CP	(HL)
	JP	Z,AF9E6
	CALL	JJJ_02
	LD	A,(BC)
	CALL	HEXABL
AF9E6:	INC	BC
	CALL	AF996
	JP	DIR_C
; ??????????????????????????????????????????????

VDP_SET_REGISTER macro reg,val
	LD	BC, reg*256+val
	call	T_WriteRegValue
	ENDM

SCROLL:
IFNDEF	VDP
	PUSH	HL
	PUSH	DE
	PUSH	BC
	LD	HL,0
	ADD	HL,SP
	LD	(TMPSTK),HL
	LD	HL,(SCRBEG)
	LD	BC,SCR_WIDTH*4+SCR_XOFS
	ADD	HL,BC
	LD	SP,HL
	LD	BC,-SCR_WIDTH
	ADD	HL,BC
	LD	B,SCR_HEIGHT
SCRL1:	LD	C,16
SCRL2:	defb	0D1H,73H,23H,72H,23H,0D1H,73H,23H,72H,23H
	DEC	C
	JP	NZ,SCRL2
	LD	DE,14
	ADD	HL,DE
	EX	DE,HL
	ADD	HL,SP
	LD	SP,HL
	EX	DE,HL
	DEC	B
	JP	NZ,SCRL1
	LD	HL,(TMPSTK)
	LD	SP,HL
	POP	BC
	POP	DE
	POP	HL
	RET
ELSE
IFDEF VDP_TEXT_SCROLL
IF 1
	PUSH	HL
	LD	HL,(SYMADR)
	LD	A,(CURSYM)
	CALL	WriteHL2
	LD	HL,ScrollRegs
	CALL	T_SetRegs
	POP	HL
	;while (VDPST & 1);    // wait for 9938 status to be idle
	LD	BC,0
SC01:
	INC	BC
	IN	A, (VDP+1)
	AND	1
	JP	NZ, SC01


	;VDP_SET_REGISTER(0x0f,0); // status register to read = SR0
	LD	BC,0F00h
	JP	T_WriteRegValue

ScrollRegs:
	DB	34,1
	DB	38,0
	DB	42,29
	DB	46,0E0h
	DB	0Fh,2
	DB	0FFh
ELSE
	;PUSH	BC
	PUSH	HL
	LD	B, T_REG_SCROLL_Y
	LD	HL, ScrollLine
	INC	(HL)
	LD	A, SCR_HEIGHT
	CP	(HL)
	JP	NZ, $+5
	LD	(HL), 0
	LD	C, (HL)
	CALL	T_WriteRegValue
	POP	HL
	;POP	BC
	
	LD	A, (ScrollLine)
	OR	A
	JP	NZ, $+5
	LD	A, SCR_HEIGHT
IF 1
	DEC	A
	;PUSH	BC
	LD	L, A
	LD	H, 0
	ADD	HL, HL
	ADD	HL, HL
	ADD	HL, HL
	ADD	HL, HL
	LD	C, L
	LD	B, H
	ADD	HL, HL
	ADD	HL, HL
	ADD	HL, BC
	;POP	BC
	;JP	DL02
ELSE
	LD	HL, 0
DL01:
	DEC	A
	JP	Z, DL02
	PUSH	AF
	CALL	NXT_S
	POP	AF
	JP	DL01
ENDIF
DL02:
	;PUSH	BC
	PUSH	DE
	LD	BC, SCR_WIDTH
	LD	DE,4Fh
	CALL	T_FillWord
	POP	DE
	;POP	BC
	RET
ENDIF
ELSE
	PUSH	HL
	PUSH	DE
	PUSH	BC

	LD	BC, T_R1_MODE_TEXT OR T_R1_DISP_ACTIVE OR T_R1_INC_ONE OR (T_REG_1 SHL 8) 
	CALL	T_WriteRegValue

	LD	HL,(SYMADR)
	LD	A,(CURSYM)
	CALL	WriteHL2
	LD	HL,0;//LHLD	BEGSCR
	LD	B, SCR_HEIGHT-1
DL01:
	PUSH	BC
	LD	D,H
	LD	E,L
	CALL	NXT_S
	PUSH	HL
	PUSH	DE

	PUSH	DE
	EX	DE,HL
	LD	HL,STRBUF
	LD	B, SCR_WIDTH; * 2
	CALL	T_ShAddrReadBytes
	POP	DE
	LD	B, SCR_WIDTH; * 2
	CALL	T_ShAddrWriteBytes
	POP	DE
	POP	HL
	POP	BC
	DEC	B
	JP	NZ,DL01


	LD	BC, SCR_WIDTH/2
	;EX	DE,HL
	LD	DE,0;4Fh
	CALL	T_FillWord

	LD	BC, T_R1_MODE_TEXT OR T_R1_DISP_ACTIVE OR (T_REG_1 SHL 8)
	CALL	T_WriteRegValue

	POP	BC
	POP	DE
	POP	HL
	RET
ENDIF
; +--------------------+
; |0                   |
; |1                   |
; |2                   |
; |3                   |
; |4                   |
; +--------------------+


ENDIF
; ??????????????????????????????????????????????


  if	$ ge	1 AND $ le ORGB+1800h
	if1
	  .printx * Code length over 2048 bytes ! *
	endif
	@OVER	EQU	$
  endif

  	rept	800H
	if	$ ne ORGB+2000H
		defb	255
	endif
	endm

	.dephase

	END

