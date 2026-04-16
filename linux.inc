; Linux Syscall + flags

; Syscall
%define SYS_OPEN        2
%define SYS_EXIT        60
%define SYS_WRITE       1
%define SYS_STAT        4
%define SYS_CLOSE       3

; Flags

; Open flags
%define O_RDONLY        0
%define O_WRONLY        1
%define O_RDWR          2
%define O_CREAT         64
%define O_TRUNC         512
%define O_APPEND        1024

;Stat flags
%define S_IRUSR         0o400
%define S_IWUSR         0o200
%define S_IXUSR         0o100

%define S_IRWXU         0o700
