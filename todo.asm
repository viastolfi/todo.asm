%include "linux.inc"

section .data
  usage_error_msg db "Usage : ./todo db", 10
  usage_error_len equ $ - usage_error_msg

  file_opening_error_msg db "Error while opening db file", 10
  file_opening_error_len equ $ - file_opening_error_msg

  file_extension db ".db", 0

section .bss
  db_name resb 256
  buffer resb 256
  input_char resb 1

section .text
global _start

_start:
.arg_reading:
  ;get the argc and check it's at least than two
  mov rbx, [rsp]
  cmp rbx, 2
  jl _usage_error

  ;get db name and check if file exist
  mov rsi, [rsp + 16]
  mov rdi, db_name
  call _strcpy

.db_file_opening:
  ;create memory to store the fd and store it
  sub rsp, 16

  ;add .db extension to db file
  mov rbx, db_name
  call _strcat
  ;store the file name in the stack
  mov [rsp + 8], rax

  ;open db file
  mov rax, SYS_OPEN
  mov rdi, [rsp + 8]
  mov rsi, O_RDWR
  mov rdx, 0
  syscall

  ;check if db file exist or not
  cmp rax, 0
  jge .db_file_reading
  funcall2 _file_error_handling, rax, [rsp + 8]

.db_file_reading:
  ;store the file descriptor
  mov [rsp + 16], rax
  ;read the content of the file and print it
  mov rax, SYS_READ
  mov rdi, [rsp + 16]
  mov rsi, buffer
  mov rdx, 256
  syscall

  mov rdi, buffer
  call _strlen
  mov rbx, rax

  call _program_end

;;  int strlen(char* s)
_strlen:
  xor rcx, rcx
len:
  cmp byte[rdi + rcx], 0
  je len_done
  inc rcx
  jmp len
len_done:
  mov rax, rcx
  ret 

;; void strcpy(char* src, char* dest)
_strcpy:
copy:
  mov al, [rsi]
  mov [rdi], al
  cmp al, 0
  je done
  inc rsi
  inc rdi
  jmp copy
done:
  ret

;; char* strcat(char* s1, char* s2)
;; copy s2 at the end of s1
_strcat:
  mov rdi, rbx ; keep the beggining of the string in rdi
  mov rsi, file_extension
parse:
  cmp byte [rbx], 0
  je concat
  inc rbx
  jmp parse
concat:
  cmp byte[rsi], 0
  je finish
  mov cl, byte[rsi]
  mov byte[rbx], cl
  inc rbx
  inc rsi
  jmp concat
finish:
  mov rax, rdi ; return the beggining of the string
  ret
 
; Check if a file error is due to file not existing
; Create it if so
; Exit with error otherwise
;; rdi => file OPEN syscall error
;; rsi => file name
_file_error_handling:
  neg rdi
  cmp rdi, 2
  jne _file_error
  
  mov rax, SYS_OPEN
  mov rdi, rsi
  mov rsi, O_RDWR|O_CREAT|O_TRUNC
  mov rdx, S_IRUSR|S_IWUSR
  syscall
  ret

_file_error:
  mov rax, SYS_WRITE
  mov rdi, 1
  mov rsi, file_opening_error_msg
  mov rdx, file_opening_error_len
  syscall
  call _program_end_error

_usage_error:
  mov rax, SYS_WRITE
  mov rdi, 1
  mov rsi, usage_error_msg
  mov rdx, usage_error_len
  syscall
  call _program_end_error

_program_end_error:
  mov rax, SYS_EXIT
  mov rdi, 1
  syscall

_program_end:
  ;TODO: maybe store db_fd in bss section to avoid stack usage error
  ;close the file
  mov rax, SYS_CLOSE
  mov rdi, [rsp + 16]
  syscall

  mov rax, SYS_EXIT
  mov rdi, 0
  syscall 
