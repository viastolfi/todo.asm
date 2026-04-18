%include "linux.inc"
%include "utils.inc"

section .data
  usage_error_msg db "Usage : ./todo db", 10
  usage_error_len equ $ - usage_error_msg

  file_opening_error_msg db "Error while opening db file", 10
  file_opening_error_len equ $ - file_opening_error_msg

  file_extension db ".db", 0

  ; Stored termios value for restoration 
  orig_termios: istruc TERMIOS
    at c_iflag, dd 0
    at c_oflag, dd 0
    at c_cflag, dd 0
    at c_lflag, dd 0
    at c_cc,    db ""
  iend

  ; termios value we will modified
  raw_termios: istruc TERMIOS
    at c_iflag, dd 0
    at c_oflag, dd 0
    at c_cflag, dd 0
    at c_lflag, dd 0
    at c_cc,    db ""
  iend

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
  funcall2 _strcpy, db_name, [rsp + 16]

.db_file_opening:
  ;create memory to store the fd and store it
  sub rsp, 16

  ;add .db extension to db file
  funcall2 _strcat, db_name, file_extension
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
  get_termios orig_termios
  get_termios raw_termios

  ;set c_iflag
  mov r15, IGNBRK
  or  r15, BRKINT
  or  r15, PARMRK
  or  r15, ISTRIP
  or  r15, INLCR
  or  r15, IGNCR
  or  r15, ICRNL
  or  r15, IXON
  not r15
  mov r14, [rel raw_termios + c_iflag]
  and r14, r15
  mov [rel raw_termios + c_iflag], r14

  ;set c_oflag
  mov r15, OPOST
  not r15
  mov r14, [rel raw_termios + c_oflag]
  and r14, r15
  mov [rel raw_termios + c_oflag], r14

  ;set c_lflag
  mov r15, ECHO
  or  r15, ECHONL
  or  r15, ICANON
  or  r15, ISIG
  or  r15, IEXTEN
  not r15
  mov r14, [rel raw_termios + c_lflag]
  and r14, r15
  mov [rel raw_termios + c_lflag], r14


  set_termios raw_termios
  call _main_loop

_main_loop:
  syscall3 SYS_READ, STDIN_FILENO, input_char, 1
  cmp byte[rel input_char], 113
  je _program_end

  syscall3 SYS_WRITE, 1, input_char, 1
  jmp _main_loop

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

  ; reset termios to its base state
  set_termios orig_termios

  syscall1 SYS_EXIT, 0
