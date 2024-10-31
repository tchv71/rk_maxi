; SD BIOS for Computer "Radio 86RK"
; (c) 09-10-2014 vinxru (aleksey.f.morozov@gmail.com)
; (c) 24-10-2024 tchv aka Dmitry Tsvetkov (tchv71@mail.ru)

     .phase 8000h;0D600h-683-9Bh-33h ; ��������� ���� ���� ������ ���� 0D5FFh
                       
;----------------------------------------------------------------------------

INIT_VIDEO      EQU  0F82DH
INIT_STACK      EQU  0D800h

STA_START       EQU 040h ; �� ���������� � ����� ������ ������
STA_WAIT        EQU 041h ; �� ��������� �������
STA_OK_DISK     EQU 042h ; ���������� ��������, ��������������� ����� � ������ �������
STA_OK_CMD          EQU 043h ; ������� ���������
STA_OK_READ     EQU 044h ; �� ����� �������� ��������� ���� ������
STA_OK_ENTRY    EQU 045h
STA_OK_WRITE	EQU 046h
STA_OK_ADDR     EQU 047h ; �� ����� �������� ����� ��������
STA_OK_BLOCK    EQU 04Fh 

VER_BUF         EQU  BUF

;----------------------------------------------------------------------------
; ��������� RK �����

     ;.db ($+2)>>8, ($+2)&0FFh
     
;----------------------------------------------------------------------------
	      
Entry:
     ; ������������� ������� ��������� ������
     ;LXI	H, SELF_NAME
     ;CALL	0F833h

     ; ����� �������� ����������� �� �����
     LXI	H, aHello
     CALL	0F818h

     ; ����� ������ �����������
     CALL	PrintVer

     ; ������� ������
     lxi	h, aCrLf
     CALL	0F818h

     ; ��������� ���� SHELL.RK ��� ��� ������
     LXI	H, aShellRk
     LXI	D, aEmpty
     CALL	CmdExec
     PUSH	PSW

     ; ������ - ���� �� ������
     CPI	04h
     JNZ 	Error2

     ; ����� ��������� "���� �� ������ BOOT/SHELL.RK"
     LXI	H, aErrorShellRk
     CALL	0F818h
     JMP	$

;----------------------------------------------------------------------------

PrintVer:
     ; ������� ��������� ������
     MVI	A, 1
     CALL	StartCommand	; ������ ���� � ������� ��������� ������
     CALL	SwitchRecv
     
     ; �������� ������ ������ ������ � �����
     ;LXI	D, VER_BUF
     CALL	Recv;Block2
          
     ; ����� ������ ������
     XRA	A
     STA    BUF_SIZE
     STA	VER_BUF+17+2
     LXI	H, VER_BUF+1+2
     JMP 	0F818h

;----------------------------------------------------------------------------

aHello:         db 13,10,"SD BIOS V1.1",13,10
aSdController:  db "SD DMA CONTROLLER ",0
aCrLf:          db 13,10,0
aErrorShellRk:  db "fajl ne najden "
aShellRk:       db "BOOT/SHELL.RK",0
                db "(c) 04-05-2014 vinxru, 2024 (c) tchv"

; ��� ���� ����� ������ ��� ������� � ���������� ������

SELF_NAME    EQU $-512 ; ���� (����� 256 ����)
CMD_LINE     EQU $-256 ; ���������� ������ 256 ����

;----------------------------------------------------------------------------
; ����������� ����� SD BIOS
;----------------------------------------------------------------------------

aError:    db "o{ibka SD "
aEmpty:    db 0

;----------------------------------------------------------------------------
; ��� ����������������� ��, ��� ����� ���� ��������� ��� ����

Error:     
     ; ������������� �����
     LXI	SP, INIT_STACK

     ; ��������� ��� ������
     PUSH	PSW

     ; ������� ������
     ; ������� ���� ������� �� ������� ������ ��� ���� �������, � �� ������ ���������
     MVI	C, 1Fh
     CALL	0F809h     
     ; � ������ ������������� ���������������
     CALL       INIT_VIDEO

Error2:
     ; ����� ������ "������ SD "
     LXI	H, aError
     CALL	0F818h

     ; ����� ���� ������
     POP	PSW
     CALL	0F815h

     ; ������
     JMP	$

;----------------------------------------------------------------------------

BiosEntry:
     PUSH   H
     LXI	H, JmpTbl
     ADD    A
     ADD	L
     MOV	L, A
     JNC    BE01
     INR    H
