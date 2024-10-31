ERR_OK              EQU 0  ; ��� ������
ERR_NO_FILESYSTEM   EQU 1  ; �������� ������� �� ����������
ERR_DISK_ERR        EQU 2  ; ������ ������/������
ERR_NOT_OPENED      EQU 3  ; ����/����� �� �������
ERR_NO_PATH         EQU 4  ; ����/����� �� �������
ERR_DIR_FULL        EQU 5  ; ����� �������� ������������ ���-�� ������
ERR_NO_FREE_SPACE   EQU 6  ; ��� ���������� �����
ERR_DIR_NOT_EMPTY   EQU 7  ; ������ ������� �����, ��� �� �����
ERR_FILE_EXISTS     EQU 8  ; ����/����� � ����� ������ ��� ����������
ERR_NO_DATA         EQU 9  ; fs_file_wtotal=0 ��� ������ ������� fs_write_begin
    
ERR_MAX_FILES       EQU 10 ; �� ������������ �������� ��������, ������
ERR_RECV_STRING     EQU 11 ; �� ������������ �������� ��������, ������
ERR_INVALID_COMMAND EQU 12 ; �� ������������ �������� ��������, ������

ERR_ALREADY_OPENED  EQU 13 ; ���� ��� ������ (fs_swap)

    .phase 100H
    LXI     B,80CAh
    PUSH    B
    CALL    OPEN
    LXI     H,800H
    LXI     D,0F800h
    MVI     A,5
    RET

OPEN:
    PUSH    B
    MVI     D,1 ; O_CREATE
    LXI     H,R
    MVI     A,2
    RET

R:  DB      "TAPE/R.BIN",0
    end
