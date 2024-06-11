; IN and OUT MACRO comands
@in	MACRO	addr
IF ((addr) LT 256)
	in	addr
ELSE
	lda	addr
ENDIF
	ENDM

@out	MACRO	addr
IF ((addr) LT 256)
	out	addr
ELSE
	sta	addr
ENDIF
	ENDM

;************ Controller's mapping ****************
_PPI	equ	000h;  8255 first		  *
_PPI2	equ	010h;  8255 second	   	  *
_DISP	equ	020h;  8275 display adapter	  *
_DMA	equ	030h;  8257 DMA chip	    	  *
_PSG1	equ	040h;  8253 first	          *
_PALM_CNTRL equ	0c0h;  Palmira control byte       *
;************ Controller's mapping ****************
PSG1	equ	0CC00h;  8253 first	          *
PPI	equ	0C200h;  8255 frist		  *
PPI2	equ	0C400h;  8255 second	   	  *
DISP	equ	0C000h;  8275 display adapter	  *
DMA	equ	0C600h;  8257 DMA chip	    	  *
PALM_CNTRL equ	0CE00h;  Palmira control byte     *
;**************************************************
PHYS_W		EQU	78
PHYS_H  	equ	29+1
SCR_BUFF	EQU	0b6d0h

@SYSREG	MACRO	VAL
	IN	-1
	MVI	A,VAL
	OUT	-1
	ENDM

	LXI	SP,100h

	;@SYSREG	0C0h ; Turn on external device programming mode (for in/out commands)
	;LXI	H,BEGPRO+1
	;LXI	B,00000h
	;MVI	A,15
	;CALL	SETPORT
	;CALL	LOOP01 ; Turn on working mode

	MVI	A,0;80H ; Start page
	LXI	D,MAP
	CALL	PROG_DC
	@SYSREG	80h
	
IF 1
	@SYSREG	0C0h ; Turn on external device programming mode (for in/out commands)

	LXI	H,BEGPRO+1

	LXI	B,400h + _PPI
	XRA	A
	CALL	SETPORT

	LXI	B,400h + _PPI2
	INR	A
	CALL	SETPORT

	INR	A
	OUT	_DISP
	OUT	_DISP+1

	LXI	B,1000h + _DMA	; DMA
	MVI	A,7
	CALL	SETPORT

	MVI	A,6	; PSG
	LXI	B,400h + _PSG1
	CALL	SETPORT

	MVI	A,11
	OUT	_PALM_CNTRL
ENDIF
	@SYSREG	80h
	MVI	A,8AH
	@out	PPI+3
	CALL	SETSCR
	JMP	0F86Ch

CP001:
	MOV	A,B
	ORA	C
	RZ
	MOV	A,M
	STAX	D
	INX	H
	INX	D
	DCX	B
	JMP	CP001


; A - value
; C - port number
; B - count
SETPORT:
	MOV	M,C
BEGPRO:
	OUT 0
	INR M
	DCR B
	RZ
	JMP BEGPRO

PROG_DC:
	PUSH	PSW
	@SYSREG	0A0H;  ¬ключить режим репрограммировани€  внутренних устройств
	POP	PSW
	LXI H,BEGPRO+1 ; «аписать в hl адрес операнда
		     ; команды out дл€ обеспечени€ инкремента
		     ; начинаем с out 80H
	MOV	M,A
LOOP:
	LDAX	D
	ORA	A
	JZ	LOOP01
	MOV	B,A
	INX	D
	LDAX	D
	INX	D
	CALL	BEGPRO
	JMP	LOOP
LOOP01:
	@SYSREG	80H	; «аписать в системный регистр-начальные
			; значени€: турборежим выключен, нулева€
			; страница дополнительного озу
	RET

IF 0
MAP:
	DB	80h,5
	DB	58h,10
	DB	8,10
	DB	18h,10
	DB	8,10
	DB	0
ELSE
MAP:	DB	80h,5,40h,10
	DB	2,2,2,0,2,1,2,7,2,8,2,10,2,6,2,11
	DB	8,10,8,13,32,4,0
ENDIF

	; *****	B1DISPB.ASM - Display parameter block *********

S	equ	0b	; All/Odd lines to display    (0/1)
VV	equ	01b	; Frame reverse time:   00 - 1 T_Row
;						01 - 2 T_Row
;						02 - 3 T_Row
;						03 - 4 T_Row
UUUU	equ	16-1	; Cursor scan line number     (1..16)
LLLL	equ	16-1	; Number of scan lines/symbol (1..16)
@M	equ	0	; Count lines 0 -  from 0  ; 1 - from 1
@F	equ	1	; Display ctrl symbols : 0 - as space
CC	equ	01	; Cursor style 		      (0..3)
;						 1 - no display
	IFDEF CONSOLE80
ZZZZ	equ	09h	; Horizontal RVV time
	ELSE
ZZZZ	equ	08h	; Horizontal RVV time
	ENDIF

Disp_PB::	db	S*128+PHYS_W-1
		db	VV*64+PHYS_H-1	; Display parameters
		db	UUUU*16+LLLL
		db	@M*128+@F*64+CC*16+ZZZZ
		dw	SCR_BUFF,PHYS_W*PHYS_H-1; DMA parameters

; Set a screen mode according to Disp_PB
SETSCR::
	PUSH	H
	PUSH	B

; *** Load 8275 controller ****

	XRA	A
	@OUT	_DISP+1	; Stop displaying

	MVI	C,4
	lxi	h,Disp_PB	; Display parameter block
	rept	4
		mov	a,m
		inx	h
		@out	_DISP
	endm

	mvi	a,27H
	@out	_DISP+1
	@in	_DISP+1	; Clear RVV flag
@wait_RVV:
	@in	_DISP+1	; Wait RVV signal
	ANI	20H
	JZ	@wait_RVV

;*** Load 8257 controller ***
	@in	_DMA+0Fh
	inr	a
	jz	VT37
	mvi	a,80h
	@out	_DMA+8	; Control register

	rept	2
		mov	a,m
		@out	_DMA+4	; Load channel 3
		inx	h
	endm

	mov	a,m
	@out	_DMA+5
	inx	h
	mov	a,m
	ori	40h
	@out	_DMA+5
	mvi	a,0a4h
	@out	_DMA+8
	POP	B
	POP	H
	RET
VT37:
	XRA	A
	@out	_DMA+0Dh
	rept	2
		mov	a,m
		@out	_DMA+4	; Load channel 2
		inx	h
	endm
	rept	2
		mov	a,m
		@out	_DMA+5
		inx	h
	endm
	mvi	a,1Ah
	@out	_DMA+0Bh
	mvi	a,8
	@out	_DMA+8
	mvi	a,0bh
	@out	_DMA+0Fh
	POP	B
	POP	H
	RET

	end
