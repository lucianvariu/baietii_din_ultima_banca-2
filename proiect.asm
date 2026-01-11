assume cs:code, ds:data, ss:stiva

stiva segment stack
    dw 256 dup(?)
    top_stiva label word
stiva ends


data segment

    msg_input       db 13, 10, '>> Introduceti octeti HEX (ex: 3F 7A 12): $'
    msg_err_len     db 13, 10, '!! EROARE: Intre 8 si 16 valori! $'
    
    buffer_citire   db 100, ?, 100 dup(?) 
    sir_octeti      db 20 dup(0)          
    lungime_sir     db 0                 


    ;ionut
    ;rares
    
data ends



code segment
start:
    
    mov ax, data
    mov ds, ax
    
    mov ax, stiva
    mov ss, ax
    lea sp, top_stiva


     call CITIRE_DATE      ; luci
    ; call CALCUL_C         ; ionut
    ; call SORTARE_AFISARE  ; rares
    ; call ROTIRE_SIR       ; ionut

    mov ax, 4c00h
    int 21h

    CITIRE_DATE proc near
REPET_CITIRE:
    mov ah, 09h
    lea dx, msg_input
    int 21h

    ; Citire text (INT 21h, 0Ah)
    mov ah, 0ah
    lea dx, buffer_citire
    int 21h
    
    ; Conversie ASCII -> Valori numerice
    xor cx, cx              ; Contor octeti
    xor si, si              ; Index buffer
    xor bx, bx
    mov bl, buffer_citire[1]; Lungimea citita
    lea di, sir_octeti      
    
    mov si, 0
PARSE_L:
    cmp si, bx
    jae END_P
    
    mov al, buffer_citire[si+2]
    cmp al, ' '      
    je SKIP_C
    cmp al, 13       
    je END_P
    
    call HEX_TO_VAL
    shl al, 4
    mov dl, al       ; High nibble
    
    inc si
    cmp si, bx
    jae SAVE_LAST
    
    mov al, buffer_citire[si+2]
    cmp al, ' '
    je SINGLE
    cmp al, 13
    je SINGLE_LAST
    
    call HEX_TO_VAL
    or dl, al        ; Low nibble
    jmp STORE
    
SINGLE:
    shr dl, 4
    dec si
    jmp STORE
SINGLE_LAST:
    shr dl, 4
    jmp STORE
    
STORE:
    mov [di], dl
    inc di
    inc cl
SKIP_C:
    inc si
    jmp PARSE_L
    
SAVE_LAST:
    shr dl, 4
    mov [di], dl
    inc cl
    
END_P:
    mov lungime_sir, cl
    ; Validare 8-16 elemente
    cmp cl, 8
    jb ERR_L
    cmp cl, 16
    ja ERR_L
    ret

ERR_L:
    mov ah, 09h
    lea dx, msg_err_len
    int 21h
    jmp REPET_CITIRE
CITIRE_DATE endp

HEX_TO_VAL proc near
    cmp al, '9'
    jbe IS_D
    cmp al, 'F'
    jbe IS_U
    sub al, 'a'
    add al, 10
    ret
IS_U:
    sub al, 'A'
    add al, 10
    ret
IS_D:
    sub al, '0'
    ret
HEX_TO_VAL endp

 

code ends
end start