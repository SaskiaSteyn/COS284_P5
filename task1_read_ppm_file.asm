; ==========================
; Group member 01: Name_Surname_student-nr
; Group member 02: Name_Surname_student-nr
; Group member 03: Name_Surname_student-nr
; Group member 04: Name_Surname_student-nr
; Group member 05: Name_Surname_student-nr
; ==========================
section .data
    mode_str db "r", 0              ; Mode for fopen
    header_fmt db "%s %d %d %d", 0  ; Format string for parsing PPM header
    pixel_node_size equ 32  ; 4 bytes for RGB and CDF + 4 pointers (8 bytes each)

section .bss
    width resd 1                    ; Reserve space for image width
    height resd 1                   ; Reserve space for image height
    maxval resd 1                   ; Reserve space for max color value
    magic resb 3                    ; Reserve space for magic number (e.g., P6)
    head resq 1  ; Pointer to the head of the list

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
    mov rdx, rax                    ; Total pixel count expect 3,275,520

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
    mov rdi, rax                    ; Buffer pointer (1st argument to fread)
    mov rsi, 1                      ; size of each item
    mov rcx, rbx                    ; Set number of elements to read 
    ; rdx is already set
    sub rsp, 8                      ; Align stack before call
    push rdx
    call fread                      ; Call fread(buf, size, count, fp)
    pop rdx
    add rsp, 8                      ; Restore stack alignment
    
    cmp rax, rdx                    ; Check if all pixel data was read
    jl .error

.build_list:
    ; ------------------
    ; Now build the list
    lea r10, [rax]                  ; r10 points to the pixel data
    ; mov r11, rdx                    ; r11 has pixel count (r*3*h)
    xor rcx, rcx
    mov r12, [width]                ; width 
    mov r13, [height]                ; height

.outer_loop: ;loop through width
    cmp rcx, r12
    jz .end_loop
    xor r14, r14

.inner_loop:    ;loop through height
    cmp r14, r13    
    jz .end_inner_loop

    ; Calculate offset for pixel    
    ; curr_width*3*height + curr_height*3*width
    mov rdx, rcx
    imul rdx, 3
    imul rdx, r13 
    
    mov r11, r14
    imul r11, 3
    imul r11, r12
    add rdx, r11
    xor r11, r11

    lea r8, [r10 + rdx]             ; (width * 3 * height) 
    movzx rdi, byte [r8]            ; Load Red value
    movzx rsi, byte [r8 + 1]        ; Load Green value
    movzx rdx, byte [r8 + 2]        ; Load Blue value
    xor r8, r8 

    ; Call insert_pixel_node
    push r10
    push r12
    push r13
    push rcx
    push r14

    call insert_pixel_node

    pop r14
    pop rcx
    pop r13
    pop r12
    pop r10

    inc r14                          ; Decrement height counter
    jmp .inner_loop

.end_inner_loop:

    inc rcx                          ; inc width counter
    jmp .outer_loop                  

.end_loop:

    ; Clean up and return
    call fclose                     ; Close the file
    add rsp, 40                     ; Restore stack
    ret

.error:
    mov rax, 0                      ; Return null in case of error
    add rsp, 40                     ; Restore stack
    ret

insert_pixel_node:
    ; Parameters: r (rdi), g (rsi), b (rdx), cdf (rcx)
    ; Parameters: r (rdi), g (rsi), b (rdx), cdf (r13)
    ; Allocate space for a new PixelNode
    sub rsp, pixel_node_size

    ; Store the RGB values and CDF value
    mov [rsp], dil         ; Red
    mov [rsp + 1], sil     ; Green
    mov [rsp + 2], dl      ; Blue
    mov [rsp + 3], r13      ; CDF Value

    ; Initialize adjacent pointers to NULL
    mov rax, 0
    mov [rsp + 4], rax     ; up
    mov [rsp + 12], rax    ; down
    mov [rsp + 20], rax     ; left
    mov [rsp + 28], rax     ; right

    ; Set the new node's down pointer to the current head (if needed)
    mov rax, [head]
    mov [rsp + 12], rax    ; down pointer

    ; Update head to point to the new node
    mov [head], rsp        ; Update head

    ; Clean up stack
    add rsp, pixel_node_size
    ret
