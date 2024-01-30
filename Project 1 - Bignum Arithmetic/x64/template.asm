;Each word is 2 bytes
;Do not forget to make the stack pointer 16-aligned before calling a libc function!
;Strings should be null terminated (is this important?)

global asm_main

extern putchar
extern getchar


segment   .data
;An integer such as 109 shall be stored in this format: db 3, 0, 1, 0, 9, 0  == length, sign, digits, NUL
;example_number: db 3, 0, 1, 0, 9, 0
;example_number_2: db 3, 0, 2, 3, 4, 0


;A signed 256-bit integer has less than 78 digits. We will represent each digit by a character. 77 digits + 1 sign + 1 null termination = 79 bytes
%define SIZE 170
segment .bss
input_buffer_1: resb SIZE
input_buffer_2: resb SIZE
output_buffer_1: resb SIZE
multiplication_buffer: resb SIZE
buffer_to_be_safe: resb SIZE

segment .text

;---------------------------------------------------------------------------
print_nl:
    sub rsp, 8

    mov rdi, 10
    call putchar
    
    add rsp, 8 ; clearing local variables from stack

    ret


remove_leading_zeros:
    push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8

    xor r12, r12 ;index
    xor r13, r13 ;count leading zeros
    movzx r14, byte [rdi] ;length
    counting_zeros:
        cmp r12, r14
        jge number_is_zero

        movzx rbp, byte [rdi + 2 + r12]
        cmp rbp, 0
        jne zeros_counted
        inc r13

        inc r12
        jmp counting_zeros
    

    zeros_counted:
    cmp r12, 0
    je removing_done
    sub r14, r12
    mov byte [rdi], r14b
    add rdi, 2
    add rdi, r12
    add r14, rdi
    shifting_to_remove_zeros:
        cmp rdi, r14
        jge shifting_to_remove_done

        movzx rbx, byte [rdi]
        sub rdi, r12
        mov byte [rdi], bl
        add rdi, r12

        inc rdi
        jmp shifting_to_remove_zeros
    
    shifting_to_remove_done:
        mov byte [rdi], 0
        jmp removing_done

    number_is_zero:
        call zero_bignum


    removing_done:

    add rsp, 8
	pop r15
	pop r14
	pop r13
	pop r12
    pop rbx
    pop rbp
    ret

