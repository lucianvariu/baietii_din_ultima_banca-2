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

    cuvant_C        dw 0    ; Variabila C (word 16 biti)

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
     call CALCUL_C         ; ionut
    ; call SORTARE_AFISARE  ; rares
     call ROTIRE_SIR       ; ionut

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


CALCUL_C proc near
    ; PAS 1: Bitii 0-3 (XOR capete)
    xor ax, ax
    lea si, sir_octeti
    mov al, [si]            ; Primul octet
    shr al, 4
    xor bx, bx
    mov bl, lungime_sir
    dec bx
    mov dl, [si+bx]         ; Ultimul octet
    and dl, 0Fh
    xor al, dl
    and al, 0Fh
    mov cuvant_C, ax

    ; PAS 2: Bitii 4-7 (OR intre bitii 2-5)
    xor dx, dx
    xor cx, cx
    mov cl, lungime_sir
    lea si, sir_octeti
L_OR:
    mov al, [si]
    and al, 00111100b       ; Masca 3Ch (bitii 2-5)
    or dl, al
    inc si
    loop L_OR

    shl dl, 2               ; Mutam pe pozitia 4-7
    and dx, 00F0h
    or cuvant_C, dx

    ; PAS 3: Bitii 8-15 (Suma mod 256)
    xor ax, ax
    xor cx, cx
    mov cl, lungime_sir
    lea si, sir_octeti
L_SUM:
    xor bx, bx
    mov bl, [si]
    add ax, bx
    inc si
    loop L_SUM

    mov ah, al              ; Suma mod 256 in AH
    mov al, 0
    or cuvant_C, ax
    ret
CALCUL_C endp

ROTIRE_SIR proc near
    ; Rotire cu N = suma primilor 2 biti
    xor cx, cx
    mov cl, lungime_sir
    lea si, sir_octeti
ROT_L:
    mov al, [si]
    mov bl, al
    and bl, 3               ; Doar ultimii 2 biti
    xor dh, dh
    test bl, 1
    jz CHK_2
    inc dh
CHK_2:
    test bl, 2
    jz DO_R
    inc dh
DO_R:
    cmp dh, 0
    je NXT_R
    push cx                 ; Salvam CX loop
    mov cl, dh              ; N in CL
    rol al, cl              ; Rotire stanga
    pop cx
    mov [si], al
NXT_R:
    inc si
    loop ROT_L
    ret
ROTIRE_SIR endp


 

code ends
end start