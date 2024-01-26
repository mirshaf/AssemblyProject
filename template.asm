;Each word is 2 bytes
;Do not forget to make the stack pointer 16-aligned before calling a libc function!
;Strings should be null terminated (is this important?)

global asm_main

extern printf
extern putchar
extern puts
extern scanf
extern sscanf
extern getchar


segment   .data
print_int_format: db "%ld", 0
read_int_format: db "%ld", 0
scan_string_format: db "%s", 0
example_number: db 4, 0, 1, 0, 9, 0
example_number_2: db 4, 0, 2, 3, 4, 0


;A signed 256-bit integer has less than 78 digits. We will represent each digit by a character. 77 digits + 1 sign + 1 null termination = 79 bytes
%define SIZE 85
segment .bss
scan_string_buffer: resb SIZE
string_2: resb SIZE
; ll_10: resq 1 ;long long 1 0
; ll_11: resq 1
; ll_12: resq 1
; ll_13: resq 1
; ll_1_s: resb 1 ;the sign of the first long long
; ll_20: resq 1
; ll_21: resq 1
; ll_22: resq 1
; ll_23: resq 1
; ll_2_s: resb 1

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

; read_int256:
;     push r12
;     push r13
;     push r14

;     mov r13, rdi ;The memory address in which the string should be written

;     xor r12, r12 ;index
;     read_char_by_char:
;         call getchar
;         cmp rax, 10
;         je newline_encountered
;         mov byte [r13 + r12], al
;         inc r12
;         jmp read_char_by_char
;     newline_encountered:
;     mov byte [r13 + r12], 0

;     mov rax, r12 ;return the length of the input

;     pop r14
;     pop r13
;     pop r12

;     ret

; read_int256_2:
;     push rbp
;     push rbx
;     push r12
;     push r13
;     push r14
;     push r15

;     sub rsp, 8

;     mov r12, rdi ;4 quadwords
;     mov r13, rsi
;     mov r14, rdx
;     mov r15, rcx
;     mov rbp, r8 ;sign

;     mov rdi, scan_string_format
;     mov rsi, scan_string_buffer
;     mov rax, 1
;     call scanf

;     xor al, al ;sign-bit
;     xor rbx, rbx ;index
;     cmp byte [scan_string_buffer], '-'
;     jne positive
;     mov al, 1 ;the number is negative
;     positive:
;     cmp byte [scan_string_buffer], '+'
;     jne sign_applied
;     inc rbx
;     sign_applied:
;     mov byte [rbp], al

;     read_loop:
;         cmp [scan_string_buffer + rbx], 0
;         je read_end


;         inc rbx
;     read_end:


;     add rsp, 8

;     pop r15
;     pop r14
;     pop r13
;     pop r12
;     pop rbx
;     pop rbp

;     ret

;an example number: 4, 0, "109", 0 == length, sign, number, null-termination
add_string:
    push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15

    sub rsp, 8

    movzx r12, byte [rdi] ;len1
    movzx r14, byte [rsi] ;len2

    ;len3:
    mov r10, r12
    cmp r12, r14
    jge len3_calculated
    mov r10, r14
    len3_calculated:
    inc r10
    mov byte [rdx], r10b
    mov byte [rdx + r10 + 1], 0 ;rdx has the address in which the answer should be written

    xor r15, r15 ;carry or borrow
    movzx rbx, byte [rsi + 1]
    movzx rcx, byte [rdi + 1]
    cmp rbx, rcx ;compare signs
    je add_loop
    jmp sub_loop

    
    add_loop:
        cmp r12, 1
        jle first_num_done
        cmp r14, 1
        jle second_num_done
        movzx r8, byte [rdi + r12]
        add r8b, byte [rsi + r14]
        ; sub r8, 96 ; '0' = 48
        add r8, r15
        cmp r8, 10
        jl no_carry
            mov r15, 1
            sub r8, 10
            jmp carry_calculated
        no_carry:
            xor r15, r15
        carry_calculated:
        ; add r8, 48 ; '0' = 48
        mov byte [rdx + r10], r8b
        dec r10
        dec r12
        dec r14
        jmp add_loop
    first_num_done:
        cmp r14, 1
        jle adding_done
        movzx r8, byte [rsi + r14]
        add r8, r15
        cmp r8, 10
        jl no_carry2
            mov r15, 1
            sub r8, 10
            jmp carry_calculated2
        no_carry2:
            xor r15, r15
        carry_calculated2:
        mov byte [rdx + r10], r8b
        dec r10
        dec r14
        jmp first_num_done
    second_num_done:
        cmp r12, 1
        jle adding_done
        movzx r8, byte [rdi + r12]
        add r8, r15
        cmp r8, 10
        jl no_carry3
            mov r15, 1
            sub r8, 10
            jmp carry_calculated3
        no_carry3:
            xor r15, r15
        carry_calculated3:
        mov byte [rdx + r10], r8b
        dec r10
        dec r12
        jmp second_num_done
    adding_done:
        cmp r15, 0
        je carry_done
        mov byte [rdx + r10], r15b
        dec r10
        carry_done:
        movzx rbx, byte [rdi + 1]
        mov byte [rdx + 1], bl
        jmp remove_leading_zeros


    sub_loop:
        ;todo
    
    remove_leading_zeros:
        ;todo
    

    add rsp, 8

	pop r15
	pop r14
	pop r13
	pop r12
    pop rbx
    pop rbp

    ret

special_print:
    push r12
    push r13
    push r14

    mov r12, rdi
    movzx r13, byte [rdi]
    mov r14, 2
    print_loop:
    cmp r14, r13
    jg print_done
    movzx rdi, byte [r12 + r14]
    add rdi, 48
    call putchar

    inc r14
    jmp print_loop

    print_done:
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

    mov rdi, example_number
    mov rsi, example_number_2
    mov rdx, string_2
    call add_string
    mov rdi, string_2
    call special_print

    ;--------------------------

    add rsp, 8

	pop r15
	pop r14
	pop r13
	pop r12
    pop rbx
    pop rbp

	ret
