; ���� ��������� ��������� ����������������
; �����������
ON_DC:	MVI A,24H;  �������� ����� ���������� ����������������
	OUT -1;     ���������� ���������
	OUT -1;     ���������� ��� � ��������� �������� FF00H�FFFFH 
	MVI A,5;    ����� ����� ������ ��������� ���
	OUT 0FEH;   �������� FE00H�FEFFH ��������� � ����� ���
	MVI A,0A4H; �������� ����� ������������������
	OUT -1;     ���������� ���������, �������� �������
	      ;     ������ ������� ��� ��������� ��������
	MVI C,ENDPRO-BEGPRO ; ����������� � �������������
	LXI H,0FE00H;         ��������, ���������� ��� ���,
	LXI D,BEGPRO;         ��������� ��� ������� ����������������
	LDAX D;               ���� ���������� ��������� ����
	MOV M,A
	INX H
	INX D
	DCR C
	JNZ $-5 ;
	LXI SP,0FEFFH; ���������� ��������� ����� � ��������
	LXI H,0FE02H ; ��������, �������� � hl ����� ��������
		     ; ������� out ��� ����������� ����������
		     ; �������� � out 00
	MVI B,80H    ; � - �������, � � ����� ����� ������
	MVI A,5
	CALL 0FE00H  ; ������ 0000�7FFF � ���
	MVI B,20H    ; ���������� ����������
	XRA A
	CALL 0FE00H  ; ������ 8000-9FFF � D20
	MVI B,20H    ; ���������� ������������� ������������
	INR A
	CALL 0FE00H  ; ������ A000�BFFF - D14
	MVI B,20H    ; ���������� ����������
	INR A
	CALL 0FE00H  ; ������ C000 � DFFF - D8
	MVI B,8H     ; ���������� ��� ��� ������� ��� ���
	INR A        ; ����������� ����
	CALL 0FE00H  ; ������ E000 -E7FF
	MVI B,8H     ; ������� ��� ��� ����������� ����
	MVI A,7
	CALL 0FE00H  ; ������ E800-EFFF
	INR A; A=8     ���� � ������� ������ ������ �����������
	OUT 0F0H     ; ������ F000-F0FF
	INR M        ; ������� ��� � ��������� F100-F7FF
	MVI A,5
	MVI B,7
	CALL 0FE00H
	MVI B,6H     ; ��� "���������� ��������"
	MVI A,4
	CALL 0FE00H  ; ������ f800-ffff

; ���������������� ������� ��������� ��� �����������
; ������ dos, ��� ��� ������������ ������� ������������
; ���������� ������� in � out
EQUP:	MVI A,0C4H  ; �������� ����� ������������������
	OUT -1      ; ������� ���������
	MVI A,8
	MVI B,5
	MVI M,0F0H  ; ���������������� ������ ����������� ����
	CALL 0FE00H ; 0F0�,0F1͂0F2�,0F3� � 0F4�
	MVI A,2     ; ���������������� ����� �����������
	OUT 0C1H    ; �������
	MVI A,0A4H  ; � ������ ������������������
	OUT -1      ; ���������� ��������� ���������
	OUT -2      ; �������� FE00-FEFF � ����� ���
	MVI A,84H   ; �������� ������� �����
	OUT -1
	MVI A,80H   ; �������� � ��������� �������-���������
	OUT-1       ; ��������: ���������� ��������, �������
                    ; �������� ��������������� ���
;	JMP BEGIN1  ; ������� � ���������������� ������������ ��
BEGPRO:
	OUT 0
	INR M
	DCR B
	RZ
	JMP 0FE00H
ENDPRO:

	
	END













