;  MON8080.ASM - 8080 Debug monitor for use with NoICE85
;  This file may be assembled with the Alfred Arnold assembler.
;  Available from http://john.ccac.rwth-aachen.de:8000/as/
;
;  Sample command lines (assuming as.exe and p2hex.exe are on path)
;    asw.exe Mon8080.asm -L -E -g NOICE
;       Where
;       -L           generate a listing file Mon8080.lst
;       -E           generate an error.log file (errors are also shown in the listing)
;       -g NOICE     generate a NoICE debug file.
;
;    p2hex Mon8080.p Mon8080.hex -F Intel
;       Where
;       -F Intel     Intel hex Output
;
        .8080 ;CPU 8080        ; Specify architecture
;
;  Copyright (c) 2000-2022 by John Hartman
;
;  Modification History:
;       14-Jun-2000 ported from Z80
;       21-Jul-2000 JLH change FN_MIN from F7 to F0
;       12-Mar-2001 JLH V3.0: improve text about paging, formerly called "mapping"
;        9-Nov-2021 JLH tweak for Alfred Arnold assembler
;       20-Nov-2021 JWD Cleanup and fixes specific to 8080
;       26-Jan-2022 JLH Cleanup and clarifying comments
;
; NOTE: review "TODO" notes for things you may need to modify for your hardware.
;
;============================================================================
;
;  TODO: To customize for a given target, you must change code in the
;  hardware equates, the string TSTG, and the routines RESET and REWDT.
;  You may or may not need to change GETCHAR, PUTCHAR, depending on
;  how peculiar your UART is.
;
;  For more information, refer to the NoICE help file monitor.htm
;
;  To add banked or paged memory support:
;  1) Define page latch port PAGELATCH here
;  2) If PAGELATCH is write only, define or import the latch port's RAM
;     image PAGEIMAGE here (The application code must update PAGEIMAGE
;     before outputing to PAGELATCH)
;  3) Search for and modify PAGELATCH, PAGEIMAGE, and REG_PAGE usage below
;  4) In TSTG below edit "LOW AND HIGH LIMIT OF PAGED MEM"
;     to appropriate range (typically 4000H to 07FFFH for two-bit MMU)
;
;  For more information, refer to the NoICE help file 2bitmmu.htm
;
;============================================================================
;
;  Hardware definitions
ROM_START equ MON_MOD_ORG       ;START OF MONITOR CODE
RAM_START equ 0D000h;           ;START OF MONITOR RAM
USER_CODE equ 30h               ; RST 6 handler
?Ctrl	equ	40h
?Shift	equ	20h

FT245R  equ     0D0h    ;  base address of FT245R FIFO
DATA    equ     0       ;  Data register
STAT    equ     1       ;  Status register
;
;  Define FIFO port
FIFO_DATA   equ   FT245R+DATA
FIFO_STATUS equ   FT245R+STAT

RXEMPTY equ     1       ; MASK FOR RX BUFFER EMPTY
TXFULL  equ     2       ; MASK FOR TX BUFFER FULL

        ;.dephase
        ;.phase RAM_START
;============================================================================
;  RAM definitions:  top 1K (or less)
;
;  Initial user stack
;  (Size and location is user option)
        ;DS     64
INITSTACK       EQU     RAM_START+40h
;
;  Monitor stack
;  (Calculated use is at most 6 bytes.  Leave plenty of spare)
        ;DS     16+16
MONSTACK       EQU     RAM_START+60h
;
;  Target registers:  order must match that in TRG8085.C
TASK_REGS      EQU     MONSTACK
REG_STATE      EQU     MONSTACK;:        DS     1
REG_PAGE       EQU     MONSTACK+1;:      DS     1
REG_SP         EQU     MONSTACK+2;:      DS     2
REG_HL         EQU     MONSTACK+4;:      DS     2
REG_BC         EQU     MONSTACK+6;:      DS     2
REG_DE         EQU     MONSTACK+8;:      DS     2
REG_PSW        EQU     MONSTACK+0Ah;:
REG_FLAGS      EQU     MONSTACK+0Ah;:    DS     1
REG_A          EQU     MONSTACK+0Bh;:    DS     1
REG_PC         EQU     MONSTACK+0Ch;:    DS     2
REG_IM         EQU     MONSTACK+0Eh;:    DS     1
T_REGS_SIZE equ 0Fh; $ - TASK_REGS

