; rhinoceros - Christophe Guieu
; Practical Reverse Engineering
; Exercice 01
; Question 2
; code_121.asm

SECTION .data
SECTION .text
GLOBAL _start
_start:
        nop
        push 008048061h
        ret
        xor ebx, ebx
        mov eax, 1
        int 080h
