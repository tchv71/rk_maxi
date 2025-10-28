; SD BIOS for Computer "Radio 86RK" / "Apogee BK01"
; (c) 09-10-2014 vinxru (aleksey.f.morozov@gmail.com)

	.phase 0h

MONITOR		equ 0F86Ch	; @dpeq qnap`r` b Lnmhrnp
USER_PORT	 equ 0C400H	; @dpeq JP580BB55
SEND_MODE	 equ 10000000b ; Pefhl oeped`wh (1 0 0 A QH 0 B CL)
RECV_MODE	 equ 10010000b ; Pefhl ophel` (1 0 0 A QH 0 B CL)

; Jnd{ oeped`b`el{e lhjpnjnmrpnkkepnl

ERR_START	 equ 040h ; LJ oepejk~wem b pefhl ophel` jnl`md
ERR_WAIT		equ 041h ; LJ b{onkmer jnl`mds
ERR_OK_DISK	equ 042h ; M`jnohrek| hqop`bem, lhjpnjnmrpnkkep cnrnb j ophels jnl`md{
ERR_OK		equ 043h ; Jnl`md` b{onkmem`
ERR_OK_READ	equ 044h ; LJ cnrnb oeped`r| qkeds~yhi aknj d`mm{u
ERR_OK_ADDR	equ 047h ; LJ cnrnb oeped`r| `dpeq g`cpsgjh
ERR_OK_BLOCK	equ 04Fh 

;----------------------------------------------------------------------------
; Rnwj` bund`

Entry:
	; Oepb{l }r`onl opnhqundhr qhmupnmhg`vh q jnmrpnkkepnl
	; 256 ono{rnj. Dk }rncn b pechqrp C g`mnqhrq 0
	MVI	C, 0

Boot:
	; Pefhl oeped`wh (nqbnanfd`el xhms) h hmhvh`khghpsel HL
	CALL	RecvMode

	JMP	Boot2

;----------------------------------------------------------------------------
; Nrop`bj` h ophel a`ir` (b HL dnkfem m`undhrq USER_PORT)

Rst1:
	; Xhm` `dpeq` hqonk|gserq j`j r`jrnb{i qhcm`k
	INX	H
	MVI	M, 20h
	MVI	M, 0
	DCX	H
	; Ophel a`ir`
	MOV	A, M
	RET

;----------------------------------------------------------------------------
; Nfhd`mhe cnrnbmnqrh LJ

Rst2:
WaitForReady:
	Rst	1
	CPI	ERR_WAIT
	JZ	WaitForReady
	RET

;----------------------------------------------------------------------------

	; M`w`kn k~ani jnl`md{ (}rn xhm` `dpeq`)
Boot2:
	INR	L
	MVI	M, 0
	MVI	M, 44h
	MVI	M, 40h
	MVI	M, 0h
	DCR	L

	; Eqkh eqr| qhmupnmhg`vh, rn jnmrpnkkep nrberhr ERR_START on xhme d`mm{u
	Rst	1
	CPI	ERR_START
	JNZ	RetrySync

	; Hmhvh`khg`vh tkexjh
	Rst	2
	CPI	ERR_OK_DISK
	JMP	Skip
	DS	6
Skip:
	JNZ	RetrySync
	; Pefhl oeped`wh	
	Rst	1	
	MVI	A, SEND_MODE
	CALL	SetMode

	; Jnd jnl`md{ BOOT
	MVI	M, 0
	Rst	1

	; Pefhl ophel`
	CALL  RecvMode

	; ]rn nrber jnl`md{ BOOT
	Rst	2
	CPI	ERR_OK_ADDR
	JNZ	RetrySync
	
	; @dpeq g`cpsgjh b BC
	Rst	1
	MOV	C, A
	Rst	1
	MOV	B, A

	; Qnup`mel b qrej `dpeq g`osqj`
	PUSH	B

	; T`ik lnfer a{r| p`gahr m` meqjnk|jn w`qrei
RecvLoop:
	; Bqe w`qrh g`cpsfem{, lnfmn g`osqj`r| t`ik.
	Rst	2
	CPI	ERR_OK_READ
	JZ	rst11

	; Eqkh LJ opnwhr`k aknj aeg nxhanj, asder oeped`m ERR_OK_BLOCK
	CPI	ERR_OK_BLOCK
	JNZ	PrintError

	; P`glep aknj` d`mm{u
	Rst	1
	MOV	E, A
	Rst	1
	MOV	D, A

	; Ophmhl`el aknj d`mm{u
RecvBlock:
	MOV	A, E
	ORA	D
	JZ	RecvLoop
	Rst	1
	STAX	B
	INX	B
	DCX	D
	JMP	RecvBlock

;----------------------------------------------------------------------------
; Onbrnpm{e ono{jh

RetrySync:
	; Ono{rjh
	DCR	C
	JNZ	Boot

;----------------------------------------------------------------------------
; B{bnd jnd` nxhajh

PrintError:
	CALL	0F815h
	JMP	MONITOR

;----------------------------------------------------------------------------
; Sqr`mnbj` pefhl` ophel` hkh oeped`wh

RecvMode:
	MVI	A, RECV_MODE

SetMode:
	LXI	H, USER_PORT+3
	MOV	M, A
	MVI	L, 0
	RET
rst11:
	JMP	8
	End
