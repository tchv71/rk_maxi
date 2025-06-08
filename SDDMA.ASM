    .phase 80H
CHANNEL0 EQU 1

    LXI D,1200h
    LXI B,4080h
    CALL SET_DMAW
    
    LXI D,1200h
    LXI B,8080h
    CALL SET_DMAW

    LXI D,1280h
    LXI B,4080h
    ;CALL SET_DMAW

    ; HL - addr
    ; DE - size
; Set DMA with waiting of the end of transfer
SET_DMAW:
     CALL  SET_DMA
WAIT_DMA:
     LDA   0C608H
IFDEF CHANNEL0
     ANI   1
ELSE
     ANI   2
ENDIF
     JZ    WAIT_DMA
     RET
; Program DMA controller

; DE - start address
; BC - packet length with MSB:
;   10 - read cycle (transfer from memory to device)
;   01 - write cycle (thansfer from device to memory)
SET_DMA:
     PUSH  H
     LXI   H,0C60Fh
     MOV   A,M
     INR   A
     JZ    VT37
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
     INX   B
     MVI   L,8
IFDEF CHANNEL0
     MVI   M,0F5h
ELSE
     MVI   M,0F6h
ENDIF
     POP   H
     RET

VT37:
     MOV   A,B
     PUSH  PSW
     ANI   3Fh
     MOV   B,A
     MVI   L,0Ch
     MOV   M,A
     MVI   L,0Ah
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
     POP   H
     RET

    END

