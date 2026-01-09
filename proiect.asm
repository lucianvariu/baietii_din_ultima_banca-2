assume cs:code, ds:data, ss:stiva

stiva segment stack
    dw 256 dup(?)
    top_stiva label word
stiva ends


data segment
    ;luci
    ;ionut
    ;rares
    msg_test db 'Proiect initializat cu succes!', 13, 10, '$'
data ends



code segment
start:
    
    mov ax, data
    mov ds, ax
    
    mov ax, stiva
    mov ss, ax
    lea sp, top_stiva

    ; --- Test ca merge scheletul ---
    mov ah, 09h
    lea dx, msg_test
    int 21h

    ; call CITIRE_DATE      ; luci
    ; call CALCUL_C         ; ionut
    ; call SORTARE_AFISARE  ; rares
    ; call ROTIRE_SIR       ; ionut

    mov ax, 4c00h
    int 21h

 

code ends
end start