BE01:
     MOV    A,M
     INX    H
     MOV    H, M
     MOV    L, A
     XTHL
     RET

;----------------------------------------------------------------------------
; �������� JmpTbl �� ������� ���� � �������� ����� ��������

JmpTbl:
     dw CmdExec           ; 0 HL-��� �����, DE-��������� ������  / A-��� ������
     dw CmdFind           ; 1 HL-��� �����, DE-�������� ������ ��� ��������, BC-����� / HL-������� ���������, A-��� ������
     dw CmdOpenDelete     ; 2 D-�����, HL-��� ����� / A-��� ������
     dw CmdSeekGetSize    ; 3 B-�����, DE:HL-������� / A-��� ������, DE:HL-�������
     dw CmdRead           ; 4 HL-������, DE-����� / HL-������� ���������, A-��� ������
     dw CmdWrite          ; 5 HL-������, DE-����� / A-��� ������
     dw CmdMove           ; 6 HL-��, DE-� / A-��� ������

;----------------------------------------------------------------------------
; HL-����, DE-�������� ������ ��� ��������, BC-����� / HL-������� ���������, A-��� ������

CmdFind:
     ; ��� �������
     MVI	A, 3
     CALL	StartCommand

     ; ����
     CALL	SendString

     ; �������� ������
     XCHG
     CALL	SendWord

     ; ������������� � ����� ������
     CALL	SwitchRecv

     ; �������
     LXI	H, 0

CmdFindLoop:
     ; ���� ���� �� ���������
     CALL	WaitForReady
     CPI	STA_OK_CMD
     JZ		Ret0
     CPI	STA_OK_ENTRY
     JNZ	EndCommand

     ; ����� ����� ������
     LXI	D, 20	; ����� �����
     CALL	RecvBlock

     ; ����������� ������� ������
     INX	H

     ; ����
     JMP	CmdFindLoop

;----------------------------------------------------------------------------
; D-�����, HL-��� ����� / A-��� ������

CmdOpenDelete: 
     ; ��� �������
     MVI	A, 4
     CALL	StartCommand

     ; �����
     MOV	A, D
     CALL	Send

     ; ��� �����
     CALL	SendString

     ; ���� ���� �� ���������
     CALL	SwitchRecvAndWait
     CPI	STA_OK_CMD
     JZ		Ret0
     JMP	EndCommand
     
;----------------------------------------------------------------------------
; B-�����, DE:HL-������� / A-��� ������, DE:HL-�������

CmdSeekGetSize:
     ; ��� �������
     MVI 	A, 5
     CALL	StartCommand

     ; �����     
     MOV	A, B
     CALL	Send

     ; �������     
     CALL	SendWord
     XCHG
     CALL	SendWord

     ; ���� ���� �� ���������. �� ������ �������� ����� STA_OK_CMD
     CALL	SwitchRecvAndWait
     CPI	STA_OK_CMD
     JNZ	EndCommand

     ; ����� �����
     CALL	RecvWord
     XCHG
     CALL	RecvWord

     ; ���������
     JMP	Ret0
     
;----------------------------------------------------------------------------
; HL-������, DE-����� / HL-������� ���������, A-��� ������

CmdRead:
     ; ��� �������
     MVI	A, 6
     CALL	StartCommand

     ; ����� � BC
     MOV	B, D
     MOV	C, E

     ; ������ �����
     CALL	SendWord        ; HL-������

     ; ������������� � ����� ������
     CALL	SwitchRecv

     ; ����� �����. �� ����� ����� BC, �������� ����� � HL
     JMP	RecvBuf

;----------------------------------------------------------------------------
; HL-������, DE-����� / A-��� ������

CmdWrite:
     ; ��� �������
     MVI	A, 7
     CALL	StartCommand
     
     ; ������ �����
     CALL	SendWord        ; HL-������

     ; ������ ����� � HL
     XCHG

CmdWriteFile2:
     ; ��������� ���������� �������
     CALL	SwitchRecvAndWait
     CPI  	STA_OK_CMD
     JZ  	Ret0
     CPI  	STA_OK_WRITE
     JNZ	EndCommand

     ; ������ �����, ������� ����� ������� �� � DE
     CALL	RecvWord

     ; ������������� � ����� ��������    
     CALL	SwitchSend

     ; �������� �����. ����� BC ����� DE.
