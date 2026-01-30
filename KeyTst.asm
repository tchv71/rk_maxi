Line	equ	1Bh
PPI	EQU	0C100h
VDP	EQU	98h

	LXI	H, KEYBOARD
	CALL	0F818h

IF 0
	LXI	h,4
	MVI	E,12
lp01:
	MOV	A, L
	OUT	VDP+1
	MOV	A, H
	ORI	40h
	OUT	VDP+1
	MVI	A,Line
	OUT	VDP
	LXI	B,33
	DAD	B
	MOV	A, L
	OUT	VDP+1
	MOV	A, H
	ORI	40h
	OUT	VDP+1
	MVI	A,Line
	OUT	VDP
	MVI	B,80-33
	DAD	B
	DCR	E
	JNZ	lp01
ENDIF


Again:
	;JMP	ScanPortC
	LXI	H,87Fh
	LXI	B, 3000h + 3 * 80 + 5;
LoopRow:
	MOV	A,L
	STA	PPI
	LDA	PPI+1
	MOV	E, A
	MVI	D,80h

	PUSH	H
	PUSH	B
	MOV	A, C
	OUT	VDP+1
	MOV	A, B
	ORI	40h
	OUT	VDP+1
	MVI	B, 8
LoopCol:
	MOV	A, E
	ANA	D
	MVI	A, 0F1h
	JNZ	$+5
	MVI	A,1Fh
	MVI	C,4
l01:
	OUT	VDP
	DCR	C
	JNZ	l01
	MOV	A,D
	RRC
	MOV	D,A
	DCR	B
	JNZ	LoopCol
	POP	H
	LXI	B,80
	DAD	B
	MOV	B,H
	MOV	C,L
	POP	H
	MOV	A,L
	RRC
	MOV	L,A
	DCR	H
	JNZ	LoopRow

ScanPortC:
	;MVI	A,7Fh
	;STA	PPI
	LXI	D, 3000h+13*80
	LXI	H,320h
	LDA	PPI+2
	MOV	B, A
l02:

	MOV	A,B
	ANA	L
	MVI	A, 01Fh
	JZ	l04
	MOV	A,H
	CPI	3
	MVI	A,0F1h
	JNZ	l04
	PUSH	PSW
	PUSH	B
	CALL	0f815h
	MVI	C,8
	CALL	0F809h
	CALL	0F809h
	POP	B
	POP	PSW

l04:
	PUSH	PSW
	MOV	A, E
	OUT	VDP+1
	MOV	A, D
	ORI	40h
	OUT	VDP+1
	POP	PSW
	MVI	C,6
l03:
	OUT	VDP
	DCR	C
	JNZ	l03
	PUSH	H
	LXI	H,80
	DAD	D
	XCHG
	POP	H
	MOV	A,L
	RLC
	MOV	L,A
	DCR	H
	JNZ	l02

	JMP	Again

Keyboard:
	DB	1fh
	DB	" ---+--------------------------------+",13,10
	DB	"    ! D7  D6  D5  D4  D3  D2  D1  D0 !",13,10
	DB	" ---+--------------------------------+",13,10
	DB	" A7 !SPC  ^   ]   \   [   Z   Y   X  !",13,10
	DB	" A6 ! W   V   U   T   S   R   Q   P  !",13,10
	DB	" A5 ! O   N   M   L   K   J   I   H  !",13,10
	DB	" A4 ! G   F   E   D   C   B   A   @  !",13,10
	DB	" A3 ! /   .   =   ,   ;   :   9   8  !",13,10
	DB	" A2 ! 7   6   5   4   3   2   1   0  !",13,10
	DB	" A1 !    ->   ^  <-  zab wk  ps  TAB !",13,10
	DB	" A0 ! F5  F4  F3  F2  F1 AP2 CTP  \  !",13,10
	DB	" ---+--------------------------------+",13,10
	DB	10,13
	DB	"SHIFT",13,10
	DB	"CTRL", 13,10
	DB	"RUSlat",13,10
	DB	0

	END
