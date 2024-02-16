;The data (and bss) must be 32 byte aligned for the AVX2 SIMD instructions to work.
;Visit https://www.nasm.us/doc/nasmdoc5.html#section-5.10 for more information
;You must take care of the stack pointer being 32-byte aligned (?)
;A word is 2 bytes in x64
;A single precision float is 4 bytes
;We use AVX2 instructions here, which work with YMM0-YMM7 which are 256-bit each, equivalent to eight 32-bit single-precision floats each
segment .data
io_int_format: db         "%ld", 0
read_float_format: db "%f", 0
print_float_format: db "%.3f ", 0
align 32
impossible: db "Impossible", 0
align 32
positive_epsilon: dd 0.0001
align 32
negative_epsilon: dd -0.0001

segment .bss
alignb 32
matrix: resd 1008032 ; A_rows * (A_columns + B_column + max_padding) = 1000 * (1000 + 1 + 7)   (also this number is divisible by 32)
alignb 32
solution: resd 1024
alignb 32
n: resq 1
alignb 32
padding: resw 1
;padding is used to make sure each row of the matrix starts with a 32-byte aligned element, by adjusting the number of elements in the previous row.

segment .text

    extern printf
    extern putchar
    extern puts
    extern scanf
    extern getchar
    global asm_main

;-------------------------------------------------------------------
print_int:
    sub rsp, 24

    mov rsi, rdi

    mov rdi, io_int_format
    mov rax, 1 ; setting rax (al) to number of vector inputs
    call printf
    
    add rsp, 24 ; clearing local variables from stack

    ret


print_nl:
    sub rsp, 24

    mov rdi, 10
    call putchar
    
    add rsp, 24 ; clearing local variables from stack

    ret


read_int:
    sub rsp, 24

    mov rsi, rsp
    mov rdi, io_int_format
    mov rax, 1 ; setting rax (al) to number of vector inputs
    call scanf

    mov rax, [rsp]

    add rsp, 24 ; clearing local variables from stack

    ret

