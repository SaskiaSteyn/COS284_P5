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

section .data
    mode_str db "r", 0              ; Mode for fopen
    header_fmt db "%s %d %d %d", 0  ; Format string for parsing PPM header
    file_error db "Error opening file", 0

section .bss
    width resd 1                    ; Reserve space for image width
    height resd 1                   ; Reserve space for image height
    maxval resd 1                   ; Reserve space for max color value
    magic resb 3                    ; Reserve space for magic number (e.g., P6)

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

    ; Calculate pixel count (width * height * 3 for RGB)
    mov eax, [width]
    imul eax, [height]              ; width * height
    imul eax, 3                     ; Multiply by 3 (RGB)
    mov rdx, rax                    ;Total pixel count expect 3275520

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
    
.tmp:
    cmp rax, rax
    jl .error

    ;Now build the list
    ; Clean up and return
    call fclose                     ; Close the file
    add rsp, 40                     ; Restore stack
    ret

.error:
    mov rax, 0                      ; Return null in case of error
    add rsp, 40                     ; Restore stack
    ret
