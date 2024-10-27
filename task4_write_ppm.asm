; ==========================
; Group member 01: Saskia_Steyn_17267162
; Group member 02: Amadeus_Fidos_22526162
; Group member 03: Rorisang_Manamela_21428574
; Group member 05: Patterson_Rainbird-Webb_17104361
; Group member 04: Nicolaas_Johan_Jansen_van_Rensburg_22590732
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




    