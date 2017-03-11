### Given what you learned about ```CALL``` and ```RET```, explain how you would read the value ```EIP```? Why can't you just do ```MOV EAX, EIP```?

```EIP``` is an internal register. This means that it is solely used by the
processor and is not accessible by general instructions.

The easiest way to read ```EIP``` value is by using the ```CALL``` instruction.
Since it pushes the current ```EIP``` value to the stack - which will be used by
```RET``` later to get back on track. It is precisely pushed at ```RSP```
address. Once on the stack it is easy to read it using ```MOV EBX, [ESP]```.

```
SECTION .data
SECTION .text
GLOBAL _start
_start:
	nop
        call get_eip    ; Call to get_eip function
        mov ebx, eax
	mov eax, 1 
	int 080h

get_eip:
        mov eax, [esp]  ; Reads EIP on the stack at ESP address, puts it in EAX
        ret             ; Returns
```

Using a debugger, it is possible to get registers value and so monitor ```EAX```
value. ```radare2``` is able to do this:

```
[0x08048062]> pd 7; dr=
|           0x08048062      0900           or dword [eax], eax
|           0x08048064      0000           add byte [eax], al
|           ;-- eax:
|           0x08048066      89c3           mov ebx, eax
|           0x08048068      b801000000     mov eax, 1
|           ; CALL XREF from 0x08048061 (fcn.08048061)
|           0x0804806d      cd80           int 0x80
|           ;-- get_eip:
|           0x0804806f      8b0424         mov eax, dword [esp]
            ;-- eip:
            0x08048072      c3             ret
eip 0x08048072     oeax 0xffffffff      eax 0x08048066  ebx 0x00000000
ecx 0x00000000      edx 0x00000000      esp 0xffb4a31   ebp 0x00000000
esi 0x00000000      edi 0x00000000      eflags 1I 
```

On this ```r2``` dump we can see that current ```EIP``` is ```0x08048072```, this
means that instruction at ```0x08048072``` is the _next_ instruction to be 
executed. It corresponds to the ```RET``` instruction in ```get_eip```. It is 
just after the ```MOV EAX, [ESP]```. ```EAX``` is now sets to ```0x08048066``` 
which corresponds to ```EIP``` value when ```CALL get_eip``` has been executed 
and it is the address ```EIP``` will be set at during the ```RET```instruction.

Note : This little piece of software is _supposed_ to returns ```EIP``` value.

```
~/cherry/x86_x64/Ex_02(master*) » ./code                        rhinoceros@worm
------------------------------------------------------------
~/cherry/x86_x64/Ex_02(master*) » echo $?                       rhinoceros@worm
102
```