;
;  Communications buffer
;  (Must be at least as long as TASK_REG_SIZE.  Larger values may improve
;  speed of NoICE memory load and dump commands)
COMBUF_SIZE equ 67              ;DATA SIZE FOR COMM BUFFER
COMBUF_        EQU     RAM_START+6Fh;DS  2+COMBUF_SIZE+1+32 ;BUFFER ALSO HAS FN, LEN, AND CHECK

RAM_END     equ COMBUF_+2+COMBUF_SIZE+1+32;$               ;ADDRESS OF TOP+1 OF RAM
;
        ;.dephase

;===========================================================================
;
;  Main entry point
;
        ;.phase ROM_START;ORG     ROM_START
START_CODE:
        ;CSEG
R0:     DI
        JMP     RESET
;
;===========================================================================
;
;  Dummy handler for RST 1.  This code is copied to USER_RAM, where the
;  RST 1 interrupt calls it.  The code then enters the monitor, specifying
;  a STATE value which identifies the interrupt which occurred.
;
;  RST 1 is used for breakpoint.  Any other RST may be used instead by
;  changing the code below and the value of the breakpoint instruction
;  in the status string TSTG.  If RST NN cannot be used, then CALL may be
;  used instead. However, this will restrict the placement of breakpoints,
;  since CALL is a three byte instruciton.
;
DUMMY_INTS:
        JMP     R1
DUMMY_SIZE      equ $-DUMMY_INTS
        JMP     READRK_NO_START
        JMP     READRK_START
;
R1:     PUSH    PSW
        MVI     A,1                     ;state = 1 (breakpoint)
        JMP     INT_ENTRY

READRK_START:
        MVI     E,1
        JMP     READRK
READRK_NO_START:
        MVI     E,0
READRK:
        CALL    GETCHAR
        JC      READRK
        MOV     H,A
        CALL    GETCHAR
        JC      ERRRK
        MOV     L,A
        CALL    GETCHAR
        JC      ERRRK
        MOV     B,A
        CALL    GETCHAR
        JC      ERRRK
        MOV     C,A
        INX     B
        MOV     A,C
        SUB     L
        MOV     C,A
        MOV     A,B
        SBB     H
        MOV     B,A
        PUSH    H
LOOP3:   CALL    GETCHAR
        JC      ERRRK
        MOV     M,A
        INX     H
        DCX     B
        MOV     A,B
        ORA     C
        JNZ     LOOP3
        POP     H
        mvi     c,6
LOOP2:  CALL    GETCHAR
        JC      ERRRK
        DCR     C
        JNZ     LOOP2
        MOV     A,E
        ORA     A
        RZ
        PCHL

ERRRK:  JMP     ORGB+1800h

@SYSREG	MACRO	VAL
        IN	-1
        MVI	A,VAL
        OUT	-1
        ENDM
; IN and OUT MACRO comands
@in	MACRO	addr
IF ((addr) LT 256)
        in	addr
ELSE
        lda	addr
ENDIF
        ENDM

@out	MACRO	addr
IF ((addr) LT 256)
        out	addr
ELSE
        sta	addr
ENDIF
        ENDM

;
;===========================================================================
;  Power on reset
RESET:
        @SYSREG 0C0h
        MVI     A,12
        out     FT245R
        out     FT245R + 1
        @SYSREG 80h

IF 0
        @SYSREG 0C0h

        MVI     A,0Eh
        @out    VV55
        @out    VV55+1
        @out    VV55+2
        @out    VV55+3

        xra     a
        @out    0
        @out    1
        @out    2
        @out    3

        @SYSREG 80h
