;Each word is 2 bytes
;Do not forget to make the stack pointer 16-aligned before calling a libc function!
;Strings should be null terminated (is this important?)

global asm_main

extern printf
extern putchar
extern puts
extern scanf
extern getchar


segment   .data
print_int_format: db "%ld", 0
read_int_format: db "%ld", 0


;a 256 bit integer has less than 78 digits. We will represent each digit by a character.
%define SIZE 80
segment .bss
big_num_1: resb SIZE
big_num_2: resb SIZE

segment .text

;---------------------------------------------------------------------------
print_int:
    sub rsp, 8

    mov rsi, rdi

    mov rdi, print_int_format
    mov rax, 1 ; setting rax (al) to number of vector inputs
    call printf
    
    add rsp, 8 ; clearing local variables from stack

    ret


print_nl:
    sub rsp, 8

    mov rdi, 10
    call putchar
    
    add rsp, 8 ; clearing local variables from stack

    ret


read_int:
    sub rsp, 8

    mov rsi, rsp
    mov rdi, read_int_format
    mov rax, 1 ; setting rax (al) to number of vector inputs
    call scanf

    mov rax, [rsp]

    add rsp, 8 ; clearing local variables from stack

    ret
read_int256:
    push r12
    push r13
    push r14

    mov r13, rdi ;The memory address in which the string should be written

    xor r12, r12 ;index
    read_char_by_char:
        call getchar
        cmp rax, 10
        je newline_encountered
        mov byte [r13 + r12], al
        inc r12
        jmp read_char_by_char
    newline_encountered:
    mov byte [r13 + r12], 0

    mov rax, r12 ;return the length of the input

    pop r14
    pop r13
    pop r12

    ret


;---------------------------------------------------------------------------


asm_main:
	push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15

    sub rsp, 8

    ; -------------------------
    ; write your code here

    mov rdi, big_num_1
    call read_int256
    mov rdi, big_num_2
    call read_int256

    ;--------------------------

    add rsp, 8

	pop r15
	pop r14
	pop r13
	pop r12
    pop rbx
    pop rbp

	ret