read_float:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 16 ;note that the stack pointer becoms 32-byte aligned
    
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

    movss   DWORD [rbp-4], xmm0 ; -4 is enough only beacause we are using movss which moves only 4 bytes of xmm0 (xmm are 16 bytes long)
    pxor    xmm1, xmm1
    cvtss2sd        xmm1, DWORD [rbp-4] ;Convert Scalar Single Precision Floating-Point Value to Scalar Double PrecisionFloating-Point Value
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
    sub     rsp, 8
    ; -------------------------
    call    read_int
    mov     DWORD [n], eax

    add eax, 1
    mov r12, 8
    div r12w
    cmp dx, 0
    je padding_calculated
    mov ax, 8
    sub ax, dx
    mov dx, ax
    padding_calculated:
    mov word [padding], dx;

    mov     r12, 0 ;row_index
    input_loop:
        mov     eax, DWORD [n]
        cmp     r12d, eax
        jge      end_input
        mov     eax, DWORD [n]
        lea     edx, [rax+1]
        add edx, [padding]
        mov     eax, r12d
        imul    eax, edx
        mov     r14d, eax ;origin
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
    sub     rsp, 8
    ; -------------------------
    mov     r12, 0 ;row_index
    print_row_loop:
        mov     eax, DWORD [n]
        cmp     r12d, eax
        jge      end_print
        mov     eax, DWORD [n]
        lea     edx, [rax+1]
        add     edx, [padding]
        mov     eax, r12d
        imul    eax, edx
        mov     r14d, eax ;origin
        mov     r13, 0 ;column_index
    print_column_loop:
        mov     eax, DWORD [n]
        cmp     r13d, eax
        jg     end_print_column
        mov     edx, r14d
        mov     eax, r13d
        add     eax, edx
        ;cdqe ;convert double to quad
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
    sub     rsp, 8
    ; -------------------------
    ;row2 -= factor * row1
    mov     r12d, edi ;row_1
    mov     r13d, esi ;row_2
    mov     eax, DWORD [n]
    lea     edx, [rax+1]
    add     edx, [padding]
    mov     eax, r12d
    imul    eax, edx
    mov     r14d, eax ;origin_1
    mov     eax, DWORD [n]
    lea     edx, [rax+1]
    add     edx, [padding]
    mov     eax, r13d
    imul    eax, edx
    mov     r15d, eax ;origin_2
    mov     eax, r12d
    add     eax, r15d
    ;cdqe ;convert double to quad
    movss   xmm0, DWORD [matrix+rax*4] ;the element below the pivot
    mov     eax, r12d
    add     eax, r14d
    ;cdqe
    movss   xmm1, DWORD [matrix+rax*4] ;pivot
    ;make sure pivot!=0 before calling this function.
    divss   xmm0, xmm1
    movss   xmm2, xmm0 ;factor
    VBROADCASTSS ymm2, xmm2 ;Broadcast low single precision floating-point element in the source operand to eight locations in ymm1.
    mov     rbx, [n] ;index

    simd_elimination_loop:
        cmp ebx, 7
        jl end_simd_elimination
        sub ebx, DWORD [n]
        neg ebx
        
        mov     eax, ebx
        add     eax, r15d ;index of the thing that should be subtracted from
        vmovaps   ymm0, [matrix+rax*4]
        mov     eax, ebx
        add     eax, r14d ;row_1 things index 
        VFNMADD231PS ymm0, ymm2, [matrix+rax*4] ;Fused Negative Multiply-Add of Packed Single Precision Floating-Point Values
        ;Multiply packed single precision floating-point values from ymm2 and ymm3/mem, negate the multiplication result and add to ymm1 and put result in ymm1.
        mov     eax, ebx
        add     eax, r15d
        vmovaps   [matrix+rax*4], ymm0

        add ebx, 8
        sub ebx, DWORD [n]
        neg ebx
        jmp simd_elimination_loop
    end_simd_elimination:
    sub ebx, DWORD [n]
    neg ebx

    jmp     end_row_elimination
    row_elimination_loop:
        mov     eax, ebx
        add     eax, r15d
        ;cdqe
        movss   xmm0, DWORD [matrix+rax*4]
        mov     eax, ebx
        add     eax, r14d
        ;cdqe

        ; movss   xmm1, DWORD [matrix+rax*4]
        ; mulss   xmm1, xmm2
        ; subss   xmm0, xmm1
        VFNMADD231SS xmm0, xmm2, DWORD [matrix+rax*4] ;Fused Negative Multiply-Add of Scalar Single Precision Floating-Point Values
        ;Multiply scalar single precision floating-point values from ymm2 and ymm3/mem, negate the multiplication result and add to ymm1 and put result in ymm1.

        mov     eax, ebx
        add     eax, r15d
        ;cdqe
        movss   DWORD [matrix+rax*4], xmm0
        add     rbx, 1
    end_row_elimination:
        mov     eax, DWORD[n]
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
    sub     rsp, 8
    ; -------------------------
    mov     r12d, edi ;row_1
    mov     r13d, esi ;row_2
    mov     eax, r12d
    cmp     eax, r13d
    je      no_swap_needed
    mov     eax, DWORD [n]
    lea     edx, [rax+1]
    add     edx, [padding]
    mov     eax, r12d
    imul    eax, edx
    mov     r14d, eax ;origin_1
    mov     eax, DWORD [n]
    lea     edx, [rax+1]
    add     edx, [padding]
    mov     eax, r13d
    imul    eax, edx
    mov     r15d, eax ;origin_2
    mov     ebx, DWORD [n] ;index

    simd_swap_loop:
        cmp ebx, 7
        jl simd_swap_done
        sub ebx, DWORD [n]
        neg ebx
        mov     eax, ebx
        add     eax, r14d
        ;cdqe
        vmovaps ymm1, [matrix + 4 * rax] ;temp
        mov     eax, ebx
        add     eax, r15d
        mov     edx, ebx
        add     edx, r14d
        ;cdqe
        vmovaps ymm0, [matrix + 4 * rax]
        movsx   rax, edx
        vmovaps [matrix + 4 * rax], ymm0
        mov     eax, ebx
        add     eax, r15d
        ;cdqe
        vmovaps [matrix + 4 * rax], ymm1
        add ebx, 8
        sub ebx, DWORD [n]
        neg ebx
        jmp simd_swap_loop
    simd_swap_done:
    sub ebx, DWORD [n]
    neg ebx

    jmp     end_row_swap
    row_swap_loop:
        ;call print_impossible
        mov     eax, ebx
        add     eax, r14d
        ;cdqe
        movss   xmm1, DWORD [matrix+rax*4] ;temp
        mov     eax, ebx
        add     eax, r15d
        mov     edx, ebx
        add     edx, r14d
        ;cdqe
        movss   xmm0, DWORD [matrix+rax*4]
        movsx   rax, edx
        movss   DWORD [matrix+rax*4], xmm0
        mov     eax, ebx
        add     eax, r15d
        ;cdqe
        movss   xmm0, xmm1 ;temp
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
    sub     rsp, 8
    ; -------------------------
    mov     r12, 0 ;index
    solutions_loop:
        mov     eax, DWORD  [n]
        cmp     r12d, eax
        jge     solutions_end
        mov     eax, r12d
        ;cdqe ;Convert Doubleword to Quadword: eax to rax
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
    sub     rsp, 8
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
    sub     rsp, 8
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
;     sub     rsp, 8
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
    sub     rsp, 8

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
            add     eax, [padding]
            imul    eax, r13d ;origin
            mov     edx, eax
            mov     eax, r12d
            add     eax, edx ;pivot_index
            ;cdqe ;convert double to quad: eax -> rax
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
        add     edx, [padding]
        mov     eax, r12d
        imul    eax, edx
        mov     r13d, eax ;origin
        mov     edx, [n]
        mov     eax, r13d
        add     eax, edx
        ;cdqe ;convert double to quad
        movss   xmm0, DWORD [matrix+rax*4]
        movss   xmm4, xmm0 ;sol
        ;note that xmm 0 through 3 may be changed when we call a function, our functions do not preserve them.
        mov     eax, r12d
        add     eax, 1
        mov     r14d, eax
        jmp     end_calculating_sol
        calculating_sol_loop:
            mov     eax, r14d
            ;cdqe
            movss   xmm1, DWORD [solution+rax*4]
            mov     edx, r13d
            mov     eax, r14d
            add     eax, edx
            ;cdqe ;convert double to quad
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
        ;cdqe
        movss   xmm1, DWORD [matrix+rax*4]
        movss   xmm0, xmm4
        divss   xmm0, xmm1
        mov     eax, r12d
        ;cdqe
        movss   DWORD [solution+rax*4], xmm0
        sub     r12d, 1
    end_main_back_substitution:
        cmp     r12d, 0
        jns     main_back_substituion_loop ;Jump if Not Signed (Positive or Zero)

    ;call    print_matrix
    call    print_solution
    end_program:
    mov rax, 0
    ;--------------------------

    leave
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    ret

