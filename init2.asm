; ���� ��������� ��������� ����������������
; �����������
	.phase 0E000h
PROG_PAGE	EQU	0FE00h
	jmp ON_DC
	JMP	LOOP
ON_DC:	MVI A,24H;  �������� ����� ���������� ����������������
	OUT -1;     ���������� ���������
	;OUT -1;     ���������� ��� � ��������� �������� FF00H�FFFFH 
	OUT 0E0h
	;OUT 0E1h
	;OUT 0E2h
	;OUT 0E3h
	;OUT 0E4h


	MVI A,10;   ����� ����� ������ �������� ���
	OUT 0FEH;   �������� FE00H�FEFFH ��������� � ����� ���
	MVI A,0A4H; �������� ����� ������������������
	OUT -1;     ���������� ���������, �������� �������
	      ;     ������ ������� ��� ��������� ��������
	;MVI	A,11
	;OUT	0CEh
	;MVI	A,80h
	;STA	0CE00h

	;MVI	A,10
	;OUT	0B5h

	MVI C,ENDPRO-BEGPRO ; ����������� � �������������
	LXI H,PROG_PAGE;      ��������, ���������� ��� ���,
	LXI D,BEGPRO;         ��������� ��� ������� ����������������
	LDAX D;               ���� ���������� ��������� ����
	MOV M,A
	INX H
	INX D
	DCR C
	JNZ $-5 ;
	LXI SP,PROG_PAGE+0100H; ���������� ��������� ����� � ��������
	LXI H,PROG_PAGE+1 ; ��������, �������� � hl ����� ��������
		     ; ������� out ��� ����������� ����������
		     ; �������� � out 00
	LXI	D,MAP
	CALL	LOOP

	MVI A,0A4H  ; � ������ ������������������
	OUT -1      ; ���������� ��������� ���������
	OUT -2      ; �������� FE00-FEFF � ����� ���
	MVI A,84H   ; �������� ������� �����
	OUT -1
	MVI A,80H   ; �������� � ��������� �������-���������
	OUT -1      ; ��������: ���������� ��������, �������
                    ; �������� ��������������� ���
	;lxi	h,0cc03h
	;mvi	m,36h
	;mvi	m,76h
	;mvi	m,0b6h

	JMP 0F800h  ; ������� � ���������������� ������������ ��
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

MAP:	DB	80h,5,40h,10
	DB	2,2,2,0,2,1,2,7,2,8,2,10,2,6,2,11
	DB	8,10,8,13,30,4,0
	
	END













