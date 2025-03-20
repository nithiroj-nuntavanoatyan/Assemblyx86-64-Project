global _start

    ; Group 8 Member
    ; นายณฐีษ์ กีรติธร 663040420-6
    ; นายนิธิโรจน์ นันทวโนทยาน 663040653-3
    ; นายอภิเชษฐ์ ธรรมรักษา 663040671-1

section .bss
    inputFilename resb 100   ; reserve for input file name
    outputFilename resb 100  ; reserve for output file name
    keyInput resb 4          ; reserve for key (3 chars max + null terminator)
    keylength resb 1        ; Store key length
    readbuffer resb buffer_size ; File content buffer (1KB)
    output_length resq 1
    byte_read resq 1

section .data
    LF equ 10
    sys_read equ 0           ; read
    sys_write equ 1          ; write
    sys_open equ 2           ; open file
    sys_close equ 3          ; close file
    sys_exit equ 60          ; exit file
    sys_creat equ 85         ; create file
    stdout equ 1             ; standard out
    stdin equ 0              ; standard in
    O_RDONLY equ 000000q     ; read and write
    null equ 0
    buffer_size equ 1024
    file equ 100
    key equ 4
    fileDescriptor dq 0     
    linefeed db 10
    success_exit equ 0
    error_exit equ 1

    msgInputFileName db "Enter input filename: ", null
    msg_lenInputFileName equ $ - msgInputFileName
    
    msgOutputFileName db "Enter output filename: ", null
    msg_lenOutputFileName equ $ - msgOutputFileName
    
    msgKeyInput db "Enter key (max. 3 Characters): ", null
    msg_lenKeyInput equ $ - msgKeyInput

    msgReadinginputFile db "Reading input file...OK", LF, null
    msg_lenmsgReadinginputFile equ $ - msgReadinginputFile

    msgGenerateoutputFile db "Generating output file...OK", LF, null
    msg_lenmsgGenerateoutputFile equ $ - msgGenerateoutputFile

    msgGeneratedsuccess db " generated", LF, null
    msg_lenmsgGeneratedsuccess equ $ - msgGeneratedsuccess

    errOpenFile db "Error opening file", LF, null
    errOpenFile_len equ $ - errOpenFile
    
    errReadFile db "Error reading file", LF, null
    errReadFile_len equ $ - errReadFile
    
    errWriteFile db "Error writing file", LF, null
    errWriteFile_len equ $ - errWriteFile

    errEmptyInput db "Error: Empty input", LF, null
    errEmptyInput_len equ $ - errEmptyInput

    errKeytooLong db "Error: Maximum character for key is 3 ", LF, null
    errKeytooLong_len equ $ - errKeytooLong

section .text
_start:
    mov rax, sys_write              
    mov rdi, stdout                 
    mov rsi, msgInputFileName       ; Enter input filename message
    mov rdx, msg_lenInputFileName   ; length of input file name message
    syscall                         

    mov rax, sys_read               
    mov rdi, stdin                  
    mov rsi, inputFilename          ; file name
    mov rdx, 99                     ; not 100 leave 1 space for making null terminator
    syscall

    cmp rax, 1                      ; check if byte read
    jl error_emptyinput

    dec rax
    mov byte [inputFilename + rax], 0 ; replace last one to 0 make it null terminated

    mov rax, sys_write              
    mov rdi, stdout                 
    mov rsi, msgOutputFileName      ; enter output file name message
    mov rdx, msg_lenOutputFileName  ; length of enter output filename message
    syscall
    
    mov rax, sys_read            
    mov rdi, stdin            
    mov rsi, outputFilename         ; output file from terminal
    mov rdx, 99                     ; not 100 leave 1 space for making null terminator
    syscall

    cmp rax, 1                      ; check if byte read
    jl error_emptyinput

    dec rax
    mov byte [outputFilename + rax], 0 ; replace last bit to 0 make it null terminated

    mov rbx, 0
output_length_loop:
    cmp byte [outputFilename + rbx], 0 ; compare byte at outputfilename + ebx to 0 to check null terminated at the end of string
    je output_length_done
    inc rbx
    jmp output_length_loop
output_length_done:
    mov [output_length], bl ; store length from bl to output_length

    ; Get encryption key
    mov rax, sys_write              
    mov rdi, stdout                 
    mov rsi, msgKeyInput            ; message enter key
    mov rdx, msg_lenKeyInput        ; length of message enter key
    syscall
    
    mov rax, sys_read               
    mov rdi, stdin                  
    mov rsi, keyInput               ; recieve key input from terminal 
    mov rdx, 100                    ; 100 chars max for key
    syscall

    cmp rax, 1                      ; ckeck error
    jl error_emptyinput

    cmp rax, 4
    jg errorkeylong 

    dec rax
    mov byte [keyInput + rax], 0    ; make it null terminate

    ; find key length
    mov rbx, 0
