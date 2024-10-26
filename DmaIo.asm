SEND_MODE       EQU 0         ; Режим передачи
RECV_MODE       EQU 1         ; Режим приема

;----------------------------------------------------------------------------
; Установка режима приема или передачи

SwitchRecv:
     LDA    Mode
     ORA    A ; CPI SEND_MODE
     JNZ    RM01
     PUSH   H
     LXI    H,-BUF
     DAD    D
     XCHG
     LXI    H,BUF-2
     MOV    M,E
     INX    H
     MOV    M,D
     DCX    H
     XCHG
     LXI    B,8002h
     POP    H
     RST    3; CALL   SET_DMA
     LDAX   D
     INX    D
     MOV    C,A
     LDAX   D
     INX    D
     ORI    80H
     MOV    B,A
     RST    3; CALL   SET_DMA
RM01:
     MVI   A, RECV_MODE
     JMP   SetMode
SwitchSend:
     MVI   A,SEND_MODE
SetMode:
     LXI   D, BUF
     STA   Mode
     MVI   C,0
     RET

GetByte:
     MOV   A,C
     ORA   A
     CZ    DmaReadVariable
     DCR   C
     RET

DmaReadVariable:
     LXI   B,4002H
     LXI   D,BUF
     RST   3; CALL  SET_DMA
     LDAX  D
     INX   D
     MOV   C,A
     LDAX  D
     INX   D
     ORI   40H
     MOV   B,A
SET_DMA:
     PUSH  H
     LXI   H,0C608H
     MVI   M,80h;0F4h
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
     ;RET
WAIT_DMA:
    LDA 0C608H
    ANI 2
    JZ WAIT_DMA
    RET
Mode: db RECV_MODE