;an example number: 3, 0, "109", 0 == length, sign, number, null-termination
add_bignum:
    push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15

    sub rsp, 8
    ;the function is called with this arguments: rdi = destination_addr rsi = addr_1    rdx = addr_2
    ;we write the function with rdi = addr_1    rsi = addr_2    rdx = destination_addr in mind, so we apply this change:
    mov r12, rdx
    mov rdx, rdi
    mov rdi, rsi
    mov rsi, r12

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
    mov byte [rdx + r10 + 2], 0 ;rdx has the address in which the answer should be written

    xor r15, r15 ;carry or borrow
    movzx rbx, byte [rdi + 1]
    movzx rcx, byte [rsi + 1]
    cmp rbx, rcx ;compare signs
    jne subtract
    ;r12=len_1   r14=len_2    r10=len_ans    r15=borrow rdi=addr_1   rsi=addr_2 rbx=sign_1
    
    add_loop:
        cmp r12, 0
        jle first_num_done
        cmp r14, 0
        jle second_num_done
        movzx r8, byte [rdi + 1 + r12]
        add r8b, byte [rsi + 1 + r14]

        add r8, r15
        cmp r8, 10
        jl no_carry
            mov r15, 1
            sub r8, 10
            jmp carry_calculated
        no_carry:
            xor r15, r15
        carry_calculated:
        mov byte [rdx + 1 + r10], r8b
        dec r10
        dec r12
        dec r14
        jmp add_loop
    first_num_done:
        cmp r14, 0
        jle adding_done
        movzx r8, byte [rsi + 1 + r14]
        add r8, r15
        cmp r8, 10
        jl no_carry2
            mov r15, 1
            sub r8, 10
            jmp carry_calculated2
        no_carry2:
            xor r15, r15
        carry_calculated2:
        mov byte [rdx + 1 + r10], r8b
        dec r10
        dec r14
        jmp first_num_done
    second_num_done:
        cmp r12, 0
        jle adding_done
        movzx r8, byte [rdi + 1 + r12]
        add r8, r15
        cmp r8, 10
        jl no_carry3
            mov r15, 1
            sub r8, 10
            jmp carry_calculated3
        no_carry3:
            xor r15, r15
        carry_calculated3:
        mov byte [rdx + 1 + r10], r8b
        dec r10
        dec r12
        jmp second_num_done
    adding_done:
        cmp r15, 0
        je carry_done
        mov byte [rdx + 1 + r10], r15b
        dec r10
        carry_done:
        movzx rbx, byte [rdi + 1]
        mov byte [rdx + 1], bl
        jmp addition_or_subtraction_done


    subtract:
        ;r12=len_1   r14=len_2    r10=len_result   r15=borrow rdi=addr_1   rsi=addr_2 rbx=sign_1  rdx=result_addr
        ;first find the bigger number (ignoring sign) and put it in rdi:
        cmp r12, r14 ;compare the number of digits of each number
        jg bigger_number_is_in_rdi
        jl swap_them

        xor rcx, rcx ;index
        comparing_loop:
            cmp rcx, r12
            jge subtraction_result_is_zero
            movzx r13, byte [rsi + 2 + rcx]
            cmp byte [rdi + 2 + rcx], r13b
            jl swap_them
            jg bigger_number_is_in_rdi

            inc rcx
            jmp comparing_loop


        swap_them:
        movzx rbx, byte [rsi + 1]

        mov rcx, r12 ;temp
        mov r12, r14
        mov r14, rcx

        mov rcx, rdi
        mov rdi, rsi
        mov rsi, rcx

        bigger_number_is_in_rdi:
        mov byte [rdx + 1], bl ;set the answer's sign
        xor r15, r15 ;borrow
    sub_loop:
        ;cmp r12, 0
        ;jle sub_first_done
        cmp r14, 0
        jle sub_second_num_done
        movzx r8, byte [rdi + 1 + r12]
        sub r8b, byte [rsi + 1 + r14]

        sub r8b, r15b
        cmp r8b, 0
        jge no_borrow
            mov r15, 1
            add r8b, 10
            jmp borrow_calculated
        no_borrow:
            xor r15, r15
        borrow_calculated:
        mov byte [rdx + 1 + r10], r8b
        dec r10
        dec r12
        dec r14
        jmp sub_loop
    sub_second_num_done:
        cmp r12, 0
        jle sub_done
        movzx r8, byte [rdi + 1 + r12]
        sub r8b, r15b
        cmp r8b, 0
        jge no_borrow2
            mov r15, 1
            add r8b, 10
            jmp borrow_calculated2
        no_borrow2:
            xor r15, r15
        borrow_calculated2:
        mov byte [rdx + 1 + r10], r8b
        dec r10
        dec r12
        jmp sub_second_num_done
    sub_done:
        ;At this point because we made sure that the absolute value of rdi is bigger than
        ; the absolute value of rsi, r15 should be 0, meaning no borrow should remain.
        ;borrow_done:
    ;-----------------
    addition_or_subtraction_done:
        fill_extra_space_with_leading_zeros:
            cmp r10, 0
            jle filling_done
            mov byte [rdx + 1 + r10], 0
            dec r10
            jmp fill_extra_space_with_leading_zeros
        filling_done:
        mov rdi, rdx
        call remove_leading_zeros
        jmp end_addition_or_subtraction
    subtraction_result_is_zero:
        mov rdi, rdx
        call zero_bignum
    
    end_addition_or_subtraction:

    add rsp, 8
	pop r15
	pop r14
	pop r13
	pop r12
    pop rbx
    pop rbp
    ret

shift_left:
    push r12

    movzx r12, byte [rdi]
    cmp r12, 1
    jne normal_shift
    cmp byte [rdi + 2], 0
    jne normal_shift

    ;the number to be shifted is zero:
    call zero_bignum
    jmp end_shift


    normal_shift:
    inc r12
    mov byte [rdi], r12b
    ;In our bignum format, each bignum should be null terminated by default. But it isn't! (why?) so we added this line to make sure:
    mov byte [rdi + 1 + r12], 0
    ;Null terminate it:
    mov byte [rdi + 2 + r12], 0
    end_shift:

    pop r12
    ret

zero_bignum:
    mov byte [rdi], 1 ;lenth
    mov byte [rdi + 1], 0 ;sign
    mov byte [rdi + 2], 0 ;zero
    mov byte [rdi + 3], 0 ;null termination

    ret

multiply_bignum_by_digit:
    push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8

    ; rdi = destination_addr    rsi = source_addr   rdx = digit to be multiplied by
    cmp dl, 0
    jne digit_not_zero
    call zero_bignum
    jmp end_multiplication_by_digit

    digit_not_zero:
    movzx r12, byte [rsi] ;source_index
    mov r13, r12 ;destination_index
    inc r13
    mov byte [rdi], r13b ;length
    mov r15b, byte [rsi + 1]
    mov byte [rdi + 1], r15b ;sign
    mov byte [rdi + 2 + r13], 0 ;null termination

    xor r15, r15 ;carry
    multiplication_by_digit_loop:
        cmp r12, 0
        jle source_ended
        movzx rax, byte [rsi + 1 + r12]
        mul dl
        add rax, r15
        mov r14, 10
        div r14b
        

        mov r15b, al ;carry
        shr rax, 8 ;we cannot access ah directly, so we need to shift rax 8 bits to the right.
        mov byte [rdi + 1 + r13], al

        dec r12
        dec r13
        jmp multiplication_by_digit_loop
    source_ended:
        mov byte [rdi + 1 + r13], r15b
        dec r13
        fill_extra_space_after_multiplication_with_leading_zeros:
            cmp r13, 0
            jle filling_after_multiplication_done
            mov byte [rdi + 1 + r13], 0

            dec r13
            jmp fill_extra_space_after_multiplication_with_leading_zeros
        filling_after_multiplication_done:
        call remove_leading_zeros
        
    end_multiplication_by_digit:

    add rsp, 8
	pop r15
	pop r14
	pop r13
	pop r12
    pop rbx
    pop rbp
	ret

