; SD BIOS for Computer "Radio 86RK" / "Apogee BK01"
; (c) 10-05-2014 vinxru (aleksey.f.morozov@gmail.com)
; (c) 24-10-2024 tchv aka Dmitry Tsvetkov (tchv71@mail.ru)
     .phase 0 

MONITOR         EQU 0F86Ch    ; Адрес собрата в Монитор

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
     ; Первым этапом происходит синхронизация с контроллером
     ; 256 попыток. Для этого в регистр C заносится 0
     MVI    H,0

Boot:
     ; Режим передачи (освобождаем шину) и инициализируем HL
     CALL  SwitchRecv

     JMP   Boot2

;----------------------------------------------------------------------------
; Отправка и прием байта (в HL должен находится USER_PORT)

Rst1:
     JMP GetByte
     NOP
     NOP
     NOP
     NOP
     NOP
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

     ; Начало любой команды (это шина адреса)
Boot2:
     ; Если есть синхронизация, то контроллер ответит STA_START по шине данных
     Rst   1
     CPI   STA_START
     JNZ   RetrySync

     ; Инициализация флешки
     Rst   2
     CPI   STA_OK_DISK
     JNZ   RetrySync

     ; Режим передачи     
     ;Rst   1     
     CALL  SwitchSend

     ; Код команды BOOT
     XRA   A
     SEND_BYTE

     ; Режим приема
     CALL  SwitchRecv

     ; Это ответ команды BOOT
     Rst   2
     CPI   STA_OK_ADDR
     JNZ   RetrySync
     
     ; Адрес загрузки в DE
     Rst   1
     MOV   L, A
     Rst   1
     MOV   H, A

     ; Сохраняем в стек адрес запуска
     PUSH   H

     ; Файл может быть разбит на несколько частей
RecvLoop:
     ; Все части загружены, можно запускать файл.
     Rst   2
     CPI   STA_OK_READ
     JZ    Rst1

     ; Если МК прочитал блок без ошибок, будет передан STA_OK_BLOCK
     CPI   STA_OK_BLOCK
     JNZ   PrintError

     ; Размер блока данных
     Rst   1
     MOV   B, A
     Rst   1
     PUSH  B
     PUSH  D
     MOV   C,B
     ORI   40h
     MOV   B, A

     ; Принимаем блок данных
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
; Повторные попыки

RetrySync:
     ; Попытки
     ;DCR   H
     ;JNZ   Boot
     jmp    0F800H

;----------------------------------------------------------------------------
; Вывод кода ошибки

PrintError:
     CALL  0F815h
     JMP   MONITOR

     include DmaIo.asm

     End

