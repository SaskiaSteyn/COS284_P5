; ==========================
; Group member 01: Name_Surname_student-nr
; Group member 02: Name_Surname_student-nr
; Group member 03: Name_Surname_student-nr
; Group member 04: Name_Surname_student-nr
; Group member 05: Name_Surname_student-nr
; ==========================

section .text
    global applyHistogramEqualisation

applyHistogramEqualisation:
    ; Prologue
    push rbp                   ; Save base pointer
    mov rbp, rsp                ; Set stack pointer as base
    sub rsp, 16                 ; Allocate space for local variables

    ; Register assignments
    mov rdi, [rbp+16]           ; Load head pointer (first argument)

.traverse_rows:
    ; Check if the row pointer (rdi) is null (end of list)
    test rdi, rdi
    je .end_function            ; If it's null, we've reached the end

    ; Traverse the row
    mov rbx, rdi                ; rbx is used to traverse each node horizontally

.traverse_columns:
    ; Check if the current node (rbx) is null
    test rbx, rbx
    je .next_row                ; If it's null, go to the next row

    ; Load the CdfValue from the PixelNode (byte at offset 3)
    movzx rax, byte [rbx + 3]   ; rax = CdfValue (as an unsigned char)

    ; Add 0.5 for rounding (0.5 * 256 = 128 for integer approximation)
    add rax, 128
    shr rax, 8                  ; Divide by 256 (convert back to 8-bit)

    ; Clamp the value to be between 0 and 255
    cmp rax, 255
    jle .update_pixel           ; If rax <= 255, continue
    mov rax, 255                ; Otherwise, set rax to 255

.update_pixel:
    ; Now rax contains the new pixel value, set Red, Green, Blue
    mov byte [rbx], al          ; Set Red   (byte at offset 0)
    mov byte [rbx + 1], al      ; Set Green (byte at offset 1)
    mov byte [rbx + 2], al      ; Set Blue  (byte at offset 2)

    ; Move to the next node in the row (right)
    mov rbx, [rbx + 32]         ; rbx = rbx->right
    jmp .traverse_columns

.next_row:
    ; Move to the next row (down)
    mov rdi, [rdi + 40]         ; rdi = rdi->down
    jmp .traverse_rows

.end_function:
    ; Epilogue
    mov rsp, rbp                ; Restore stack pointer
    pop rbp                     ; Restore base pointer
    ret                         ; Return to caller
    