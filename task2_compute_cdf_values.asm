; ==========================
; Group member 01: Saskia_Steyn_17267162
; Group member 02: Amadeus_Fidos_22526162
; Group member 03: Rorisang_Manamela_21428574
; Group member 05: Patterson_Rainbird-Webb_17104361
; Group member 04: Nicolaas_Johan_Jansen_van_Rensburg_22590732
; ==========================

section .bss
    histogram resb 256            ; Reserve space for histogram
    cumulativeHistogram resb 256   ; Reserve space for cumulative histogram
    cdfMin dq 0                   ; Store the minimum non-zero CDF
    totalPixels dq 0               ; Total number of pixels
    tempGray resb 1                ; Temporary storage for grayscale value

section .text
    global computeCDFValues

computeCDFValues:
    ; Input: rdi = PixelNode* head
    xor rax, rax                  ; Clear rax (used for indexing)
    xor rbx, rbx                  ; Clear rbx (used for histogram index)
    mov rcx, 256                  ; Set loop counter for histogram initialization

    ; Step 1: Initialize Histogram
    lea rdi, [histogram]          ; Load address of histogram
    rep stosb                     ; Initialize histogram to 0

    ; Step 2: First Pass - Compute Histogram
first_pass:
    mov rdi, [rdi]                ; Load head of linked list
    cmp rdi, 0                    ; Check if the node is NULL
    je  compute_cdf               ; Jump to CDF computation if NULL

    ; Convert RGB to grayscale
    movzx rbx, byte [rdi + 0]     ; Load Red
    movzx rdx, byte [rdi + 1]     ; Load Green
    movzx rsi, byte [rdi + 2]     ; Load Blue

    ; Compute gray = 0.299 * Red + 0.587 * Green + 0.114 * Blue
    ; Using fixed-point arithmetic to avoid floating-point
    ; gray = (299 * Red + 587 * Green + 114 * Blue) / 1000
    imul rbx, 299                  ; Red * 0.299
    imul rdx, 587                  ; Green * 0.587
    imul rsi, 114                  ; Blue * 0.114
    add rbx, rdx                   ; Add Green contribution
    add rbx, rsi                   ; Add Blue contribution
    mov rdi, 1000                  ; Divisor
    xor rdx, rdx                   ; Clear rdx for division
    div rdi                        ; rbx = gray (0-255)

    ; Store temporary grayscale intensity
    mov [tempGray], al            ; Store gray in tempGray
    movzx rdi, byte [tempGray]    ; Move gray to rdi for histogram increment

    ; Increment histogram
    inc byte [histogram + rdi]    ; histogram[gray] += 1

    ; Move to the next pixel node
    mov rdi, [rdi + 24]           ; Move to next node (next pointer)
    jmp first_pass

compute_cdf:
    ; Step 3: Compute Cumulative Histogram (CDF)
    xor rax, rax                  ; Cumulative frequency = 0
    mov rcx, 256                  ; Loop over 256 intensity levels
    lea rdi, [cumulativeHistogram] ; Load address of cumulativeHistogram

cdf_loop:
    movzx rbx, byte [histogram + rax] ; Get histogram value
    add rax, rbx                  ; Update cumulative frequency
    mov [rdi], al                 ; Store cumulative frequency
    inc rdi                       ; Move to the next cumulative histogram entry
    inc rax                       ; Next intensity level
    loop cdf_loop                 ; Repeat for all intensity levels

    ; Step 4: Find Minimum Non-Zero CDF Value
    mov rax, 0                    ; Reset rax for finding cdfMin
    mov rcx, 256                  ; Loop counter
    lea rdi, [cumulativeHistogram] ; Load address

find_min:
    movzx rbx, byte [rdi]         ; Get current CDF value
    test rbx, rbx                 ; Check if it's non-zero
    jz  skip_min                  ; If zero, skip
    cmp rax, 0                    ; Compare with current min
    jz  update_min                ; If min is zero, update
    movzx rcx, al
    cmp rbx, rcx                   ; Compare with current minimum
    jge skip_min                  ; If not less, skip
update_min:
    mov al, bl                   ; Update cdfMin with the new min

skip_min:
    inc rdi                       ; Move to the next cumulative histogram entry
    loop find_min                 ; Repeat for all intensity levels

    ; Step 5: Second Pass - Normalize CDF and Update Pixels
    mov rdi, [rdi]                ; Load head of linked list
    mov rbx, 0                    ; Reset pixel counter

second_pass:
    cmp rdi, 0                    ; Check if the node is NULL
    je  done                      ; Jump to done if NULL

    ; Retrieve the grayscale intensity stored in CdfValue
    movzx rsi, byte [rdi + 3]     ; Load CdfValue (which temporarily stores gray)

    ; Compute the normalized CDF value
    movzx rdx, byte [cumulativeHistogram + rsi] ; Get CDF
    sub rdx, rax                  ; Subtract cdfMin
    mov rsi, totalPixels          ; Load totalPixels
    sub rsi, rax                  ; totalPixels - cdfMin
    test rsi, rsi                 ; Check for division by zero
    jz  clamped_value             ; If zero, jump to clamping

    ; Normalize
    mov rdi, 255                  ; Multiply by 255
    imul rdx                      ; rdx = (cdfValue - cdfMin) * 255
    xor rax, rax                  ; Clear rax for division
    div rsi                       ; rdx = (cdfValue - cdfMin) / (totalPixels - cdfMin)

clamped_value:
    ; Clamp CdfValue between 0 and 255
    cmp rdx, 255
    jg  set_max
    jmp store_value

set_max:
    mov rdx, 255                  ; Set to max value

store_value:
    mov [rdi + 3], dl             ; Store normalized cdfValue back into CdfValue field
    mov rdi, [rdi + 24]           ; Move to the next pixel node
    mov rax, totalPixels
    inc rax
    mov [totalPixels], rax
    jmp second_pass               ; Repeat

done:
    ret
