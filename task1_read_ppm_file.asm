<<<<<<< Updated upstream
; ==========================
; Group member 01: Name_Surname_student-nr
; Group member 02: Name_Surname_student-nr
; Group member 03: Name_Surname_student-nr
; Group member 04: Name_Surname_student-nr
; Group member 05: Name_Surname_student-nr
; ==========================

extern malloc

section .text
    global readPPM

readPPM:
    
=======
section .data            
    P6_format db "P6", 0
    whitespace db " \n\t", 0             ; Characters to skip
    comment_char db "#", 0               ; Comment character
    mode_str db "r", 0

section .bss
    header_buf resb 512                   ; Buffer for reading the PPM header (512 bytes max)
    filename resb 256                     ; Space for filename
    file_desc resq 1                      ; File descriptor
    width resd 1                          ; Image width
    height resd 1                         ; Image height
    max_color_value resd 1                ; Max color value
    head_ptr resq 1                       ; Head pointer for 2D linked list
    prev_row resq 1                       ; Pointer to the previous row's nodes
    curr_node resq 1                      ; Current node pointer

section .text
    ; extern malloc, free, fopen, fread, parse_header, fclose                   ; External functions for memory management
    global readPPM                        ; Export function name for external calls
    extern malloc, free, fopen, fread, fclose

readPPM:
    ; Open the file
    mov [filename], rdi                     ; Filename as argument to open()
    sub rsp, 40
    mov rdi, rdi
    mov rsi, mode_str                            ; Read-only flag
    call fopen
    test rax, rax
    mov [file_desc], rax                  ; Store file descriptor

    ; Check if the file opened successfully
    cmp rax, -1
    je .error_exit                        ; Exit on error

    ; Read header
    mov rdi, header_buf
    mov rsi, 512
    mov rdx, 1
    mov rcx, rax
    call fread

    ; mov rsi, header_buf
    ; mov rdx, 512                          ; Max buffer size
    ; call fread                            ; Read header data into buffer

    ; Parse header to extract PPM format, width, height, and max color
    mov rdi, header_buf
    call parse_header
    cmp rax, 0
    je .error_exit                        ; Exit if parsing failed

    ; Validate metadata
    cmp dword [width], 0
    jle .error_exit                       ; Exit if width is invalid
    cmp dword [height], 0
    jle .error_exit                       ; Exit if height is invalid
    cmp dword [max_color_value], 0
    jle .error_exit                       ; Exit if max color is invalid

    ; Allocate memory and read pixel data
    call malloc                           ; Allocate memory for first row
    mov [head_ptr], rax                   ; Store head of linked list
    mov [prev_row], rax                   ; Initialize prev_row to head

    ; Read pixels and populate the linked list
    mov rcx, [height]
.next_row:
    call malloc                           ; Allocate memory for the next row
    mov rsi, rax                          ; Store pointer to the current row
    mov [curr_node], rsi                  ; Set current node

    ; Loop through each column (width) to read and link pixels
    mov rdx, [width]
.next_col:
    call malloc                           ; Allocate memory for PixelNode
    mov rbx, rax                          ; Store new node in rbx

    ; Read RGB values from the file
    mov rdi, [file_desc]
    mov rsi, rbx
    mov rdx, 3
    call fread

    ; Initialize the CdfValue to 0
    mov byte [rbx + 3], 0

    ; Link nodes in 2D linked list
    ; Link left and right
    test rsi, rsi
    jz .first_col                         ; Skip if it's the first column
    mov [rsi + 8], rbx                    ; Link the left node to the current node
    mov [rbx + 16], rsi                   ; Link the current node to the left node

.first_col:
    mov [curr_node], rbx                  ; Update current node to this node

    ; Link up and down
    mov rax, [prev_row]
    test rax, rax
    jz .first_row                         ; Skip if it's the first row
    mov [rax + 24], rbx                   ; Link the above node to the current node
    mov [rbx + 32], rax                   ; Link the current node to the above node

