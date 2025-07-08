;----------------------------------------------------------------------------
; Copy the string with limit 256 symbols (including terminator)

strcpy255:
     MVI	B, 255
strcpy255_1:
     LDAX	D
     INX	D
     MOV	M, A
     INX	H
     ORA	A
     RZ
     DCR	B
     JNZ	strcpy255_1
     MVI	M, 0 ; Terminator
     RET
;----------------------------------------------------------------------------
; Send byte from A.

SendSD:
    PUSH	H
    LHLD	SDBUF_PTR
    MOV		M,A
    INX		H
    SHLD	SDBUF_PTR
    POP		H
    RET

IF 0
;----------------------------------------------------------------------------
; Receive byte into À

RecvSD:
     PUSH	H
     PUSH	D
     PUSH	B
     LDA	SDBUF_SIZE
     ORA	A
     CZ		DmaReadVariable
     LDA	SDBUF_SIZE
     DCR	A
     STA	SDBUF_SIZE
     LHLD	SDBUF_PTR
     MOV	A,M
     INX	H
     SHLD	SDBUF_PTR
     POP	B
     POP	D
     POP	H
     RET
ENDIF
