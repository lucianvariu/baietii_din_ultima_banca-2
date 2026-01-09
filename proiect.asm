assume cs:code, ds:data, ss:stiva

data segment
    
data ends



code segment
start:
    
    mov ax, data
    mov ds, ax
    
    
    mov ax, 4c00h
    int 21h

 

code ends
end start