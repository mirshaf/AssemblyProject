align 32
segment .data
align 32
io_int_format: db         "%ld", 0
align 32
read_float_format: db "%f", 0
align 32
print_float_format: db "%.3f ", 0
align 32
impossible: db "Impossible", 0
align 32
positive_epsilon: dd 0.0001
negative_epsilon: dd -0.0001

align 32
segment .bss
align 32
matrix: resd 1001008
align 32
solution: resd 1008
align 32
n: resq 1

segment .text
    extern printf
    extern putchar
    extern puts
    extern scanf
    extern getchar
    global asm_main

;-------------------------------------------------------------------
print_int:
    sub rsp, 8

    mov rsi, rdi

    mov rdi, io_int_format
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
    mov rdi, io_int_format
    mov rax, 1 ; setting rax (al) to number of vector inputs
    call scanf

    mov rax, [rsp]

    add rsp, 8 ; clearing local variables from stack

    ret

read_float:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 16
    
    lea     rax, [rbp-4]
    mov     rsi, rax
    mov     edi,read_float_format
    mov     eax, 0
    call    scanf
    movss   xmm0, DWORD [rbp-4]

    leave
    ret

print_float:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 16

    movss   DWORD [rbp-4], xmm0
    pxor    xmm1, xmm1
    cvtss2sd        xmm1, DWORD [rbp-4]
    movq    rax, xmm1
    movq    xmm0, rax
    mov     edi, print_float_format
    mov     eax, 1
    call    printf

    leave
    ret

read_input:
    push    r12
    push    r13
    push    r14
    push    r15
    push    rbx
    push    rbp
    mov     rbp, rsp
    sub     rsp, 24
    ; -------------------------
    call    read_int
    mov     DWORD [n], eax
    mov     r12, 0 ;row_index
    input_loop:
        mov     eax, DWORD [n]
        cmp     r12d, eax
        jge      end_input
        mov     eax, DWORD [n]
        lea     edx, [rax+1]
        mov     eax, r12d ;origin
        imul    eax, edx
        mov     r14d, eax
        mov     r13, 0 ;column_index
        
    read_row:
        mov     eax, DWORD [n]
        cmp     r13d, eax
        jg     end_row
        mov     edx, r14d
        mov     eax, r13d
        lea     ebx, [rdx+rax]
        call    read_float
        movd    eax, xmm0
        movsx   rdx, ebx ;move with sign extension
        mov     matrix[rdx*4], eax
        add     r13d, 1
        jmp read_row
    end_row:
        add     r12, 1
        jmp input_loop
    end_input:
    ;--------------------------
    leave
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    ret

print_matrix:
    push    r12
    push    r13
    push    r14
    push    r15
    push    rbx
    push    rbp
    mov     rbp, rsp
    sub     rsp, 24
    ; -------------------------
    mov     r12, 0 ;row_index
    print_row_loop:
        mov     eax, DWORD [n]
        cmp     r12d, eax
        jge      end_print
        mov     eax, DWORD [n]
        lea     edx, [rax+1]
        mov     eax, r12d
        imul    eax, edx ;origin
        mov     r14d, eax
        mov     r13, 0 ;column_index
    print_column_loop:
        mov     eax, DWORD [n]
        cmp     r13d, eax
        jg     end_print_column
        mov     edx, r14d
        mov     eax, r13d
        add     eax, edx
        cdqe ;convert double to quad
        mov     eax, DWORD [matrix+rax*4]
        movd    xmm0, eax
        call    print_float
        add     r13, 1
        jmp print_column_loop
    end_print_column:
        call    print_nl
        add     r12, 1
        jmp print_row_loop
    end_print:    
    ;--------------------------
    leave
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    ret

