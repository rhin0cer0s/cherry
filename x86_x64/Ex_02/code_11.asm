; rhinoceros - Christophe Guieu
; Practical Reverse Engineering
; Exercice 01
; Question 1
; code_11.asm

SECTION .data
SECTION .text
GLOBAL _start
_start:
	nop
        call get_eip
        mov ebx, eax
	mov eax, 1 
	int 080h

get_eip:
        mov eax, [esp]
        ret
