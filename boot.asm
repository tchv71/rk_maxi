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
Boot:
     ; ����� �������� (����������� ����) � �������������� HL
     ;CALL  SwitchRecv
     CALL   Boot2 ; ���� �������� - ��������� ������
;----------------------------------------------------------------------------
; ��������� ������

     jmp    0F800H
     NOP
     NOP
;----------------------------------------------------------------------------
; �������� � ����� ����� (� HL ������ ��������� USER_PORT)

Rst1:
     PUSH  D
     PUSH  B
     CALL  Recv
     POP   B
     POP   D
     RET
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
; Program DMA controller

; DE - start address
; BC - packet length with MSB:
;   10 - read cycle (transfer from memory to device)
;   01 - write cycle (thansfer from device to memory)
SET_DMAW:
     PUSH  H
     LXI   H,0C608H
     MVI   M,0F4h
     MVI   L,2
     MOV   M,E
     MOV   M,D
     INR   L
     DCX   B
     MOV   M,C
     MOV   M,B
     INX   B
     MVI   L,8
     MVI   M,0F6h
     POP   H
WAIT_DMA:
     LDA   0C608H
     ANI   2
     JZ    WAIT_DMA
     RET

;----------------------------------------------------------------------------
     ; ������ ����� ������� (��� ���� ������)
Boot2:
     MVI    H,1
     ; ���� ���� �������������, �� ���������� ������� STA_START �� ���� ������
     Rst   1
     CPI   STA_START
     RNZ; JNZ   RetrySync

     ; ������������� ������
     Rst   2
     CPI   STA_OK_DISK
     RNZ; JNZ   RetrySync

     ; ����� ��������     
     ;Rst   1     
     ;CALL  SwitchSend

     ; ��� ������� BOOT
     XRA   A
Send:
     LXI   D,OUTCHAR
     STAX  D
     DCX   D
     DCX   D
     ;MVI   A,1
     ;@out  SD
     LXI   B,8002H
     ;CALL  SET_DMAW
     RST   3
     INX   D
     INX   D
     DCR   C
     RST   3
     ;ORA   A

     ; ����� ������
     ;CALL  SwitchRecv

     ; ��� ����� ������� BOOT
     Rst   2
     CPI   STA_OK_ADDR
     RNZ; JNZ   RetrySync
     
     ; ����� �������� � DE
     Rst   1
     MOV   E, A
     Rst   1
     MOV   D, A

     ; ��������� � ���� ����� �������
     PUSH   D

     ; ���� ����� ���� ������ �� ��������� ������
RecvLoop:
     ; ��� ����� ���������, ����� ��������� ����.
     Rst   2
     CPI   STA_OK_READ
     RZ;    Rst1

     ; ���� �� �������� ���� ��� ������, ����� ������� STA_OK_BLOCK
     CPI   STA_OK_BLOCK
     RNZ; JNZ   PrintError

     ; ������ ����� ������
     Rst   1
     MOV   C, A
     Rst   1
     MOV   B, A
     PUSH  B
     ORI   40h
     MOV   B, A

     ; ��������� ���� ������
     RST   3; CALL  SET_DMA
     XCHG
     POP   B
     DAD   B
     XCHG
     JMP   RecvLoop


;----------------------------------------------------------------------------
; ����� ���� ������

;PrintError:
;     CALL  0F815h
;     JMP   MONITOR


Recv:
     LXI   D,OUTCHAR
     LXI   B,4001H
     DCR   H
     JNZ   Recv01
     INR   C
     RST   3
     DCR   C
     LDAX  D
     MOV   H,A
Recv01:
     ;CALL  SET_DMAW
     RST   3
     LDAX  D
     ;ORA   A ; Clear C-flag
     RET

     DW 1
OUTCHAR: DS 2

     End

