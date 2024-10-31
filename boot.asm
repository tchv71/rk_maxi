; SD BIOS for Computer "Radio 86RK" / "Apogee BK01"
; (c) 10-05-2014 vinxru (aleksey.f.morozov@gmail.com)
; (c) 24-10-2024 tchv aka Dmitry Tsvetkov (tchv71@mail.ru)
     .phase 0 

MONITOR         EQU 0F86Ch    ; ����� ������� � �������

; ���� ������������ �����������������

STA_START       EQU 040h ; �� ���������� � ����� ������ ������
STA_WAIT        EQU 041h ; �� ��������� �������
STA_OK_DISK     EQU 042h ; ���������� ��������, ��������������� ����� � ������ �������
STA_OK          EQU 043h ; ������� ���������
STA_OK_READ     EQU 044h ; �� ����� �������� ��������� ���� ������
STA_OK_ADDR     EQU 047h ; �� ����� �������� ����� ��������
STA_OK_BLOCK    EQU 04Fh 
;BUF             EQU 0D8h
;----------------------------------------------------------------------------
; ����� �����

Entry:
     ; ������ ������ ���������� ������������� � ������������
     ; 256 �������. ��� ����� � ������� C ��������� 0
     MVI    H,0

Boot:
     ; ����� �������� (����������� ����) � �������������� HL
     CALL  SwitchRecv

     JMP   Boot2

;----------------------------------------------------------------------------
; �������� � ����� ����� (� HL ������ ��������� USER_PORT)

Rst1:
     JMP GetByte
     NOP
     NOP
     NOP
     NOP
     NOP
;----------------------------------------------------------------------------
; �������� ���������� ��

Rst2:
WaitForReady:
     Rst   1
     CPI   STA_WAIT
     JZ    WaitForReady
     RET
     NOP
Rst3:
     JMP   SET_DMAW

SEND_BYTE MACRO
    PUSH   H
    LHLD   BUF_PTR
    MOV    M,A
    INX    H
    SHLD   BUF_PTR
    POP    H
    ENDM

;----------------------------------------------------------------------------

     ; ������ ����� ������� (��� ���� ������)
Boot2:
     ; ���� ���� �������������, �� ���������� ������� STA_START �� ���� ������
     Rst   1
     CPI   STA_START
     JNZ   RetrySync

     ; ������������� ������
     Rst   2
     CPI   STA_OK_DISK
     JNZ   RetrySync

     ; ����� ��������     
     ;Rst   1     
     CALL  SwitchSend

     ; ��� ������� BOOT
     XRA   A
     SEND_BYTE

     ; ����� ������
     CALL  SwitchRecv

     ; ��� ����� ������� BOOT
     Rst   2
     CPI   STA_OK_ADDR
     JNZ   RetrySync
     
     ; ����� �������� � DE
     Rst   1
     MOV   L, A
     Rst   1
     MOV   H, A

     ; ��������� � ���� ����� �������
     PUSH   H

     ; ���� ����� ���� ������ �� ��������� ������
RecvLoop:
     ; ��� ����� ���������, ����� ��������� ����.
     Rst   2
     CPI   STA_OK_READ
     JZ    Rst1

     ; ���� �� �������� ���� ��� ������, ����� ������� STA_OK_BLOCK
     CPI   STA_OK_BLOCK
     JNZ   PrintError

     ; ������ ����� ������
     Rst   1
     MOV   B, A
     Rst   1
     PUSH  B
     PUSH  D
     MOV   C,B
     ORI   40h
     MOV   B, A

     ; ��������� ���� ������
     XCHG
     RST   3; CALL  SET_DMA
     XCHG
     MOV   A,B
     ANI   3Fh
     MOV   B,A
     DAD   B
     POP   D
     POP   B
     JMP   RecvLoop

;----------------------------------------------------------------------------
; ��������� ������

RetrySync:
     ; �������
     ;DCR   H
     ;JNZ   Boot
     jmp    0F800H

;----------------------------------------------------------------------------
; ����� ���� ������

PrintError:
     CALL  0F815h
     JMP   MONITOR

     include DmaIo.asm

     End