CmdWriteFile1:
     CALL   SendBlock
     JMP	CmdWriteFile2

;----------------------------------------------------------------------------
; HL-��, DE-� / A-��� ������

CmdMove:     
     ; ��� �������
     MVI	A, 8
     CALL	StartCommand

     ; ��� �����
     CALL	SendString

     ; ���� ���� �� ���������
     CALL	SwitchRecvAndWait
     CPI	STA_OK_WRITE
     JNZ	EndCommand

     ; ������������� � ����� ��������
     CALL	SwitchSend

     ; ��� �����
     XCHG
     CALL	SendString

WaitEnd:
     ; ���� ���� �� ���������
     CALL	SwitchRecvAndWait
     CPI	STA_OK_CMD
     JZ		Ret0
     JMP	EndCommand

;----------------------------------------------------------------------------
; HL-��� �����, DE-��������� ������ / A-��� ������

CmdExec:
     ; ��� �������
     MVI	A, 2
     CALL	StartCommand

     ; ��� �����
     PUSH	H
     CALL	SendString
     POP	H

     ; ���� ���� �� ��������� ����
     ; �� ������ �������� ����� STA_OK_ADDR
     CALL	SwitchRecvAndWait
     CPI	STA_OK_ADDR
     JNZ	EndCommand

     ; ��������� ��� ����� (HL-������)
     PUSH	D
     XCHG
     LXI	H, SELF_NAME
     CALL	strcpy255
     POP	D

     ; ��������� ��������� ������ (DE-������)
     LXI	H, CMD_LINE
     CALL	strcpy255

     ; *** ��� ����� ����������. ����� ������ �������� � ������������. ***

     ; ������������� ����� (���������� ������������ ��������)
     LXI	SP, INIT_STACK

     ; ��������� ����� �������� � BC � ��������� ��� � ����
     CALL	RecvWord
     PUSH	D
     MOV 	B, D
     MOV 	C, E

     ; ��������� ����
     CALL	RecvBuf
     JNZ 	Error

     ; ������� ������
     ; ������� ���� ������� �� ������� ������ ��� ���� �������, � �� ������ ���������
     MVI	C, 1Fh
     CALL	0F809h     
     ; � ������ ������������� ���������������
     CALL       INIT_VIDEO

     ; ��������� ��� ���������
     MVI  A, 1		; ������ �����������
     LXI  B, BiosEntry  ; ����� ����� SD BIOS
     LXI  D, SELF_NAME  ; ����������� ���
     LXI  H, CMD_LINE   ; ��������� ������

     ; ������ ����������� ���������
     RET

;----------------------------------------------------------------------------
; ��� ���� ��������� �������. ������ �������� 8E00.
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
; ������ ����� �������. 
; A - ��� �������

StartCommand:
     ; ������ ������ ���������� ������������� � ������������
     ; ����������� 256 �������, � ������ �� ������� ������������ 256+ ����
     ; �� ���� ��� ������������ ���-�� ������, ������� ����� �������� ����������
     PUSH	B
     PUSH	H
     PUSH	PSW
     MVI	C, 0

StartCommand1:
     ; ����� �������� (����������� ����) � �������������� HL
     CALL       SwitchRecv

     ; ������ ����� ������� (��� ���� ������)
     ;LXI	H, USER_PORT+1
     ;MVI        M, 0
     ;MVI        M, 44h
     ;MVI        M, 40h
     ;MVI        M, 0h

     ; ���� ���� �������������, �� ���������� ������� STA_START
     CALL	Recv
     CPI	STA_START
     JZ		StartCommand2

     ; �����. � �� ���� ���������� 256 ���� (� ����� ����� 
     ; ��������� 64 �� ������, ������������ ������ ������)
     PUSH	B
     MVI	C, 0
StartCommand3:
     CALL	Recv
     DCR	C
     JNZ	StartCommand3
     POP	B
        
     ; �������
     DCR	C
     JNZ	StartCommand1    

     ; ��� ������
     MVI	A, STA_START
StartCommandErr2:
     POP	B ; ������� �������� PSW
     POP	H ; ������� �������� H
     POP	B ; ������� �������� B     
     POP	B ; ������� ����� �������.
     RET

;----------------------------------------------------------------------------
; ������������� � ������������ ����. ���������� ������ �������� STA_OK_DISK

