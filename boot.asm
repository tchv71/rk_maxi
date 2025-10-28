; SD BIOS for Computer "Radio 86RK" / "Apogee BK01"
; (c) 09-10-2014 vinxru (aleksey.f.morozov@gmail.com)

	.phase 0h

MONITOR		equ 0F86Ch	; ����� ������� � �������
USER_PORT	 equ 0C400H	; ����� ��580��55
SEND_MODE	 equ 10000000b ; ����� �������� (1 0 0 A �H 0 B CL)
RECV_MODE	 equ 10010000b ; ����� ������ (1 0 0 A �H 0 B CL)

; ���� ������������ �����������������

ERR_START	 equ 040h ; �� ���������� � ����� ������ ������
ERR_WAIT		equ 041h ; �� ��������� �������
ERR_OK_DISK	equ 042h ; ���������� ��������, ��������������� ����� � ������ �������
ERR_OK		equ 043h ; ������� ���������
ERR_OK_READ	equ 044h ; �� ����� �������� ��������� ���� ������
ERR_OK_ADDR	equ 047h ; �� ����� �������� ����� ��������
ERR_OK_BLOCK	equ 04Fh 

;----------------------------------------------------------------------------
; ����� �����

Entry:
	; ������ ������ ���������� ������������� � ������������
	; 256 �������. ��� ����� � ������� C ��������� 0
	MVI	C, 0

Boot:
	; ����� �������� (����������� ����) � �������������� HL
	CALL	RecvMode

	JMP	Boot2

;----------------------------------------------------------------------------
; �������� � ����� ����� (� HL ������ ��������� USER_PORT)

Rst1:
	; ���� ������ ������������ ��� �������� ������
	INX	H
	MVI	M, 20h
	MVI	M, 0
	DCX	H
	; ����� �����
	MOV	A, M
	RET

;----------------------------------------------------------------------------
; �������� ���������� ��

Rst2:
WaitForReady:
	Rst	1
	CPI	ERR_WAIT
	JZ	WaitForReady
	RET

;----------------------------------------------------------------------------

	; ������ ����� ������� (��� ���� ������)
Boot2:
	INR	L
	MVI	M, 0
	MVI	M, 44h
	MVI	M, 40h
	MVI	M, 0h
	DCR	L

	; ���� ���� �������������, �� ���������� ������� ERR_START �� ���� ������
	Rst	1
	CPI	ERR_START
	JNZ	RetrySync

	; ������������� ������
	Rst	2
	CPI	ERR_OK_DISK
	JMP	Skip
	DS	6
Skip:
	JNZ	RetrySync
	; ����� ��������	
	Rst	1	
	MVI	A, SEND_MODE
	CALL	SetMode

	; ��� ������� BOOT
	MVI	M, 0
	Rst	1

	; ����� ������
	CALL  RecvMode

	; ��� ����� ������� BOOT
	Rst	2
	CPI	ERR_OK_ADDR
	JNZ	RetrySync
	
	; ����� �������� � BC
	Rst	1
	MOV	C, A
	Rst	1
	MOV	B, A

	; ��������� � ���� ����� �������
	PUSH	B

	; ���� ����� ���� ������ �� ��������� ������
RecvLoop:
	; ��� ����� ���������, ����� ��������� ����.
	Rst	2
	CPI	ERR_OK_READ
	JZ	rst11

	; ���� �� �������� ���� ��� ������, ����� ������� ERR_OK_BLOCK
	CPI	ERR_OK_BLOCK
	JNZ	PrintError

	; ������ ����� ������
	Rst	1
	MOV	E, A
	Rst	1
	MOV	D, A

	; ��������� ���� ������
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
; ��������� ������

RetrySync:
	; �������
	DCR	C
	JNZ	Boot

;----------------------------------------------------------------------------
; ����� ���� ������

PrintError:
	CALL	0F815h
	JMP	MONITOR

;----------------------------------------------------------------------------
; ��������� ������ ������ ��� ��������

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

