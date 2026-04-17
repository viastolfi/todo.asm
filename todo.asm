%include "linux.inc"
%include "utils.inc"

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
  mov rdi, db_name
  mov rsi, [rsp + 16]
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
  syscall3 SYS_OPEN, [rsp + 8], O_RDWR, 0

  ;check if db file exist or not
  cmp rax, 0
  jge .db_file_reading
  funcall2 _file_error_handling, rax, [rsp + 8]

.db_file_reading:
  ;store the file descriptor
  mov [rsp + 16], rax
  ;read the content of the file
  syscall3 SYS_READ, [rsp + 16], buffer, 256

.enable_raw_mode:
  call _program_end

_main_loop:

; Check if a file error is due to file not existing
; Create it if so
; Exit with error otherwise
;; rdi => file OPEN syscall error
;; rsi => file name
_file_error_handling:
  neg rdi
  cmp rdi, 2
  jne _file_error
  
  syscall3 SYS_OPEN, rsi, O_RDWR|O_CREAT|O_TRUNC, S_IRUSR|S_IWUSR
  ret

_file_error:
  syscall3 SYS_WRITE, 1, file_opening_error_msg, file_opening_error_len
  call _program_end_error

_usage_error:
  syscall3 SYS_WRITE, 1, usage_error_msg, usage_error_len
  call _program_end_error

_program_end_error:
  syscall1 SYS_EXIT, 1

_program_end:
  ;TODO: maybe store db_fd in bss section to avoid stack usage error
  ;close the file
  syscall1 SYS_CLOSE, [rsp + 16]

  syscall1 SYS_EXIT, 0
