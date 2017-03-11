; rhinoceros - Christophe Guieu
; Practical Reverse Engineering
; Exercice 01
; Question 2
; code_122.asm

SECTION .data
SECTION .text
GLOBAL _start
_start:
        nop
        jmp 0xaabbccdd
