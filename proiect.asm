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

    msg_sort        db 13, 10, '>> Sirul sortat descrescator: $'
    msg_max_b       db 13, 10, '>> Pozitie octet cu max biti 1 (>3): $'
    msg_C_hex       db 13, 10, '>> Cuvantul C (Hex): $'
    msg_C_bin       db 13, 10, '>> Cuvantul C (Bin): $'
    msg_rot         db 13, 10, '>> Sirul dupa rotiri (Hex): $'
    msg_rot_bin     db 13, 10, '>> Sirul dupa rotiri (Bin): $'
    msg_sp          db ' $'
    msg_none        db ' -$'
    
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
     call SORTARE_AFISARE  ; rares
     call ROTIRE_SIR       ; ionut
     call AFISARE_FINAL_ROTIT  ; rares

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

SORTARE_AFISARE proc near
    ; 1. Afisare C (Calculat de Ionut anterior)
    mov ah, 09h
    lea dx, msg_C_hex
    int 21h
    
    mov ax, cuvant_C
    mov bh, ah
    mov bl, al
    mov al, bh
    call PR_BYTE      ; Afisam partea de sus (High)
    mov al, bl
    call PR_BYTE      ; Afisam partea de jos (Low)
    
    mov ah, 09h
    lea dx, msg_C_bin
    int 21h
    mov ax, cuvant_C
    call PR_WORD_BIN  ; Afisam C in binar

    ; 2. Sortare Bubble Sort Descrescator
    cmp lungime_sir, 1
    jbe GATA_SORT     ; Daca e 0 sau 1 element, nu sortam
    
    xor cx, cx
    mov cl, lungime_sir
    dec cl            ; Loop exterior (N-1)
OUT_S:
    push cx
    lea si, sir_octeti
    mov cl, lungime_sir
    dec cl            ; Loop interior
IN_S:
    mov al, [si]
    mov bl, [si+1]
    cmp al, bl
    jae NO_SW         ; Daca AL >= BL, nu schimba (vrem descrescator)
    mov [si], bl      ; Swap
    mov [si+1], al
NO_SW:
    inc si
    dec cl
    jnz IN_S
    
    pop cx
    loop OUT_S

GATA_SORT:
    ; 3. Afisare Sir Sortat
    mov ah, 09h
    lea dx, msg_sort
    int 21h
    call PRINT_SIR
    
    ; 4. Gasire Max Biti (Statistica)
    call GASIRE_MAX_BITI
    ret
SORTARE_AFISARE endp

AFISARE_FINAL_ROTIT proc near
    mov ah, 09h
    lea dx, msg_rot
    int 21h
    call PRINT_SIR
    
    mov ah, 09h
    lea dx, msg_rot_bin
    int 21h
    
    ; Afisare sir binar extins
    xor cx, cx
    mov cl, lungime_sir
    lea si, sir_octeti
P_BIN_LOOP:
    xor ax, ax
    mov al, [si]
    push cx
    push ax
    call PR_BYTE_BIN_ONLY 
    mov ah, 02h
    mov dl, ' '
    int 21h
    pop ax
    pop cx
    inc si
    loop P_BIN_LOOP
    ret
AFISARE_FINAL_ROTIT endp

GASIRE_MAX_BITI proc near
    xor cx, cx
    mov cl, lungime_sir
    lea si, sir_octeti
    mov bl, 0       ; Max curent
    mov bh, 0       ; Pozitie (index)
    mov dx, 0       ; Index curent (0, 1, 2...)
SCAN:
    mov al, [si]
    push cx
    mov cx, 8
    xor ah, 0       ; Contor biti de 1 pentru numarul curent
CNT:
    shr al, 1
    jnc NOT_1
    inc ah
NOT_1:
    loop CNT
    pop cx
    
    ; Verificam conditia > 3
    cmp ah, 3
    jbe SKIP_MAX    ; Daca are <= 3 biti, nu ne intereseaza
    
    cmp ah, bl
    jbe SKIP_MAX    ; Daca nu e mai mare decat maximul gasit pana acum
    mov bl, ah      ; Noul maxim
    mov bh, dl      ; Noua pozitie
SKIP_MAX:
    inc si
    inc dx          ; Crestem indexul
    dec cl
    jnz SCAN
    
    mov ah, 09h
    lea dx, msg_max_b
    int 21h
    
    cmp bl, 0       
    je NO_RES
    mov al, bh
    inc al          ; Afisam pozitia 1-based (nu de la 0)
    call PR_BYTE
    ret
NO_RES:
    mov ah, 09h
    lea dx, msg_none
    int 21h
    ret
GASIRE_MAX_BITI endp

; --- HELPERE AFISARE ---
PRINT_SIR proc near
    xor cx, cx
    mov cl, lungime_sir
    lea si, sir_octeti
P_LOOP:
    mov al, [si]
    push cx
    call PR_BYTE
    mov ah, 02h
    mov dl, ' '
    int 21h
    pop cx
    inc si
    loop P_LOOP
    ret
PRINT_SIR endp

PR_BYTE proc near
    push ax
    push bx
    push dx
    mov bl, al
    mov dl, al
    shr dl, 4
    call PR_DIG
    mov dl, bl
    and dl, 0Fh
    call PR_DIG
    pop dx
    pop bx
    pop ax
    ret
PR_BYTE endp

PR_DIG proc near
    cmp dl, 9
    jbe IS_N
    add dl, 7
IS_N:
    add dl, '0'
    mov ah, 02h
    int 21h
    ret
PR_DIG endp

PR_WORD_BIN proc near
    push cx
    push bx
    push dx
    mov cx, 16
    mov bx, ax
WB_L:
    shl bx, 1
    mov dl, '0'
    adc dl, 0
    mov ah, 02h
    int 21h
    loop WB_L
    pop dx
    pop bx
    pop cx
    ret
PR_WORD_BIN endp

PR_BYTE_BIN_ONLY proc near
    push cx
    push bx
    push dx
    mov cx, 8
    mov bl, al
BB_L:
    shl bl, 1
    mov dl, '0'
    adc dl, 0
    mov ah, 02h
    int 21h
    loop BB_L
    pop dx
    pop bx
    pop cx
    ret
PR_BYTE_BIN_ONLY endp


 

code ends
end start