eliminate_row_by_subtraction:
    push    r12
    push    r13
    push    r14
    push    r15
    push    rbx
    push    rbp
    mov     rbp, rsp
    sub     rsp, 24
    ; -------------------------
    ;row2 -= factor * row1
    mov     r12d, edi ;row_1
    mov     r13d, esi ;row_2
    mov     eax, DWORD [n]
    lea     edx, [rax+1]
    mov     eax, r12d
    imul    eax, edx
    mov     r14d, eax ;origin_1
    mov     eax, DWORD [n]
    lea     edx, [rax+1]
    mov     eax, r13d
    imul    eax, edx
    mov     r15d, eax ;origin_2
    mov     edx, r15d
    mov     eax, r12d
    add     eax, edx
    cdqe ;convert double to quad
    movss   xmm0, DWORD [matrix+rax*4]
    mov     edx, r14d
    mov     eax, r12d
    add     eax, edx
    cdqe
    movss   xmm1, DWORD [matrix+rax*4] ;pivot
    ;make sure pivot!=0 before calling this function.
    divss   xmm0, xmm1
    movss   DWORD [rbp-20], xmm0 ;factor
    mov     rbx, 0 ;index
    jmp     end_row_elimination
    row_elimination_loop:
        mov     edx, r15d
        mov     eax, ebx
        add     eax, edx
        cdqe
        movss   xmm0, DWORD [matrix+rax*4]
        mov     edx, r14d
        mov     eax, ebx
        add     eax, edx
        cdqe
        movss   xmm1, DWORD [matrix+rax*4]
        mulss   xmm1, DWORD [rbp-20]
        mov     edx, r15d
        mov     eax, ebx
        add     eax, edx
        subss   xmm0, xmm1
        cdqe
        movss   DWORD [matrix+rax*4], xmm0
        add     rbx, 1
    end_row_elimination:
        mov     eax, DWORD [n]
        cmp     ebx, eax
        jle     row_elimination_loop
    ;--------------------------
    leave
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    ret

swap_rows:
    push    r12
    push    r13
    push    r14
    push    r15
    push    rbx
    push    rbp
    mov     rbp, rsp
    sub     rsp, 24
    ; -------------------------
    mov     r12d, edi ;row_1
    mov     r13d, esi ;row_2
    mov     eax, r12d
    cmp     eax, r13d
    je      no_swap_needed
    mov     eax, DWORD [n]
    lea     edx, [rax+1]
    mov     eax, r12d
    imul    eax, edx
    mov     r14d, eax ;origin_1
    mov     eax, DWORD [n]
    lea     edx, [rax+1]
    mov     eax, r13d
    imul    eax, edx
    mov     r15d, eax ;origin_2
    mov     ebx, 0 ;index
    jmp     end_row_swap
    row_swap_loop:
        mov     edx, r14d
        mov     eax, ebx
        add     eax, edx
        cdqe
        movss   xmm0, DWORD [matrix+rax*4]
        movss   DWORD [rbp-24], xmm0 ;temp
        mov     edx, r15d
        mov     eax, ebx
        add     eax, edx
        mov     ecx, r14d
        mov     edx, ebx
        add     edx, ecx
        cdqe
        movss   xmm0, DWORD [matrix+rax*4]
        movsx   rax, edx
        movss   DWORD [matrix+rax*4], xmm0
        mov     edx, r15d
        mov     eax, ebx
        add     eax, edx
        cdqe
        movss   xmm0, DWORD [rbp-24] ;temp
        movss   DWORD [matrix+rax*4], xmm0
        add     ebx, 1
    end_row_swap:
        mov     eax, DWORD [n]
        cmp     ebx, eax
        jle     row_swap_loop
    no_swap_needed:
    ;--------------------------
    leave
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    ret

print_solution:
    push    r12
    push    r13
    push    r14
    push    r15
    push    rbx
    push    rbp
    mov     rbp, rsp
    sub     rsp, 24
    ; -------------------------
    mov     r12, 0 ;index
    solutions_loop:
        mov     eax, DWORD  [n]
        cmp     r12d, eax
        jge     solutions_end
        mov     eax, r12d
        cdqe ;Convert Doubleword to Quadword: eax to rax
        mov     eax, DWORD  solution[rax*4]
        movd    xmm0, eax
        call    print_float
        add     r12d, 1
        jmp solutions_loop
    solutions_end:
    call print_nl
    ;--------------------------
    leave
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    ret

compare_with_zero:
    push    r12
    push    r13
    push    r14
    push    r15
    push    rbx
    push    rbp
    mov     rbp, rsp
    sub     rsp, 24
    ; -------------------------
    movss   xmm2, xmm0
    movss   xmm1, DWORD [negative_epsilon]
    movss   xmm0, xmm2
    comiss  xmm0, xmm1 ;Compare Scalar Ordered Single Precision
    jbe     not_zero ;jump if unsigned below or equal
    movss   xmm0, DWORD [positive_epsilon]
    comiss  xmm0, xmm2 ;Compare Scalar Ordered Single Precision
    jbe     not_zero ;jump if unsigned below or equal
    mov     eax, 1
    jmp     end_zero_comparison
    not_zero:
        mov     eax, 0
    end_zero_comparison:
    ;--------------------------
    leave
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    ret

