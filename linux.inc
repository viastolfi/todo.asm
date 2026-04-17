; Linux Syscall + flags

; BASICS
%define STDIN_FILENO    0

; Syscall
%define SYS_OPEN        2
%define SYS_EXIT        60
%define SYS_WRITE       1
%define SYS_STAT        4
%define SYS_CLOSE       3
%define SYS_READ        0

; Flags

; Open flags
%define O_RDONLY        0
%define O_WRONLY        1
%define O_RDWR          2
%define O_CREAT         64
%define O_TRUNC         512
%define O_APPEND        1024

; Stat flags
%define S_IRUSR         0o400
%define S_IWUSR         0o200
%define S_IXUSR         0o100

%define S_IRWXU         0o700

; Termios definition
struc TERMIOS
  c_iflag: resd 1   ; input modes
  c_oflag: resd 1   ; output modes
  c_cflag: resd 1   ; control modes
  c_lflag: resd 1   ; local modes
  c_cc:    resb 255 ; special characters
endstruc

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

%macro syscall1 2
  mov rax, %1
  mov rdi, %2
  syscall
%endmacro

%macro syscall3 4
  mov rax, %1
  mov rdi, %2
  mov rsi, %3
  mov rdx, %4
  syscall
%endmacro

%macro funcall1 2
  mov rdi, %2
  call %1
%endmacro

%macro funcall2 3
  mov rdi, %2
  mov rsi, %3
  call %1
%endmacro
