section .data
    mode_str db "r", 0              ; Mode for fopen
    header_fmt db "%s %d %d %d", 0  ; Format string for parsing PPM header
    file_error db "Error opening file", 0
    
section .bss
    width resd 1                    ; Reserve space for image width
    height resd 1                   ; Reserve space for image height
    maxval resd 1                   ; Reserve space for max color value
    magic resb 3                    ; Reserve space for magic number (e.g., P6)
    map_size resd 1
    width_position resd 1
    height_position resd 1

    prev_head resq 1 ; used for double linking in vertical arrangement - store previous row head during the linking loop
    curr resq 1 ; use as new head
    prev_node resq 1 ; for horizontal link
    
    struc Pixel
        red resd 1
        green resd 1
        blue resd 1
        cdf resd 1
        up resq 1
        down resq 1
        left resq 1
        right resq 1
    endstruc
section .text
    global readPPM
    extern fopen, fscanf, malloc, fclose, fread

readPPM:
    sub rsp, 40                     ; Allocate space on the stack

    ; Open the file for reading
    mov rdi, rdi
    mov rsi, mode_str               ; Mode = "r"
    call fopen
    test rax, rax                   ; Check if file opened successfully
    jz .error                       ; If it failed, handle it
    mov rbx, rax                    ; Save file pointer

    ; Read header (magic number, width, height, maxval)
    mov rdi, rbx
    lea rsi, [header_fmt]
    lea rdx, [magic]
    lea rcx, [width]
    lea r8, [height]
    lea r9, [maxval]

    ; Align stack to 16 bytes
    and rsp, -16
    call fscanf
    test rax, rax
    cmp rax, 4
    jne .error

    ; Calculate size to read (width * 3') * height for RGB
    mov eax, [width]
    imul eax, 3                     ; multiply width by 3 (RGB) - 3 chars to read per pixel
    imul eax, [height]              ; multiply by height

    mov rdx, rax                    ;Total pixel char count expect 3275520
    ; each pixel has rgb
    
    ; Allocate memory for pixel data
    mov rdi, rax                    ; Number of bytes to allocate
    push rdx
    push rbx
    call malloc
    test rax, rax
    pop rbx
    pop rdx
    jz .error

    ; Read pixel data
    mov rdi, rax                   ; buffer pointer (1st argument to fread)
    mov rsi, 1                      ; Buffer for pixel data (2nd argument to fread, allocated memory)

    mov rcx, rbx                    ; Set number of elements to read (4th argument to fread)
    ; push rbx
    sub rsp, 8                      ; Align stack before call
    call fread                      ; Call fread(buf, size, count, fp)
    add rsp, 8                      ; Restore stack alignment
    
.tmp: ; i would change this
    cmp rax, rax
    jl .error

    ;Now build the list
    ; Clean up and return
    call fclose                     ; Close the file
    add rsp, 40                     ; Restore stack
    ret

finish_loop:
call fclose                     ; Close the file
    add rsp, 40                     ; Restore stack
    ret
loop_rows: ; read lines 
cmp height_position, [height]
je finish_loop


loop_cols: ; logic to read characters
cmp [width], width_position
je loop_rows
; read here
jmp loop_cols ; return to loop

check_char: ; used everywhere - I believe the lines might not follow the exact dimensions in the header 
; check for \n
join_horizontal: ; join nodes horizontally - call after creation
.error:
    mov rax, 0                      ; Return null in case of error
    add rsp, 40                     ; Restore stack
    ret