ENDIF

        LXI     H,Prompt
        CALL    ORGB+1818h
IF 0
        @SYSREG	0C0h ; Turn on external device programming mode (for in/out commands)
        
        LXI	    H,BEGPRO+1
        
        LXI     B,400h + VV55
        MVI     A,1
        CALL    SETPORT
        @SYSREG 80h
ENDIF
        ;MVI     A,9
        ;CALL    StartCommand
        jmp     Init

PUTS:   MOV     A,M
        INX     H
        MOV     C,A
        ORA     A
        RZ
        CALL    CONOUT
        JMP     PUTS

CONOUT: PUSH    H
        CALL    CONOU1
        POP     H
        RET

CONOU1:
        LHLD	1
        PUSH    D
        LXI	D,9
        DAD	D
        MOV	A,M
        CPI	JMP
        POP     D
        RNZ
        INX	H
        PUSH	D
        MOV	E,M
        INX	H
        MOV	D,M
        XCHG
        POP	D
        PCHL

Prompt:     DB     "NOICE 8080 MONITOR V3.20 (CTRL+SHIFT TO BREAK)",10,13,0

STA_START       EQU 040h ; �� ���������� � ����� ������ ������
STA_WAIT        EQU 041h ; �� ��������� �������
STA_OK_DISK     EQU 042h ; ���������� ��������, ��������������� ����� � ������ �������
STA_OK_CMD      EQU 043h ; ������� ���������
STA_OK_READ     EQU 044h ; �� ����� �������� ��������� ���� ������
STA_OK_ENTRY    EQU 045h ; MK ����� �������� ������ � �����
STA_OK_WRITE	EQU 046h ; MK ���� ��������� ���� ��� ������
STA_OK_ADDR     EQU 047h ; �� ����� �������� ����� ��������
STA_OK_BLOCK    EQU 04Fh 

;Recv    EQU     GETCHAR


;  Initialize monitor
INIT:   LXI     SP,MONSTACK
;
;===========================================================================
;  Perform user hardware initialization here
;  VV55 does not require initialization
;
;===========================================================================
;  Initialize user interrupt vectors to point to monitor
        LXI     H,DUMMY_INTS           ;dummy handler code
        LXI     D,USER_CODE            ;start of user codespace
        LXI     B,DUMMY_SIZE           ;number of bytes
I10:    MOV     A,M
        STAX    D
        INX     H
        INX     D
        DCR     C
        JNZ     I10

;===========================================================================
;
;  Initialize user registers
        LXI     H,INITSTACK
        SHLD    REG_SP                  ;INIT USER'S STACK POINTER
        XRA     A
        MOV     H,A
        MOV     L,A
        SHLD    REG_PC                  ;INIT ALL REGS TO 0
        SHLD    REG_HL
        SHLD    REG_BC
        SHLD    REG_DE
        SHLD    REG_PSW
        STA     REG_STATE               ;set state as "RESET"
;
;  Initialize memory paging variables and hardware (if any)
        STA     REG_PAGE                ;page 0
;;;     STA     PAGEIMAGE
;;;     OUT     PAGELATCH               ;set hardware page
;
; TODO: if you can read interrupt state, you may want to set a different initial value
        STA     REG_IM
;
;  Set function code for "GO".  Then if we reset after being told to
;  GO, we will come back with registers so user can see the crash
        MVI     A,FN_RUN_TARGET
        STA     COMBUF_
        JMP     RETURN_REGS             ;DUMP REGS, ENTER MONITOR
;
;===========================================================================
;  Get a character to A
;
;  Return A=char, CY=0 if data received
;         CY=1 if timeout (0.5 seconds)
;
;  Uses 4 bytes of stack including return address
;
GETCHAR:
        PUSH    D
        LXI     D,8000h       ;long timeout
gc10:   DCX     D
        MOV     A,D
        ORA     E
        JZ      gc90          ;exit if timeout
        @in     FIFO_STATUS   ;read device status
        ANI     RXEMPTY
        JNZ     gc10          ;not ready yet.