multiply_bignum:
    push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8

    ;rdi = destination_arr  rsi = addr_1    rdx = addr_2
    ;we need to save these three registers, because it is not gauranteed that their values will remian the same after calling a function
    mov r13, rdi
    mov r14, rsi
    mov r15, rdx

    call zero_bignum ;zero the destination which is in rdi
    movzx r12, byte [r15] ;len2
    xor rbp, rbp ;index

    multiplication_loop:
        cmp rbp, r12
        jge multiplication_end

        ;multiply by a digit:
        mov rdi, multiplication_buffer
        mov rsi, r14
        movzx rdx, byte [r15 + 2 + rbp] ;a digit of the second number
        call multiply_bignum_by_digit

        ;shift:
        mov rdi, r13
        call shift_left

        ;add: (we are using a second buffer just to be safe)
        mov rdi, buffer_to_be_safe
        mov rsi, r13
        mov rdx, multiplication_buffer
        call add_bignum

        mov rdi, multiplication_buffer
        call zero_bignum

        mov rdi, r13
        mov rsi, buffer_to_be_safe
        mov rdx, multiplication_buffer
        call add_bignum

        inc rbp
        jmp multiplication_loop

    multiplication_end:
        cmp byte [r15 + 1], 0
        je second_sign_applied
        mov rdi, r13
        call negate_bignum
    second_sign_applied:

    add rsp, 8
	pop r15
	pop r14
	pop r13
	pop r12
    pop rbx
    pop rbp
	ret

negate_bignum:
    push r12

    xor r12, r12
    cmp r12b, byte [rdi + 1]
    jne sign_determined
    mov r12, 1
    sign_determined:
    mov byte [rdi + 1], r12b

    pop r12
    ret

print_bignum:
    push r12
    push r13
    push r14

    mov r12, rdi
    call remove_leading_zeros
    movzx r13, byte [r12] ;length
    mov r14, 0

    cmp byte [rdi + 1], 0
    je print_loop
    mov rdi, '-'
    call putchar
    print_loop:
    cmp r14, r13
    jge print_done
    movzx rdi, byte [r12 + 2 + r14]
    add rdi, 48
    call putchar

    inc r14
    jmp print_loop

    print_done:
    pop r14
    pop r13
    pop r12
    ret

read_bignum:
    push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8

    mov r12, rdi ;saving address
    xor r13, r13 ;length
    xor r14, r14 ;sign
    call getchar
        cmp rax, '-'
        jne not_negative_sign
        mov r14, 1
        jmp first_character_was_a_sign
    not_negative_sign:
        cmp rax, '+'
        je first_character_was_a_sign
        cmp rax, 10
        je end_of_line
        jmp reading_loop ;if the input is correctly formatted, upon reaching this line the character is a digit
    first_character_was_a_sign:
        call getchar
    reading_loop:
        cmp rax, 10
        je end_of_line
        sub rax, 48 ;'0' == 48
        mov byte [r12 + 2 + r13], al
        inc r13
        call getchar
        jmp reading_loop
    end_of_line:
        mov byte [r12], r13b
        mov byte [r12 + 1], r14b
        mov byte [r12 + 2 + r13], 0
    
    mov rdi, r12
    call remove_leading_zeros

    add rsp, 8
	pop r15
	pop r14
	pop r13
	pop r12
    pop rbx
    pop rbp
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
    main_loop:
        call getchar
        cmp rax, 'q'
        je main_end
        mov r12, rax
        call getchar ;handling LineFeed

        mov rdi, input_buffer_1
        call read_bignum
        mov rdi, input_buffer_2
        call read_bignum
        mov rdi, output_buffer_1
        mov rsi, input_buffer_1
        mov rdx, input_buffer_2

        cmp r12, '+'
        je main_addition
        cmp r12, '-'
        je main_subtraction
        cmp r12, '*'
        je main_multiplication
        ;todo division

        main_addition:
            call add_bignum
            jmp output
        main_subtraction:
            ;negate the second number:
            mov r13, rdi
            mov rdi, rdx
            call negate_bignum
            mov rdi, r13

            call add_bignum
            jmp output
        main_multiplication:
            ;movzx rdx, byte [rdx + 2]
            ;call multiply_bignum_by_digit
            ;mov rdi, output_buffer_1
            ;call shift_left
            call multiply_bignum
            jmp output
        
        output:
            mov rdi, output_buffer_1
            call print_bignum
            call print_nl
            jmp main_loop
    main_end:
    ;--------------------------

    add rsp, 8

	pop r15
	pop r14
	pop r13
	pop r12
    pop rbx
    pop rbp

	ret
