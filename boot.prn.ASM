; Boot loader (SD BIOS) for Computer "Radio 86RK" / "Apogee BK01" 
; (c) 10-05-2014 vinxru (aleksey.f.morozov@gmail.com) 
; (c) 24-10-2024 - 08-06-2025 tchv aka Dmitry Tsvetkov (tchv71@mail.ru) 
     .phase 0 
 
MONITOR         EQU	0F86Ch    ; RK-86 warm start 
CHANNEL0	EQU	1	  ; Use channel 0 of DMA 
;VT37		EQU	1 
 
; MC codes 
STA_START       EQU 040h ; MC switched to command receive mode 
STA_WAIT        EQU 041h ; MC is executing command 
STA_OK_DISK     EQU 042h ; The drive is working, MC is ready to receive command 
STA_OK          EQU 043h ; Command is executed 
STA_OK_READ     EQU 044h ; MC is ready to transfer next data block 
STA_OK_ADDR     EQU 047h ; MC is ready to send loading address 
STA_OK_BLOCK    EQU 04Fh  
;BUF             EQU 0D8h 
;---------------------------------------------------------------------------- 
; Entry point 
 
Entry: 
Boot: 
     ; Send mode (release the bus) and init HL 
     ;CALL  SwitchRecv 
     CALL   Boot2 ; If this subprogram returns - there is an error 
     jmp    0F800H 
     NOP 
     NOP 
;---------------------------------------------------------------------------- 
; Byte send and receive (HL should contain USER_PORT) 
 
Rst1: 
     JMP   Recv 
ClearRcvBuf: 
     XRA    A 
     STA    BUF_SIZE 
     RET 
;---------------------------------------------------------------------------- 
; Wait for MC ready 
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
     LXI   H,0C60Fh 
     MOV   A,M 
     INR   A 
     JZ    _VT37 
     MVI   L,8 
     MVI   M,0F4h 
IFDEF CHANNEL0 
     MVI   L,0 
ELSE 
     MVI   L,2 
ENDIF 
     MOV   M,E 
     MOV   M,D 
     INR   L 
     DCX   B 
     MOV   M,C 
     MOV   M,B 
     ;INX   B 
     JMP   SD01 
     DS    3 ; RST 6 
SD01: 
     INX    B 
     JMP   WAIT_DMA1 
 
     DS    3Fh-$ 
 
_VT37: 
     MOV   A,B 
     PUSH  PSW 
     ANI   3Fh 
     MOV   B,A 
     MVI   L,0Ch 
     MOV   M,A 
     MVI   L,0AH 
IFDEF CHANNEL0 
     MVI   M,4 ; Stop channel 0 
     MVI   L,0 
ELSE 
     MVI   M,5 ; Stop channel 1 
     MVI   L,2 
ENDIF 
     MOV   M,E 
     MOV   M,D 
     INR   L 
     DCX   B 
     MOV   M,C 
     MOV   M,B 
     INX   B 
     MVI   L,0Bh 
     POP   PSW 
     ANI   0C0H 
     RRC 
     RRC 
     RRC 
     RRC 
IFNDEF CHANNEL0 
     ORI   1 
ENDIF 
     MOV   M,A 
     MVI   L,8 
     MVI   M,20h 
     MVI   L,0Ah 
IFDEF CHANNEL0 
     MVI   M,0 
ELSE 
     MVI   M,1 ; Start channel 1 
ENDIF 
 
     MVI   L,8 
WAIT_DMA: 
     MOV   A,M 
IFDEF CHANNEL0 
     ANI   1 
ELSE 
     ANI   2 
ENDIF 
     JZ    WAIT_DMA 
     POP   H 
     RET 
WAIT_DMA1: 
     MVI   L,8 
IFDEF CHANNEL0 
     MVI   M,0F5H 
ELSE 
     MVI   M,0F6h 
ENDIF 
     JMP   WAIT_DMA 
;---------------------------------------------------------------------------- 
     ; Start of any command (this is address bus) 
Boot2: 
     CALL  ClearRcvBuf 
     ; If there is synchronization, controller will answer STA_START 
     Rst   1 
     CPI   STA_START 
     RNZ; JNZ   RetrySync 
 
     ; Flash disk initialization 
     Rst   2 
     CPI   STA_OK_DISK 
     RNZ; JNZ   RetrySync 
 
     XRA   A     ; BOOT command code 
Send: 
     LXI   D,OUTCHAR 
     STAX  D 
     ;XRA   A 
     DCX   D 
     STAX  D 
     DCX   D 
     INR   A 
     STAX  D 
     LXI   B,8002H 
     RST   3;CALL  SET_DMAW 
     INX   D 
     INX   D 
     DCR   C 
     RST   3;CALL  SET_DMAW 
 
     ; This is BOOT command answer 
     CALL  ClearRcvBuf 
     Rst   2 
     CPI   STA_START 
     JNZ   CMD01 
     Rst   2  
CMD01: 
     CPI   STA_OK_ADDR 
     RNZ 
      
     ; Loading address in DE 
     Rst   1 
     MOV   E, A 
     Rst   1 
     MOV   D, A 
 
     ; Save starting address into stack 
     PUSH   D 
 
     ; File may be broken into several parts 
RecvLoop: 
     ; All parts are loaded, may execute the file 
     Rst   2 
     CPI   STA_OK_READ 
     RZ 
 
     ; If MC has readed block without errors, STA_OK_BLOCK will be send 
     CPI   STA_OK_BLOCK 
     RNZ 
 
     ; Data block size 
     Rst   1 
     MOV   C, A 
     Rst   1 
     MOV   B,A 
     PUSH  B 
     ORI   40h 
     MOV   B, A 
     ; Receive the data block 
     RST   3; CALL  SET_DMA 
     POP   B 
     XCHG 
     DAD   B 
     XCHG 
     JMP   RecvLoop 
 
 
;---------------------------------------------------------------------------- 
; Print error code 
 
;PrintError: 
;     CALL  0F815h 
;     JMP   MONITOR 
 
 
;---------------------------------------------------------------------------- 
; Receive byte into @ 
 
Recv: 
     PUSH   H 
     PUSH   D 
     PUSH   B 
     LXI    H,BUF_SIZE 
     MOV    A,M 
     ORA    A 
     CZ     DmaReadVariable 
     DCR    M 
     LHLD   BUF_PTR 
     MOV    A,M 
     INX    H 
     SHLD   BUF_PTR 
     POP    B 
     POP    D 
     POP    H 
     RET 
 
; Read variable length DMA record - the first packet is 2 bytes length, 
; the second - data with previosly transmitted length 
DmaReadVariable: 
     LXI   B,4002H 
     LXI   D,BUF 
     RST   3;CALL  SET_DMAW 
     LDAX  D 
     INX   D 
     MOV   C,A 
     LDAX  D 
     INX   D 
     ORI   40H 
     MOV   B,A 
     RST   3;CALL  SET_DMAW 
     MOV   A,C 
     STA   BUF_SIZE 
     XCHG 
     SHLD  BUF_PTR 
     XCHG 
     RET 
 
;     DW 1 
;OUTCHAR: DS 2 
;Mode: db RECV_MODE 
BUF_PTR:    ds  2 
BUF_SIZE:   DW  0 
OUTCHAR: 
BUF:        ds  2 
THE_END: 
     End 