;
;  Data received:  return CY=0. data in A
        XRA     A             ;cy=0
        @in     FIFO_DATA     ;read data
        ;PUSH    PSW
        ;CALL    0F815h
        ;POP     PSW
        POP     D
        RET
;
;  Timeout:  return CY=1
gc90:   STC                   ;cy=1
        POP     D
        RET
;
;===========================================================================
;  Output character in A
;
;  Uses 4 bytes of stack including return address
;
PUTCHAR:
        PUSH    PSW           ;save byte to output
pc10:   @in     FIFO_STATUS   ;read device status
        ANI     TXFULL        ;tx full ?
        JNZ     pc10
        POP     PSW
        @out    FIFO_DATA     ;transmit char
        RET
OUTCHAR: DS 1

CheckBrk:
        LDA     0C200h
        ANI     ?Ctrl+?Shift
        RET
;
;===========================================================================
;  Response string for GET TARGET STATUS request
;  Reply describes target:
TSTG:   DB      14                      ;2: PROCESSOR TYPE = 8085
        DB      COMBUF_SIZE             ;3: SIZE OF COMMUNICATIONS BUFFER
        DB      0                       ;4: NO OPTIONS
        DW      0                       ;5,6: BOTTOM OF PAGED MEM (none)
        DW      0                       ;7,8: TOP OF PAGED MEM (none)
        DB      B1-B0                   ;9 BREAKPOINT INSTRUCTION LENGTH
B0:     RST     6                       ;10+ BREKAPOINT INSTRUCTION
B1:     DB     "NoICE 8080 monitor V3.1" ;DESCRIPTION, ZERO
        DB      0
TSTG_SIZE EQU   $ - TSTG                ;SIZE OF STRING
;
;===========================================================================
;  HARDWARE PLATFORM INDEPENDENT EQUATES AND CODE
;
;  Communications function codes.
FN_GET_STATUS   equ 0FFh    ;reply with device info
FN_READ_MEM     equ 0FEh    ;reply with data
FN_WRITE_MEM    equ 0FDh    ;reply with status (+/-)
FN_READ_REGS    equ 0FCh    ;reply with registers
FN_WRITE_REGS   equ 0FBh    ;reply with status
FN_RUN_TARGET   equ 0FAh    ;reply (delayed) with registers
FN_SET_BYTES    equ 0F9h    ;reply with data (truncate if error)
FN_IN           equ 0F8h    ;input from port
FN_OUT          equ 0F7h    ;output to port
;
FN_MIN          equ 0F0h    ;MINIMUM RECOGNIZED FUNCTION CODE
FN_ERROR        equ 0F0h    ;error reply to unknown op-code
;
;===========================================================================
;  Enter here via RST nn for breakpoint:  PSW, PC are stacked.
;  Enter with A=interrupt code = processor state
;  Interrupt status is not changed from user program
INT_ENTRY:
        STA     REG_STATE       ;save entry state
;
;  TODO: if you can read interrupt state, do it here
        XRA     A               ;ALWAYS 0 IF YOU CAN'T READ THE STATE
        DI                      ;NO INTERRUPTS ALLOWED HEREAFTER
        STA     REG_IM          ;SAVE INT REG
;
;  Save registers in reg block for return to master
        SHLD    REG_HL          ;SAVE HL
        POP     H               ;GET FLAGS IN L, ACCUM IN H
        SHLD    REG_PSW         ;SAVE A AND FLAGS
;
;  If entry here was by breakpoint (state=1), then back up the program
;  counter to point at the breakpoint/RST instruction.  Else leave PC alone.
;  (If CALL is used for breakpoint, then back up by 3 bytes)
        POP     H               ;GET PC OF BREAKPOINT/INTERRUPT
        LDA     REG_STATE
        DCR     A
        JNZ     NOTBP           ;JIF NOT A BREAKPOINT
        DCX     H               ;BACK UP PC TO POINT AT BREAKPOINT
