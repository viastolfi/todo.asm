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
%define SYS_IOCTL       16
%define SYS_LSEEK        8

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

; Ioctl flags 
%define TCGETS    0x5401
%define TCSETS    0x5402

; Ioctl c_iflag
%define IGNBRK    0x01
%define BRKINT    0x02
%define PARMRK    0x08
%define ISTRIP    0x20
%define INLCR     0x40
%define IGNCR     0x80
%define ICRNL     0x100
%define IXON      0x400

; Ioctl c_oflag
%define OPOST     0x01

; Ioctl c_lflag
%define ECHO      0x08
%define ECHONL    0x40
%define ICANON    0x02
%define ISIG      0x01
%define IEXTEN    0x8000

; Ioctl c_cflag
%define CSIZE     0x30
%define PARENB    0x100
%define CS8       0x30

; Termios definition
struc TERMIOS
  c_iflag: resd 1   ; input modes
  c_oflag: resd 1   ; output modes
  c_cflag: resd 1   ; control modes
  c_lflag: resd 1   ; local modes
  c_cc:    resb 32 ; special characters
endstruc

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

%macro get_termios 1
  syscall3 SYS_IOCTL, STDIN_FILENO, TCGETS, %1
%endmacro

%macro set_termios 1
  syscall3 SYS_IOCTL, STDIN_FILENO, TCSETS, %1
%endmacro