.first_row:
    add rsi, 8                            ; Move to the next pixel node in the row
    dec rdx
    jnz .next_col                         ; Continue with the next column

    ; mov [prev_row], [curr_node]           ; Update previous row to current row
    mov r11, [curr_node]
    mov [prev_row], r11
    dec rcx
    jnz .next_row                         ; Continue with the next row

    ; Close file and return head pointer
    mov rdi, [file_desc]
    call fclose
    mov rax, [head_ptr]
    ret

.error_exit:
    xor rax, rax                          ; Return NULL on error
    ret


; Function: parse_header
; Parses the PPM header, extracting the format, width, height, and max color value.
; Input: rdi - pointer to the header buffer
; Output: rax - 1 if parsing succeeded, 0 if failed
parse_header:
    push rdi                             ; Preserve registers
    push rsi
    push rdx
    push rcx

    ; Check for "P6" format at the start of the header
    ; mov rsi, P6_format                   ; rsi points to "P6" format string
    call skip_whitespace
    mov rsi, P6_format                   ; rsi points to "P6" format string
    call compare_strings
    jnz .error_exit                      ; Exit if format does not match "P6"

    ; Read width
    call skip_whitespace
    call read_integer
    mov [width], rax                     ; Store width

    ; Read height
    call skip_whitespace
    call read_integer
    mov [height], rax                    ; Store height

    ; Read max color value
    call skip_whitespace
    call read_integer
    mov [max_color_value], rax           ; Store max color value

    ; Successful parsing
    mov rax, 1
    jmp .exit

.error_exit:
    xor rax, rax                         ; Return 0 on error

.exit:
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    ret

; Helper Function: skip_whitespace
; Advances rdi to the next non-whitespace character, skipping comments.
skip_whitespace:
    .next_char:
        mov al, byte [rdi]               ; Load current character
        test al, al
        jz .end                          ; End of string

        ; Skip whitespace characters
        mov rsi, whitespace
        call is_in_set
        jz .check_comment
        inc rdi
        jmp .next_char

    .check_comment:
        cmp al, byte [comment_char]      ; Check if the character is '#'
        jne .end                         ; Exit if not a comment

        ; Skip until newline for comments
        .skip_comment:
            mov al, byte [rdi]
            cmp al, 0x0A                 ; Newline character
            je .next_char
            inc rdi
            jmp .skip_comment

    .end:
        ret

; Helper Function: read_integer
; Reads an integer from the header, converting ASCII digits to a number.
; Output: rax - the integer value read
read_integer:
    xor rax, rax                         ; Clear rax for the result
    .next_digit:
        mov al, byte [rdi]               ; Load current character
        sub al, '0'                      ; Convert ASCII to integer
        cmp al, 9
        ja .end_integer                  ; End if not a valid digit

        imul rax, rax, 10                ; Multiply current result by 10
        add rax, rax                     ; Add new digit to result
        inc rdi                          ; Move to next character
        jmp .next_digit

    .end_integer:
        ret

; Helper Function: compare_strings
; Compares two null-terminated strings (rdi and rsi).
; Returns 0 if they are equal, non-zero otherwise.
compare_strings:
    .compare_loop:
        mov al, byte [rdi]               ; Load byte from rdi
        mov bl, byte [rsi]               ; Load byte from rsi
        cmp al, bl
        jne .not_equal                   ; Exit if characters do not match
        test al, al
        jz .equal                        ; End if null-terminator is reached
        inc rdi
        inc rsi
        jmp .compare_loop

    .equal:
        xor rax, rax                     ; Return 0 for equal
        ret
    .not_equal:
        mov rax, 1                       ; Return non-zero for not equal
        ret

; Helper Function: is_in_set
; Checks if AL is in a null-terminated set of bytes pointed to by RSI.
; Returns ZF = 1 if AL is in the set, ZF = 0 otherwise.
is_in_set:
    .loop:
        mov bl, byte [rsi]
        test bl, bl
        jz .not_in_set                   ; End if null terminator
        cmp al, bl
        je .in_set
        inc rsi
        jmp .loop

    .in_set:
        xor rax, rax                     ; Found, set ZF = 1
        ret
    .not_in_set:
        mov rax, 1                       ; Not found, set ZF = 0
        ret
>>>>>>> Stashed changes
