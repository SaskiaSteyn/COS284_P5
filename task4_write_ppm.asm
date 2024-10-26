; ==========================
; Group member 01: Name_Surname_student-nr
; Group member 02: Name_Surname_student-nr
; Group member 03: Name_Surname_student-nr
; Group member 04: Name_Surname_student-nr
; Group member 05: Name_Surname_student-nr
; ==========================

section .text
    global writePPM

writePPM:
    ; Allocate space on the stack
    sub rsp, 40                     

    ; 1. Open the File: Open the file for reading
    mov rdi, rdi                        ; Filename is passed in the first argument (rdi) - (Input 1)
    mov rsi, mode_str                   ; Mode = "r"
    call fopen                          ; fmopen is a function for opening files

    test rax, rax                       ; Check if file opened successfully
    jz .error                           ; If it failed, handle it
    mov rbx, rax                        ; Save file pointer


    mov rdi, [rdi]                      ; Load head of linked list (PixelNode* head) - (Input 2)
    cmp rdi, 0                          ; Check if the node is NULL
    je  compute_cdf                     ; Jump to CDF computation if NULL


.error:
    mov rax, 0                          ; Return null in case of error
    add rsp, 40                         ; Restore stack
    ret




    