It does not. ```0x08048066 = 134512742```, because in fact POSIX norm states that
_[only the least significant 8 bits shall be
available](http://pubs.opengroup.org/onlinepubs/9699919799/)_. Since ```0x66 =
102``` this result is normal.

### Come up with at least two code sequences to set ```EIP``` to ```0xAABBCCDD```.

#### Pushing ```0xAABBCCDD``` onto the stack and calling ```RET``` will also do the trick

```
; code_121.asm
SECTION .data
SECTION .text
GLOBAL _start
_start:
        nop
        push 0AABBCCDDh ; push 0xAABBCCDD onto the stack
        ret             ; pop a value from the stack and set EIP to it
        xor ebx, ebx
        mov eax, 1
        int 080h
```
Let's execute it :
```
------------------------------------------------------------
~/cherry/x86_x64/Ex_02(master*) » ./code_12                     rhinoceros@worm
[1]    3849 segmentation fault  ./code_12
```
Well that is awkward but not _that_ surprising. Since ```EIP``` is set to an
incoherent and most likely uninitialized memory address. A simple attempt would
be to push a coherent and initialized memory address. For example a previous
one:

```
        push 008048061h
        ret
```
```
------------------------------------------------------------
~/cherry/x86_x64/Ex_02(master*) » ./code_121                    rhinoceros@worm
^C
------------------------------------------------------------
~/cherry/x86_x64/Ex_02(master*) »                               rhinoceros@worm
```
This time the execution is blocked in an infinite loop. I had to ```^C``` it. It
is not surprising since :
```
0x08048061      68ddccbbaa     push 0xaabbccdd
```
So we can simulate some kind of ```JUMP``` with this trick. Let's dive into it
with ```radare2``` :
```
[0x08048060]> pd 6
            ;-- entry0:
            ;-- section..text:
            ;-- _start:
            ;-- skip:
            0x08048060      90              nop
┌ (fcn) fcn.08048061 6
│   fcn.08048061 ();
│           0x08048061      68ddccbbaa      push 0xaabbccdd
|           ;-- eip:
└           0x08048066 b    c3              ret 
            0x08048067      31db            xor ebx,  ebx
            0x08048069      b801000000      mov eax,  1
            0x0804806e      cd80            int 0x80
[0x08048060]> dr=
eip 0x08048066     oeax 0xffffffff      eax 0x00000000      ebx 0x00000000
ecx 0x00000000      edx 0x00000000      esp 0xffd4f0cc      ebp 0x00000000
esi 0x00000000      edi 0x00000000      eflags 1I
```
This dump has been done at ```0x08048066```, just after pushing ```0xaabbccdd```
onto the stack and before the ```RET``` instruction. Let's check that it has 
correctly been written:

```
[0x08048060]> pfS@esp
0xffd4f0cc = 0xffd4f0cc -> 0xaabbccdd
```

Everything is in place to overwrite ```EIP```:

```
[0x08048060]> ds
[0xaabbccdd]> dr=
eip 0xaabbccdd     oeax 0xffffffff      eax 0x00000000      ebx 0x00000000
ecx 0x00000000      edx 0x00000000      esp 0xffd4f0d0      ebp 0x00000000
esi 0x00000000      edi 0x00000000      eflags 1I
```

```EIP``` has been set to ```0xaabbccdd```, success! What will happen if we keep
on going with the execution? :

```
[0xaabbccdd]> pd 7
            ;-- eip:
            ; DATA XREF from 0x08048061 (fcn.08048061)
            0xaabbccdd      ff             invalid
[0xaabbccdd]> ds
child stopped with signal 11
[+] SIGNAL 11 errno=0 addr=0xaabbccdd code=1 ret=0
```

Next execution is supposed to happen at ```0xaabbccdd``` which is uninitialized,
the ```SEGFAULT``` is real...

#### ```JUMP```

```JUMP``` instruction allow to jump to any memory address :

```
; code_122.asm

SECTION .data
SECTION .text
GLOBAL _start
_start:
        nop
        jmp 0xaabbccdd
```

```
------------------------------------------------------------
~/cherry/x86_x64/Ex_02(master*) » ./code_122                    rhinoceros@worm
[1]    4447 segmentation fault  ./code_122
```

Not surprising once again. Let's start ```radare2```:

```
[0x08048060]> dr=
eip 0x08048061     oeax 0x0000003b      eax 0x00000000      ebx 0x00000000
ecx 0x00000000      edx 0x00000000      esp 0x00178000      ebp 0x00178000
esi 0x00000000      edi 0x00000000      eflags I           
```

This is before the ```JMP``` instruction. Nothing to report.

```
[0x08048060]> ds
[0xaabbccdd]> dr=
eip 0xaabbccdd     oeax 0xffffffff      eax 0x00000000      ebx 0x00000000
ecx 0x00000000      edx 0x00000000      esp 0x00178000      ebp 0x00178000
esi 0x00000000      edi 0x00000000      eflags 1I          
[0xaabbccdd]> ds
child stopped with signal 11
[+] SIGNAL 11 errno=0 addr=0xaabbccdd code=1 ret=0
```
As forcasted ```EIP``` has been set to ```0xaabbccdd``` and the ```SEGFAULT```
happened.

- In the example function ```addme```, what would happen if the stack pointer
  were not properly restored before executing ```RET```?

The execution would not get back on track and this lead to an undefined state.
At best it produces a ```SEGFAULT``` as shown before, worst case is the control
flow hijacked in order to execute malicious instructions.

- In all of the calling conventions explained, the return value is stored in a
  32-bit register (```EAX```). What happens when the return value does not fit
  in a 32-bit register? Write program to experiment and evaluate your answer.
  Does the mechanism change from compiler to compiler?

When the return value does not fit it is truncated, this situations is called an
```overflow``` and raised a special flag ```OF``` in ```RFLAGS```. This is a
dangerous situations and can be used to get around control flow instruction and
hijack the execution flow.