NOTBP:  JMP     ENTER_MON       ;HL POINTS AT BREAKPOINT OPCODE
;
;===========================================================================
;  Main loop:  wait for command frame from master
MAIN:   CALL    CheckBrk
        JZ      ORGB+1886Ch
        LXI     SP,MONSTACK     ;CLEAN STACK IS HAPPY STACK
        LXI     H,COMBUF_        ;BUILD MESSAGE HERE
;
;  First byte is a function code
        CALL    GETCHAR         ;GET A FUNCTION (uses 6 bytes of stack)
        JC      MAIN            ;JIF TIMEOUT: RESYNC
        CPI     FN_MIN
        JC      MAIN            ;JIF BELOW MIN: ILLEGAL FUNCTION
        MOV     M,A             ;SAVE FUNCTION CODE
        INX     H
;
;  Second byte is data byte count (may be zero)
        CALL    GETCHAR         ;GET A LENGTH BYTE
        JC      MAIN            ;JIF TIMEOUT: RESYNC
        CPI     COMBUF_SIZE+1
        JNC     MAIN            ;JIF TOO LONG: ILLEGAL LENGTH
        MOV     M,A             ;SAVE LENGTH
        INX     H
        ORA     A
        JZ      MA80            ;SKIP DATA LOOP IF LENGTH = 0
;
;  Loop for data
        MOV     B,A             ;SAVE LENGTH FOR LOOP
MA10:   CALL    GETCHAR         ;GET A DATA BYTE
        JC      MAIN            ;JIF TIMEOUT: RESYNC
        MOV     M,A             ;SAVE DATA BYTE
        INX     H
        DCR     B
        JNZ     MA10
;
;  Get the checksum
MA80:   CALL    GETCHAR         ;GET THE CHECKSUM
        JC      MAIN            ;JIF TIMEOUT: RESYNC
        MOV     C,A             ;SAVE CHECKSUM
;
;  Compare received checksum to that calculated on received buffer
;  (Sum should be 0)
        CALL    CHECKSUM
        ADD     C
        JNZ     MAIN            ;JIF BAD CHECKSUM
;
;  Process the message.
        LDA     COMBUF_+0        ;GET THE FUNCTION CODE
        CPI     FN_GET_STATUS
        JZ      TARGET_STATUS
        CPI     FN_READ_MEM
        JZ      READ_MEM
        CPI     FN_WRITE_MEM
        JZ      WRITE_MEM
        CPI     FN_READ_REGS
        JZ      READ_REGS
        CPI     FN_WRITE_REGS
        JZ      WRITE_REGS
        CPI     FN_RUN_TARGET
        JZ      RUN_TARGET
        CPI     FN_SET_BYTES
        JZ      SET_BYTES
        CPI     FN_IN
        JZ      IN_PORT
        CPI     FN_OUT
        JZ      OUT_PORT
;
;  Error: unknown function.  Complain
        MVI     A,FN_ERROR
        STA     COMBUF_+0        ;SET FUNCTION AS "ERROR"
        MVI     A,1
        JMP     SEND_STATUS     ;VALUE IS "ERROR"

;===========================================================================
;
;  Target Status:  FN, len
;
TARGET_STATUS:
;
        LXI     H,TSTG          ;DATA FOR REPLY
        LXI     D,COMBUF_+1      ;RETURN BUFFER
        MVI     B,TSTG_SIZE     ;LENGTH OF REPLY
        MOV     A,B
        STAX    D               ;SET SIZE IN REPLY BUFFER
        INX     D
TS10:   MOV     A,M             ;MOVE REPLY DATA TO BUFFER
        STAX    D
        INX     H
        INX     D
        DCR     B
        JNZ     TS10
;
;  Compute checksum on buffer, and send to master, then return
        JMP     SEND

