;build with z80asm -b test-z88dk.asm
	;org 0100h
	.z80
setup:
reg_p	equ 0a0h ;= 0xd8
data_p	equ 0a1h ; = 0xd0

	in	a,(0ffh)
	ld	a,0c0h
	out	(0ffh),a

	ld	a, 8
	out (0a0h),a
	out (0a1h),a
	out (0a2h),a

	in	a,(0ffh)
	ld	a,81h
	out	(0ffh),a

repeat:
	ld	a, 7
	out	(REG_P), a	;select the mixer register
	ld	a, 3eh
	out	(DATA_P),a	; enable channel A only
	ld	a, 8
	out	(REG_P),a	; channel A volume
	ld	a, 15
	out	(DATA_P),a	; set it to maximum
	ld	a, 0
	out	(REG_P),a	; select channel A pitch
	call	reset

	ld	a, 7
	out	(REG_P), a	;select the mixer register
	ld	a, 3dh;62
	out	(DATA_P),a	; enable channel B only
	ld	a, 9;8
	out	(REG_P),a	; channel B volume
	ld	a, 15
	out	(DATA_P),a	; set it to maximum
	ld	a, 2;0
	out	(REG_P),a	; select channel B pitch
	call	reset

	; Channel C
	ld	a, 7
	out	(REG_P), a	;select the mixer register
	ld	a, 3Bh;62
	out	(DATA_P),a	; enable channel C only
	ld	a, 10;8
	out	(REG_P),a	; channel C volume
	ld	a, 15
	out	(DATA_P),a	; set it to maximum
	ld	a, 4;0
	out	(REG_P),a	; select channel Ñ pitch
	call	reset


	jp	repeat

reset:
	ld	b, 255
loop:
	ld	a, b
	out	(DATA_P),a	; set it
	call	pause
	dec	b
	;jp	nz, loop
	;jp	reset
	ret

pause:
	CALL	0f803h
	ret
;	push	bc
;	push	de
;	push	af
;	
;	ld	bc,1500h	;loads bc with hex 1000
;	; outer: ld de, $1000	;loads de with hex 1000
;	; inner: dec de		;decrements de
;	; ld a, d		;copies d into a
;	; or e			;bitwise or of e with a (now, a = d | e)
;	; jp nz, inner		;jumps back to inner: label if a is not zero
;outer:
;	dec	bc		;decrements bc
;	ld	a, b		;copies b into a
;	or	c		;bitwise or of c with a (now, a = b | c)
;	jp	nz, outer	;jumps back to outer: label if a is not zero
;
;	pop	af
;	pop	de
;	pop	bc
;	ret			;return from call to this subroutine

	end
