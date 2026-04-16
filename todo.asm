%include "linux.inc"

section .data
  usage_error_msg db "Usage : ./todo db", 10
  usage_error_len equ $ - usage_error_msg

section .bss

section .text
global _start

_start:
  ;get the argc and check it's at least than two
  mov rbx, [rsp]
  cmp rbx, 2
  jl _usage_error

  ;get db name and check if file exist
  mov rbx, [rsp + 16]

  mov rax, SYS_OPEN
  mov rdi, rbx
  mov rsi, O_CREAT|O_RDWR|O_TRUNC
  mov rdx, S_IRUSR|S_IWUSR
  syscall

  cmp rax, 0
  ; TODO: change this with on file open error
  jl _usage_error

  mov rbx, rax
  mov rax, SYS_CLOSE
  mov rdi, rbx
  syscall

  call _program_end

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
  mov rax, SYS_EXIT
  mov rdi, 0
  syscall 
