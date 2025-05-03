; ���� ��������� ��������� ����������������
; �����������
	.phase 0e000h
PROG_PAGE	EQU	0FE00h
	jmp ON_DC
	JMP	LOOP
ON_DC:
	IN	-1	; ������������ ������ ����� ������� ���������� ��������

	MVI	A,20H	; �������� ����� ���������� ����������������
	OUT	-1		; ���������� ���������

	MVI	A,4	; �������� ��� E000H-E0FFH
	OUT	0E0h

	MVI A,13+10h	; ����� ����� ������ �������� ���
	OUT 0FEH	; �������� FE00H�FEFFH ��������� � ����� ���

	IN	-1	; ������������ ������ ����� ������� ���������� ��������
	MVI	A,80H	; �������� � ��������� �������-���������
	OUT	-1	; ��������

	MVI C,ENDPRO-BEGPRO	; ����������� � �������������
	LXI H,PROG_PAGE		; ��������, ���������� ��� ���,
	LXI D,BEGPRO		; ��������� ��� ������� ����������������
	LDAX D			; ���� ���������� ��������� ����
	MOV M,A
	INX H
	INX D
	DCR C
	JNZ $-5 ;

	IN	-1
	MVI	A,0C0h
	OUT	-1

	LXI SP,PROG_PAGE+0100H	; ���������� ��������� ����� � ��������
	LXI	H,PROG_PAGE+1	; ��������, �������� � hl ����� ��������
	XRA	A
	MOV	M,A
	MOV	B,A
	MVI	A,15
	CALL	PROG_PAGE

	IN	-1	; ������������ ������ ����� ������� ���������� ��������
	MVI	A,0A0H	; �������� ����� ������������������
	OUT	-1	; ���������� ���������, �������� �������
			; ������ ������� ��� ��������� ��������

	LXI H,PROG_PAGE+1
				; ������� out ��� ����������� ����������
				; �������� � out 00
	LXI	D,MAP
	CALL	LOOP

	MVI	A,4
	OUT	-2
	OUT	-1

	IN	-1	; ������������ ������ ����� ������� ���������� ��������
	MVI	A,80H	; �������� � ��������� �������-���������
	OUT	-1	; ��������

	; �������� ������������ ������ ��� CP/M
	; Ctrl - ������
	; Shift - CP/M
	LXI	SP,0D800H
	MVI	A,90h
	STA	0C403h
	MVI	A,8Ah
	STA	0C203H
	LDA	0C202H
	ANI	060H
	MOV	C,A
	ANI	040H
	LXI	D,APOGEE
	JZ	LOAD
	MOV	A,C
	ANI	20H
	LXI	D,CPM
	JNZ	INTR_INIT

LOAD:
	MVI	A,3
	PUSH	D
	CALL	0F003H
	POP	D
	JNZ	INTR_INIT ; ���������������� ����������
	CALL	EXEC_A
	; ���������� ����� ��� ���� ����� �� ������
	JMP	INTR_INIT ; 

EXEC_A:
	PUSH	H
	MVI	A,0
	XCHG
	LXI	D,EMPTY
	RET

BEGPRO:
	OUT 0
	INR M
	DCR B
	RZ
	JMP PROG_PAGE
ENDPRO:
LOOP:
	LDAX	D
	ORA	A
	RZ
	MOV	B,A
	INX	D
	LDAX	D
	INX	D
	CALL	PROG_PAGE
	JMP	LOOP
; ���� �����������:
; 0	- 0C200h - ��55 - 1
; 1	- 0C400h - ��55 - 2
; 2	- 0C000h - ��75
; 3	-	Memory R/O
; 4	-	ROM
; 5	-	Memory < 32K
; 6	- 0CC00h - ��53 - 1
; 7	- 0C600h - ��57
; 8	- 0C800h - ��53 - 2
; 9	- 0C100h - SD_CNTR - ���������� SD-��������
;10	-	�� RAM
;11	- 0CE00h - ��9 (Palmira Control Byte)
;12	- 0C300h - 
;13	-	Memory >= 32K
;14	- 0CA00h - VDP TMS9918A
;15	- 0F700h - RK60K Ports
MAP:	DB	1,5,3fh,5,40h,15h,40h,13
	DB	1,2  ; 0C000h - ��75
	DB	1,9  ; 0C100h - SD_CNTR - ���������� SD-��������
	DB	2,0  ; 0C200h - ��55 - 1
	DB	2,1  ; 0C400h - ��55 - 2
	DB	2,7  ; 0C600h - ��57
	DB	2,8  ; 0C800h - ��53 - 2
	DB	2,14 ; 0CA00h - VDP TMS9918A
	DB	2,6  ; 0CC00h - ��53 - 1
	DB	2,11 ; 0CE00h - ��9  (Palmira Control Byte)
	DB	8,13+10h,8,10,30,4,0
APOGEE:
	DB	"APOGEE.RKL"
EMPTY:	DB	0
CPM:	DB	"CPM/CPM.RKL",0

INTR_INIT:
	LXI     H,E0F8
	LXI     D,38h
	MVI     C,07
E0CD:	MOV     A,M
	STAX    D
	INX     H
	INX     D
	DCR     C
	JNZ     E0CD
	.Z80
	im	1
	.8080
	JMP     0F800h
E0F8:
	PUSH    PSW
	LDA     0C001h
	POP     PSW
	EI      
	RET     


	DS	0E100H-$
	END













