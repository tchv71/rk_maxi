        .PHASE 80h
        

endpage EQU     0b6h

        lxi     h,0
loop:   mov     m,h
        inr     h
        mov     a,h
        cpi     endpage
        jnz     loop

        lxi     h,0
loop1:  mov     a,m
        cmp     h
        jnz     0f800h
        inr     h
        mov     a,h
        cpi     endpage
        jnz     loop1
        ret

        end
