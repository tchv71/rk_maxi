	.phase 100h
BUFF	EQU	1000h
	IN	-1
	MVI	A,0A0H
	OUT	-1
	LXI	H,0E000h
	MOV	A,H
	STA	BEGPRO+1
	MVI	C,20h
PAGE_LOOP:
	LXI	D,BUFF
	MVI	B,0
PL01:
	MOV	A,M
	STAX	D
	INX	H
	INX	D
	DCR	B
	JNZ	PL01

	MVI	A,10
PL03:	CALL	BEGPRO

	DCR	D
	DCR	H
	; B is surely 0
PL02:
	LDAX	D
	MOV	M,A
	INX	H
	INX	D
	DCR	B
	JNZ	PL02
	DCR	C
	JNZ	PAGE_LOOP
	IN	-1
	MVI	A,80h
	OUT	-1
	JMP	0F86Ch
	
BEGPRO:
	OUT	0E0H
	LDA	BEGPRO+1
	INR	A
	STA	BEGPRO+1
	RET

	END