StartCommand2:
     ; �����         	
     CALL	WaitForReady
     CPI	STA_OK_DISK
     JNZ	StartCommandErr2

     ; ������������� � ����� ��������
     CALL       SwitchSend

     POP        PSW
     POP        H
     POP        B

     ; �������� ��� �������
     JMP        Send

;----------------------------------------------------------------------------
; ������������� � ����� ��������


;----------------------------------------------------------------------------
; �������� ��������� ������� 
; � �������������� ����, ��� �� �� �������� ����

Ret0:
     XRA	A

;----------------------------------------------------------------------------
; ��������� ������� � ������� � A 
; � �������������� ����, ��� �� �� �������� ����

EndCommand:
     ;PUSH	PSW
     ;CALL	Recv
     ;POP	PSW
     RET

;----------------------------------------------------------------------------
; ������� ����� � DE 
; ������ A.

RecvWord:
    CALL Recv
    MOV  E, A
    CALL Recv
    MOV  D, A
    RET
    
;----------------------------------------------------------------------------
; ��������� ����� �� HL 
; ������ A.

SendWord:
    MOV		A, L
    CALL	Send
    MOV		A, H
    JMP		Send
    
;----------------------------------------------------------------------------
; �������� ������
; HL - ������
; ������ A.

SendString:
     XRA	A
     ORA	M
     JZ		Send
     CALL	Send
     INX	H
     JMP	SendString
     

;----------------------------------------------------------------------------
; ������������� � ����� ������ � �������� ���������� ��.

SwitchRecvAndWait:
     CALL SwitchRecv

;----------------------------------------------------------------------------
; �������� ���������� ��.

WaitForReady:
     CALL	Recv
     CPI	STA_WAIT
     JZ		WaitForReady
     RET


;----------------------------------------------------------------------------
; ��������� DE ���� �� ������ BC
; ������ A
SendBlock:
     MVI    A,80H
     JMP    RecvSendBlock

;----------------------------------------------------------------------------
; ������� DE ���� �� ������ BC
; ������ A

RecvBlock:
     MVI    A,40H
RecvSendBlock:
     PUSH   H
     PUSH   D

     PUSH	B
     PUSH   D
     POP    B
     POP    D

     PUSH   B
     ORA    B
     MOV    B,A
     CALL   SET_DMAW
     XCHG
     POP    B
     DAD    B
     MOV    C,L
     MOV    B,H
     POP    D
     POP    H
     XRA    A
     RET

RecvBlock2:
    JMP    DmaReadVariable

;----------------------------------------------------------------------------
; �������� ������ �� ������ BC. 
; �� ������ HL ������� ���������
; ������ A
; ���� ��������� ��� ������, �� ������ Z=1

RecvBuf:
     LXI	H, 0
RecvBuf0:   
     ; ���������
     CALL	WaitForReady
     CPI	STA_OK_READ
     JZ		Ret0		; �� ������ Z (��� ������)
     SUI    STA_OK_BLOCK
     JNZ	EndCommand	; �� ������ NZ (������)

     ; ������ ����������� ������ � DE
     CALL	RecvWord

     ; � HL ����� ������
     DAD D

     ; ������� DE ���� �� ������ BC
     CALL	RecvBlock

     JMP	RecvBuf0

;----------------------------------------------------------------------------
; ����������� ������ � ������������ 256 �������� (������� ����������)

strcpy255:
     MVI  B, 255
strcpy255_1:
     LDAX D
     INX  D
     MOV  M, A
     INX  H
     ORA  A
     RZ
     DCR  B
     JNZ  strcpy255_1
     MVI  M, 0 ; ����������
     RET

;----------------------------------------------------------------------------
; ��������� ���� �� A.

Send:
    PUSH    H
    LHLD    BUF_PTR
    MOV     M,A
    INX     H
    SHLD    BUF_PTR
    POP H
    RET

;----------------------------------------------------------------------------
; ������� ���� � �

Recv:
     PUSH   H
     PUSH   D
     PUSH   B
     LHLD   BUF_PTR
     LDA    BUF_SIZE
     ORA    A
     CZ     DmaReadVariable
     LDA    BUF_SIZE
     DCR    A
     STA    BUF_SIZE
     LHLD   BUF_PTR
     MOV    A,M
     INX    H
     SHLD   BUF_PTR
     POP    B
     POP    D
     POP    H
     RET

;----------------------------------------------------------------------------
include DmaIo.asm
THE_END:
End
