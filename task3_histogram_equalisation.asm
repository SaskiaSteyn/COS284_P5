; ==========================
; Group member 01: Saskia_Steyn_17267162
; Group member 02: Amadeus_Fidos_22526162
; Group member 03: Rorisang_Manamela_21428574
; Group member 05: Patterson_Rainbird-Webb_17104361
; Group member 04: Nicolaas_Johan_Jansen_van_Rensburg_22590732
; ==========================

section .data
double_point_five dq 0.5        ; const double_point_five = 0.5


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
    ; Check if the row pointer (rdi) = null (end of list)
    test rdi, rdi
    je .end_function            ; if == null, reached end of list

    ; Traverse the row
    mov rbx, rdi                ; rbx used to traverse horizontally

.traverse_columns:
    ; Check if the current node (rbx) is null
    test rbx, rbx
    je .next_row                ; if == null, go to next row

    ; Load the CdfValue from the PixelNode (byte at offset 3)
    movzx eax, byte [rbx + 3]   ; Load CdfValue as unsigned char into 32-bit eax
    cvtsi2sd xmm0, eax          ; Convert 32-bit integer in eax to double-precision in xmm0
    addsd xmm0, qword [double_point_five]  ; Add 0.5 to xmm0 for rounding

    ; Convert double to int with truncation and clamp to [0, 255]
    cvttsd2si eax, xmm0         ; Convert and truncate double in xmm0 to integer in eax
    cmp eax, 255
    jle .update_pixel           ; If value <= 255, continue
    mov eax, 255                ; Clamp to 255 if value exceeds

.update_pixel:
    ; Now rax contains the new pixel value, set Red, Green, Blue
    mov byte [rbx], al          ; Set Red
    mov byte [rbx + 1], al      ; Set Green
    mov byte [rbx + 2], al      ; Set Blue

    ; Move to the next node in the row (right)
    mov rbx, [rbx + 8]         ; rbx = rbx->right
    jmp .traverse_columns

.next_row:
    ; Move to the next row (down)
    mov rdi, [rdi + 16]         ; rdi = rdi->down
    jmp .traverse_rows

.end_function:
    ; Epilogue
    mov rsp, rbp                ; Restore stack pointer
    pop rbp                     ; Restore base pointer
    ret                         ; Return to caller
    

 xorps xmm0, xmm0            ; Clear xmm0 register for cleanliness
    ret 