;===========================================================================
;
;  Read Memory:  FN, len, page, Alo, Ahi, Nbytes
;
READ_MEM:
;
;  Set page
;;      LDA     COMBUF_+2
;;      STA     PAGEIMAGE
;;      OUT     PAGELATCH
;
;  Get address
        LHLD    COMBUF_+3
        LDA     COMBUF_+5                ;NUMBER OF BYTES TO GET
;
;  Prepare return buffer: FN (unchanged), LEN, DATA
        LXI     D,COMBUF_+1              ;POINTER TO LEN, DATA
        STAX    D                       ;RETURN LENGTH = REQUESTED DATA
        INX     D
        ORA     A
        JZ      GLP90                   ;JIF NO BYTES TO GET
;
;  Read the requested bytes from local memory
        MOV     B,A
GLP:    MOV     A,M             ;GET BYTE TO A
        STAX    D               ;STORE TO RETURN BUFFER
        INX     H
        INX     D
        DCR     B
        JNZ     GLP
;
;  Compute checksum on buffer, and send to master, then return
GLP90:  JMP     SEND

;===========================================================================
;
;  Write Memory:  FN, len, page, Alo, Ahi, (len-3 bytes of Data)
;
;  Uses 2 bytes of stack
;
WRITE_MEM:
;
;  Set page
;;      LDA     COMBUF_+2
;;      STA     PAGEIMAGE
;;      OUT     PAGELATCH
;
;  Get address
        LXI     D,COMBUF_+5      ;POINTER TO SOURCE DATA IN MESSAGE
        LHLD    COMBUF_+3        ;POINTER TO DESTINATION
        XCHG
;
        LDA     COMBUF_+1        ;NUMBER OF BYTES IN MESSAGE
        SBI     3               ;LESS PAGE, ADDRLO, ADDRHI
        JZ      WLP50           ;EXIT IF NONE REQUESTED
;
;  Write the specified bytes to local memory
        MOV     B,A
        PUSH    B               ;SAVE BYTE COUNTER
WLP10:  MOV     A,M             ;BYTE FROM HOST
        STAX    D               ;WRITE TO TARGET RAM
        INX     H
        INX     D
        DCR     B
        JNZ     WLP10
;
;  Compare to see if the write worked
        LXI     D,COMBUF_+5      ;POINTER TO SOURCE DATA IN MESSAGE
        LHLD    COMBUF_+3        ;POINTER TO DESTINATION
        XCHG
        POP     B               ;SIZE AGAIN
;
;  Compare the specified bytes to local memory
WLP20:  LDAX    D               ;READ BACK WHAT WE WROTE
        CMP     M               ;COMPARE TO HOST DATA
        JNZ     WLP80           ;JIF WRITE FAILED
        INX     H
        INX     D
        DCR     B
        JNZ     WLP20
;
;  Write succeeded:  return status = 0
WLP50:  XRA     A               ;RETURN STATUS = 0
        JMP     WLP90
;
;  Write failed:  return status = 1
WLP80:  MVI      A,1
;
;  Return OK status
WLP90:  JMP     SEND_STATUS

;===========================================================================
;
;  Read registers:  FN, len=0
;
READ_REGS:
;
;  Enter here from int after "RUN" and "STEP" to return task registers
RETURN_REGS:
        LXI     H,TASK_REGS     ;REGISTER LIVE HERE
        MVI     A,T_REGS_SIZE   ;NUMBER OF BYTES
;
;  Prepare return buffer: FN (unchanged), LEN, DATA
        LXI     D,COMBUF_+1      ;POINTER TO LEN, DATA
        STAX    D               ;SAVE DATA LENGTH
        INX     D
;
;  Copy the registers
        MOV     B,A
GRLP:   MOV     A,M             ;GET BYTE TO A
        STAX    D               ;STORE TO RETURN BUFFER
        INX     H
        INX     D
        DCR     B
        JNZ     GRLP
;
;  Compute checksum on buffer, and send to master, then return
        JMP     SEND

;===========================================================================
;
;  Write registers:  FN, len, (register image)
;
WRITE_REGS:
;
        LXI     H,COMBUF_+2      ;POINTER TO DATA
        LDA     COMBUF_+1        ;NUMBER OF BYTES
        ORA     A
        JZ      WRR80           ;JIF NO REGISTERS
