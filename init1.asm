	.8080
	LXI H,BEGPRO+1 ; �������� � hl ����� ��������
		     ; ������� out ��� ����������� ����������
		     ; �������� � out 00
	mvi	a,0c4h
	out	-1
	MVI B,0FEH    ; � - �������, � � ����� ����� ������
	MVI A,0
	CALL BEGPRO  ; ������ 0000�7FFF � ���

	mvi	a,0a4h
	out	-1

	MVI	M,0
	MVI B,0FEH    ; � - �������, � � ����� ����� ������
	MVI A,0
	CALL BEGPRO  ; ������ 0000�7FFF � ���

	mvi	a,0;6
	out	0cch

	mvi	a,80h
	out	-1
	lxi	h,0cc03h
	mvi	m,36h
	mvi	m,76h
	mvi	m,0b6h

	jmp	0f800h


BEGPRO:
	OUT 0
	INR M
	DCR B
	RZ
	JMP BEGPRO

	end
