; SD BIOS for Computer "Radio 86RK" / "Apogee BK01"
; (c) 10-05-2014 vinxru (aleksey.f.morozov@gmail.com)
; (c) 24-10-2024 tchv aka Dmitry Tsvetkov (tchv71@mail.ru)
     .phase 0 

MONITOR         EQU 0F86Ch    ; Адрес собрата в Монитор
VT37            EQU 1

; Коды передаваемые микроконтроллером

STA_START       EQU 040h ; МК переключен в режим приема команд
STA_WAIT        EQU 041h ; МК выполняет команду
STA_OK_DISK     EQU 042h ; Накопитель исправен, микроконтроллер готов к приему команды
STA_OK          EQU 043h ; Команда выполнена
STA_OK_READ     EQU 044h ; МК готов передать следующий блок данных
STA_OK_ADDR     EQU 047h ; МК готов передать адрес загрузки
STA_OK_BLOCK    EQU 04Fh 
;BUF             EQU 0D8h
;----------------------------------------------------------------------------
; Точка входа

Entry:
Boot:
     ; Режим передачи (освобождаем шину) и инициализируем HL
     ;CALL  SwitchRecv
     CALL   Boot2 ; Если вернется - произошла ошибка
;----------------------------------------------------------------------------
; Повторные попыки

     jmp    0F800H
     NOP
     NOP
;----------------------------------------------------------------------------
; Отправка и прием байта (в HL должен находится USER_PORT)

Rst1:
     PUSH  D
     PUSH  B
     CALL  Recv
     POP   B
     POP   D
     RET
;----------------------------------------------------------------------------
; Ожидание готовности МК

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
IFNDEF VT37
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
ELSE
     LXI   H,0C60CH
     MOV   M,A
     MVI   L,0AH
     MVI   M,5 ; Stop channel 1

     MVI   L,2
     MOV   M,E
     MOV   M,D
     DCX   B
     INX   H
     MOV   M,C
     MOV   M,B
     INX   B

     MVI   L,0Bh
     ;ORI   1
     MOV   M,A
IF 1
     MVI   L,8
     MVI   M,20h
ENDIF
     MVI   L,0Ah
     MVI   M,1 ; Start channel 1
     MVI   L,8
ENDIF
WAIT_DMA:
     MOV   A,M
     ANI   2
     JZ    WAIT_DMA
     POP   H
     RET

;----------------------------------------------------------------------------
     ; Начало любой команды (это шина адреса)
Boot2:
     MVI    H,1
     ; Если есть синхронизация, то контроллер ответит STA_START по шине данных
     Rst   1
     CPI   STA_START
     RNZ; JNZ   RetrySync

     ; Инициализация флешки
     Rst   2
     CPI   STA_OK_DISK
     RNZ; JNZ   RetrySync

     ; Режим передачи     
     ;Rst   1     
     ;CALL  SwitchSend

     ; Код команды BOOT
     XRA   A
Send:
     LXI   D,OUTCHAR
     STAX  D
     DCX   D
     DCX   D
     ;MVI   A,1
     ;@out  SD
IFNDEF VT37
     LXI   B,8002H
ELSE
     LXI   B,2
     MVI   A,8+1
ENDIF
     ;CALL  SET_DMAW
     RST   3
     INX   D
     INX   D
     DCR   C
IFDEF VT37
     MVI   A,8+1
ENDIF
     RST   3
     ;ORA   A

     ; Режим приема
     ;CALL  SwitchRecv

     ; Это ответ команды BOOT
     Rst   2
     CPI   STA_OK_ADDR
     RNZ; JNZ   RetrySync
     
     ; Адрес загрузки в DE
     Rst   1
     MOV   E, A
     Rst   1
     MOV   D, A

     ; Сохраняем в стек адрес запуска
     PUSH   D

     ; Файл может быть разбит на несколько частей
RecvLoop:
     ; Все части загружены, можно запускать файл.
     Rst   2
     CPI   STA_OK_READ
     RZ;    Rst1

     ; Если МК прочитал блок без ошибок, будет передан STA_OK_BLOCK
     CPI   STA_OK_BLOCK
     RNZ; JNZ   PrintError

     ; Размер блока данных
     Rst   1
     MOV   C, A
     Rst   1
     MOV   B, A
IFNDEF VT37
     PUSH  B
     ORI   40h
     MOV   B, A
ELSE
     MVI   A,4+1
ENDIF
     ; Принимаем блок данных
     RST   3; CALL  SET_DMA
     XCHG
     DAD   B
     XCHG
     JMP   RecvLoop


;----------------------------------------------------------------------------
; Вывод кода ошибки

;PrintError:
;     CALL  0F815h
;     JMP   MONITOR


Recv:
     LXI   D,OUTCHAR
IFNDEF VT37
     LXI   B,4001H
ELSE
     LXI   B,1
     MVI   A,4+1
ENDIF
     DCR   H
     JNZ   Recv01
     INR   C
     RST   3
     DCR   C
     LDAX  D
     MOV   H,A
IFDEF VT37
     MVI   A,4+1
ENDIF
Recv01:
     ;CALL  SET_DMAW
     RST   3
     LDAX  D
     ;ORA   A ; Clear C-flag
     RET

     DW 1
OUTCHAR: DS 2

     End