;
;  Copy the registers
        LXI     D,TASK_REGS     ;OUR REGISTERS LIVE HERE
        MOV     B,A
WRRLP:  MOV     A,M             ;GET BYTE TO A
        STAX    D               ;STORE TO REGISTER RAM
        INX     H
        INX     D
        DCR     B
        JNZ     WRRLP
;
;  Return OK status
WRR80:  XRA     A
        JMP     SEND_STATUS

;===========================================================================
;
;  Run Target:  FN, len
;
;  Uses 4 bytes of stack
;
RUN_TARGET:
;
;  Restore user's page
;;      LDA     REG_PAGE
;;      STA     PAGEIMAGE
;;      OUT     PAGELATCH
;
;  Switch to user stack
        LHLD    REG_SP          ;BACK TO USER STACK
        SPHL

        LHLD    REG_PC          ;USER PC
        PUSH    H               ;SAVE USER PC FOR RET
        LHLD    REG_PSW
        PUSH    H               ;SAVE USER A AND FLAGS FOR POP
;
;  Restore registers
        LHLD    REG_BC
        MOV     B,H
        MOV     C,L
        LHLD    REG_DE
        MOV     D,H
        MOV     E,L
        LHLD    REG_HL
;
;  TODO: if you read interrupt enable state at INT_ENTRY, use the value in REG_IM
;  to restore the state before RET
;        LDA     REG_IM
;        ANI     SOME-KIND-OF-TEST
;        JZ      RUTT10         ;JUMP IF USER INTERRUPTS WERE OFF
;
;  Return to user with interrupts enabled
;        POP     PSW
;        EI                     ;ENABLES AFTER NEXT INSTRUCTION
;        RET
;
;  Return to user with interrupts disabled
RUTT10: POP     PSW
        RET

;===========================================================================
;
;  Common continue point for all monitor entrances
;  HL = user PC, SP = user stack
;  REG_STATE has current state, REG_HL, REG_IM, REG_PSW set
;
;  Uses 2 bytes of stack
;
ENTER_MON:
        SHLD    REG_PC
        LXI     H,0
        DAD     SP
        SHLD    REG_SP          ;SAVE USER'S STACK POINTER
        LXI     SP,MONSTACK     ;AND USE OURS INSTEAD
;
        MOV     H,B
        MOV     L,C
        SHLD    REG_BC
        MOV     H,D
        MOV     L,E
        SHLD    REG_DE
;
;;      LDA     PAGEIMAGE       ;GET CURRENT USER PAGE
        XRA     A               ;...OR NONE IF UNPAGED TARGET
        STA     REG_PAGE        ;SAVE USER PAGE
;
;  Return registers to master
        JMP     RETURN_REGS

;===========================================================================
;
;  Set target byte(s):  FN, len { (page, alow, ahigh, data), (...)... }
;
;  Return has FN, len, (data from memory locations)
;
;  If error in insert (memory not writable), abort to return short data
;
;  This function is used primarily to set and clear breakpoints
;
;  Uses 2 bytes of stack
;
SET_BYTES:
;
        LXI     H,COMBUF_+1
        MOV     B,M             ;LENGTH = 4*NBYTES
        INX     H
        INR     B
        DCR     B
        MVI     C,0             ;C GETS COUNT OF INSERTED BYTES
        JZ      SB90            ;JIF NO BYTES (C=0)
        PUSH    H               ;RETURN BUFFER
;
;  Loop on inserting bytes
SB10:   MOV     A,M             ;MEMORY PAGE
        INX     H
;;      STA     PAGEIMAGE
;;      OUT     PAGELATCH       ;SET PAGE
        MOV     E,M             ;ADDRESS TO DE
        INX     H
        MOV     D,M
        INX     H
