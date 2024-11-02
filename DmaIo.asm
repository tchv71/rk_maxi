SEND_MODE       EQU 0         ; Режим передачи
RECV_MODE       EQU 1         ; Режим приема

;----------------------------------------------------------------------------
; Установка режима приема или передачи

SwitchRecv:
     PUSH   H
     PUSH   D
     PUSH   B
     LDA    Mode
     ORA    A ; CPI SEND_MODE
     JNZ    RM01

     LXI    H,-BUF
     XCHG
     LHLD   BUF_PTR
     DAD    D
     MOV    A,H
     ORA    L
     JZ     RM01
     XCHG
     LXI    H,BUF-2
     MOV    M,E
     INX    H
     MOV    M,D
     DCX    H
     XCHG
     LXI    B,8002h
     ;RST    3
     CALL   SET_DMAW
     LDAX   D
     INX    D
     MOV    C,A
     LDAX   D
     INX    D
     ORI    80H
     MOV    B,A
     ;RST    3
     CALL   SET_DMAW
RM01:
     MVI   A, RECV_MODE
     JMP   SetMode
SwitchSend:
     PUSH  H
     PUSH  D
     PUSH  B
     XRA   A ; MVI   A,SEND_MODE
SetMode:
     STA   Mode
     XRA    A
     STA   BUF_SIZE
     LXI   H, BUF
     SHLD  BUF_PTR
     ;MVI   C,0
     POP   B
     POP   D
     POP   H
     RET

; Read variable length DMA record - the first packet is 2 bytes length,
; the second - data with previosly transmitted length
DmaReadVariable:
     LXI   B,4002H
     LXI   D,BUF
     ;RST   3
     CALL  SET_DMAW
     LDAX  D
     INX   D
     MOV   C,A
     LDAX  D
     INX   D
     ORI   40H
     MOV   B,A
     CALL  SET_DMAW
     MOV   A,C
     STA   BUF_SIZE
     XCHG
     SHLD  BUF_PTR
     XCHG
     RET

; Set DMA with waiting of the end of transfer
SET_DMAW:
     CALL  SET_DMA
WAIT_DMA:
     LDA   0C608H
     ANI   2
     JZ    WAIT_DMA
     RET
; Program DMA controller

; DE - start address
; BC - packet length with MSB:
;   10 - read cycle (transfer from memory to device)
;   01 - write cycle (thansfer from device to memory)
SET_DMA:
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
     RET


Mode: db RECV_MODE
BUF_PTR:    ds  2
BUF_SIZE:   ds  1
BUF:        ds  32