print_impossible:
    push    r12
    push    r13
    push    r14
    push    r15
    push    rbx
    push    rbp
    mov     rbp, rsp
    sub     rsp, 24
    ; -------------------------
    mov     edi, impossible
    mov     eax, 0
    call    printf
    call print_nl
    ;--------------------------
    leave
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    ret

; function_template:
;     push    r12
;     push    r13
;     push    r14
;     push    r15
;     push    rbx
;     push    rbp
;     mov     rbp, rsp
;     sub     rsp, 24
;     ; -------------------------

;     ;--------------------------
;     leave
;     pop rbx
;     pop r15
;     pop r14
;     pop r13
;     pop r12
;     ret

;-------------------------------------------------------------------

asm_main:
    push r12
    push r13
    push r14
    push r15
    push rbx
    push    rbp
    mov     rbp, rsp
    sub     rsp, 24

    ; -------------------------
    call    read_input

    ;elimination:
    mov     r12d, 0 ;row_index
    jmp     end_main_elimination
    main_elimination_loop:
        mov     eax, r12d
        mov     r13d, eax ;index of the row to be swapped with in case the current row has a 0 as it's pivot
        jmp     check_swapping_condition
        main_swapping_loop:
            add     r13d, 1
        check_swapping_condition:
            mov     eax, [n]
            add     eax, 1
            imul    eax, r13d
            mov     edx, eax
            mov     eax, r12d
            add     eax, edx ;pivot_index
            cdqe ;convert double to quad: eax -> rax
            mov     eax, DWORD [matrix+rax*4]
            movd    xmm0, eax ;pivot
            call    compare_with_zero
            cmp eax, 0 ; test    eax, eax
            je      end_main_swapping
            mov     eax, [n]
            cmp     r13d, eax
            jl      main_swapping_loop
        end_main_swapping:
        mov     eax, [n]
        cmp     r13d, eax
        jne     determined_index_to_swap_with
        call    print_impossible
        jmp     end_program
        determined_index_to_swap_with:
            mov     esi, r13d
            mov     edi, r12d
            call    swap_rows
            mov     eax, r12d
            add     eax, 1
            mov     r14d, eax ;row_elimination_index
            jmp     end_eliminating_elements_in_lower_rows
        eliminating_elements_in_lower_rows:
            mov     edi, r12d
            mov     esi, r14d
            call    eliminate_row_by_subtraction
            add     r14d, 1
        end_eliminating_elements_in_lower_rows:
            mov     eax, [n]
            cmp     r14d, eax
            jl      eliminating_elements_in_lower_rows
        add     r12d, 1
    end_main_elimination:
        mov     eax, [n]
        cmp     r12d, eax
        jl      main_elimination_loop


    ;back substitution:
    mov     eax, [n]
    sub     eax, 1
    mov     r12d, eax ;back_substitution_index
    jmp     end_main_back_substitution
    main_back_substituion_loop:
        mov     eax, [n]
        lea     edx, [rax+1]
        mov     eax, r12d
        imul    eax, edx
        mov     r13d, eax ;origin
        mov     edx, [n]
        mov     eax, r13d
        add     eax, edx
        cdqe ;convert double to quad
        movss   xmm0, DWORD [matrix+rax*4]
        movss   xmm4, xmm0 ;sol
        ;note that xmm 0 through 3 may be changed when we call a function, our functions do not preserve them.
        mov     eax, r12d
        add     eax, 1
        mov     r14d, eax
        jmp     end_calculating_sol
        calculating_sol_loop:
            mov     eax, r14d
            cdqe
            movss   xmm1, DWORD [solution+rax*4]
            mov     edx, r13d
            mov     eax, r14d
            add     eax, edx
            cdqe ;convert double to quad
            movss   xmm0, DWORD [matrix+rax*4]
            mulss   xmm1, xmm0
            movss   xmm0, xmm4
            subss   xmm0, xmm1
            movss   xmm4, xmm0
            add     r14d, 1
        end_calculating_sol:
            mov     eax, [n]
            cmp     r14d, eax
            jl      calculating_sol_loop
        mov     edx, r13d
        mov     eax, r12d
        add     eax, edx
        cdqe
        movss   xmm1, DWORD [matrix+rax*4]
        movss   xmm0, xmm4
        divss   xmm0, xmm1
        mov     eax, r12d
        cdqe
        movss   DWORD [solution+rax*4], xmm0
        sub     r12d, 1
    end_main_back_substitution:
        cmp     r12d, 0
        jns     main_back_substituion_loop ;Jump if Not Signed (Positive or Zero)

    ;call    print_matrix
    call    print_solution
    end_program:
    ;--------------------------

    leave
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    ret