;
;  Read current data at byte location
        LDAX    D               ;READ CURRENT DATA
        XTHL
        MOV     M,A             ;SAVE IN RETURN BUFFER
        INX     H
        XTHL
;
;  Insert new data at byte location
        MOV     A,M
        STAX    D               ;SET BYTE
        LDAX    D               ;READ IT BACK
        CMP     M               ;COMPARE TO DESIRED VALUE
        JNZ     SB90            ;BR IF INSERT FAILED: ABORT
        INX     H
        INR     C               ;ELSE COUNT ONE BYTE TO RETURN
;
        DCR     B
        DCR     B
        DCR     B
        DCR     B
        JNZ     SB10            ;LOOP FOR ALL BYTES
;
;  Return buffer with data from byte locations
SB90:   MOV     A,C
        STA     COMBUF_+1        ;SET COUNT OF RETURN BYTES
        POP     H               ;CLEAN STACK
;
;  Compute checksum on buffer, and send to master, then return
        JMP     SEND

;===========================================================================
;
;  Input from port:  FN, len, PortAddressLo, PAhi (=0)
;
IN_PORT:
;
;  Port address is at COMBUF_+2 (and unused high address+3)
;  Build "IN PORT" and "RET" around it.
        MVI     A,IN
        STA     COMBUF_+1
        MVI     A,RET
        STA     COMBUF_+3
;
;  Read port value
        CALL    COMBUF_+1
;
;  Return byte read as "status"
        JMP     SEND_STATUS

;===========================================================================
;
;  Output to port:  FN, len, PortAddressLo, PAhi (=0), data
;
OUT_PORT:
;
;  Port address is at COMBUF_+2, (unused high address+3)
;  Data to write is at COMBUF_+4
;  Build "OUT PORT" and "RET" in combuffer
        MVI     A,OUT
        STA     COMBUF_+1
        MVI     A,RET
        STA     COMBUF_+3
;
;  Get data
        LDA     COMBUF_+4
;
;  Write value to port
        CALL    COMBUF_+1
;
;  Return status of OK
        XRA     A
        JMP     SEND_STATUS
;
;===========================================================================
;  Build status return with value from "A"
;
SEND_STATUS:
        STA     COMBUF_+2        ;SET STATUS
        MVI     A,1
        STA     COMBUF_+1        ;SET LENGTH
;;;     JMP     SEND

;===========================================================================
;  Append checksum to COMBUF_ and send to master
;
;  Uses 6 bytes of stack (not including return address: jumped, not called)
;
SEND:
        ;CALL    0F803h
        CALL    CHECKSUM        ;GET A=CHECKSUM, HL->checksum location
        CMA
        INR     A
        MOV     M,A             ;STORE NEGATIVE OF CHECKSUM
;
;  Send buffer to master
        LXI     H,COMBUF_        ;POINTER TO DATA
        LDA     COMBUF_+1        ;LENGTH OF DATA
        ADI     3               ;PLUS FUNCTION, LENGTH, CHECKSUM
        MOV     B,A             ;save count for loop
SND10:  MOV     A,M
        CALL    PUTCHAR         ;SEND A BYTE (uses 6 bytes of stack)
        INX     H
        DCR     B
        JNZ     SND10
        JMP     MAIN            ;BACK TO MAIN LOOP

;===========================================================================
;  Compute checksum on COMBUF_.  COMBUF_+1 has length of data,
;  Also include function byte and length byte
;
;  Returns:
;       A = checksum
;       HL = pointer to next byte in buffer (checksum location)
;       B is scratched
;
;  Uses 2 bytes of stack including return address
;
CHECKSUM:
        LXI     H,COMBUF_        ;pointer to buffer
        LDA     COMBUF_+1        ;length of message
        ADI     2               ;plus function, length
        MOV     B,A             ;save count for loop
        XRA     A               ;init checksum to 0
CHK10:  ADD     M
        INX     H
        DCR     B
        JNZ     CHK10           ;loop for all
        RET                     ;return with checksum in A
END_CODE:
        ;.dephase

        ;END     RESET

