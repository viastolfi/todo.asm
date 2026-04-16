%include "linux.inc"

section .data
  usage_error_msg db "Usage : ./todo db", 10
  usage_error_len equ $ - usage_error_msg

  file_opening_error_msg db "Error while opening db file", 10
  file_opening_error_len equ $ - file_opening_error_msg

  file_extension db ".db", 0

section .bss
  db_name resb 256

section .text
global _start

_start:
  ;get the argc and check it's at least than two
  mov rbx, [rsp]
  cmp rbx, 2
  jl _usage_error

  ;get db name and check if file exist
  mov rsi, [rsp + 16]
  mov rdi, db_name
  call _strcpy

  mov rbx, db_name
  ;add .db extension to db file
  call _strcat

  mov rbx, rax

  ;open/create db file
  mov rax, SYS_OPEN
  mov rdi, rbx
  mov rsi, O_CREAT|O_RDWR|O_TRUNC
  mov rdx, S_IRUSR|S_IWUSR
  syscall

  cmp rax, 0
  jl _file_error

  mov rsi, rbx
  call _strlen
  mov rcx, rax

  mov rax, SYS_WRITE
  mov rdi, 1
  mov rsi, rbx
  mov rdx, rcx
  syscall

  mov rbx, rax
  mov rax, SYS_CLOSE
  mov rdi, rbx
  syscall

  call _program_end

_strlen:
  xor rcx, rcx
len:
  cmp byte[rsi + rcx], 0
  je len_done
  inc rcx
  jmp len
len_done:
  mov rax, rcx
  ret 

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
  mov rax, SYS_EXIT
  mov rdi, 0
  syscall 