loop_keylength:
    cmp byte [keyInput + rbx], 0    ; compare byte to check null terminator
    je findkeylength_finish
    inc rbx
    jmp loop_keylength
findkeylength_finish:
    mov [keylength], bl             ; store key length from bl use bl because it the least in rbx

    ; Open input file
    mov rax, sys_open               
    mov rdi, inputFilename          ; filename to open
    mov rsi, O_RDONLY               ; read only
    mov rdx, 0644o                  ; make permission to write file and read file
    syscall
    
    ; Check for errors
    cmp rax, 0
    jl error_openfile              
    mov [fileDescriptor], rax       ; save file descriptor
    
    mov rax, sys_read               
    mov rdi, [fileDescriptor]       ; file descriptor
    mov rsi, readbuffer             ; address of where to place data
    mov rdx, buffer_size            ; count of characters to read in this is 1024 byte
    syscall
    
    cmp rax, 0
    jl error_readfile              ; Jump if rax < 0
    mov [byte_read], rax            ; move number of byte that has read to byte read
    
    mov rax, sys_close              ; close file
    mov rdi, [fileDescriptor]
    syscall

    mov rax, sys_write                  ; show read input file message
    mov rdi, stdout
    mov rsi, msgReadinginputFile
    mov rdx, msg_lenmsgReadinginputFile
    syscall

    mov rsi, 0                      ; index for buffer to get character
    mov rbx, 0                      ; index for key 

encrypt_loop:
    cmp rsi, [byte_read]            ; check if all byte are encrypted
    je write_file
    
    mov al, [readbuffer + rsi]      ; get character from buffer at index    
    mov cl, [keyInput + rbx]        ; get character from key at index
    xor al, cl                      ; xor 
    mov [readbuffer + rsi], al      ; store encrypted text to buffer in the same position as the original text
    
    inc rsi                         ; increase index to find next buffer character
    inc rbx                         ; increase index to find next key character
    
    cmp bl, [keylength]            ; compare the key value to key length if less encrypt buf if not less reset key so that it can loop again
    jl continue_encrypt
    mov rbx , 0                   ; reset key index if reached key length

continue_encrypt:
    jmp encrypt_loop

write_file:   
    mov rax, sys_creat              ; create file
    mov rdi, outputFilename         ; filename
    mov rsi, 0644o                  ; permission
    syscall

    cmp rax, 0
    jl error_openfile
    mov [fileDescriptor], rax

    mov rax, sys_write              ; write file
    mov rdi, [fileDescriptor]
    mov rsi, readbuffer             ; address of characters to write
    mov rdx, [byte_read]            ; number of bytes or character to write
    syscall

    mov rax, sys_write                      ; show generating input file message
    mov rdi, stdout
    mov rsi, msgGenerateoutputFile
    mov rdx, msg_lenmsgGenerateoutputFile
    syscall
    
    mov rax, sys_write                      ; show output file name
    mov rdi, stdout
    mov rsi, outputFilename
    mov rdx, [output_length]
    syscall

    mov rax, sys_write                      ; show [filename] generated
    mov rdi, stdout
    mov rsi, msgGeneratedsuccess
    mov rdx, msg_lenmsgGeneratedsuccess
    syscall
    
    mov rax, sys_close                      ; close
    mov rdi, [fileDescriptor]
    syscall
    
    mov rax, sys_exit                       ; exit
    mov rdi, success_exit                   ; return 0
    syscall

errorkeylong:
    mov rax, sys_write
    mov rdi, stdout
    mov rsi, errKeytooLong
    mov rdx, errKeytooLong_len
    syscall
    jmp exit_error

error_emptyinput:
    mov rax, sys_write
    mov rdi, stdout
    mov rsi, errEmptyInput
    mov rdx, errEmptyInput_len
    syscall
    jmp exit_error

error_openfile:
    mov rax, sys_write
    mov rdi, stdout
    mov rsi, errOpenFile
    mov rdx, errOpenFile_len
    syscall
    jmp exit_error
    
error_readfile:
    mov rax, sys_write
    mov rdi, stdout
    mov rsi, errReadFile
    mov rdx, errReadFile_len
    syscall
    jmp exit_error
    
error_writefile:
    mov rax, sys_write
    mov rdi, stdout
    mov rsi, errWriteFile
    mov rdx, errWriteFile_len
    syscall
    
exit_error:
    mov rax, sys_exit
    mov rdi, error_exit                      ; Error exit code
    syscall