%include "linux.inc"
%include "utils.inc"

section .data
  usage_error_msg db "Usage : ./todo db", 10
  usage_error_len equ $ - usage_error_msg

  file_opening_error_msg db "Error while opening db file", 10
  file_opening_error_len equ $ - file_opening_error_msg

  file_extension db ".db", 0

  clear_term_msg db 27,"[2J",27,"[H"
  clear_term_len equ  $ - clear_term_msg

  hide_cursor_msg db 27,"[?25l"
  hide_cursor_len equ $ - hide_cursor_msg

  show_cursor_msg db 27,"[?25h"
  show_cursor_len equ $ - show_cursor_msg

  selected_todos_msg db "> ", 0
  none_selected_todos_msg db "  ", 0

  newline db 10, 0

  open_state_msg db "[ ] ", 0
  close_state_msg db "[X] ", 0

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
  db_name resb        256
  db_content resb     256
  db_size resq        1
  input_char resb     1

  todos_cursor  resb  1
  todos_content resb  257 * 10

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
  sub rsp, 32

  ;add .db extension to db file
  funcall2 _strcat, db_name, file_extension
  ;store the file name in the stack
  mov [rsp], rax

  ;open db file
  syscall3 SYS_OPEN, [rsp], O_RDWR, 0

  ;check if db file exist or not
  cmp rax, 0
  jge .db_file_reading
  funcall2 _file_error_handling, rax, [rsp]

.db_file_reading:
  ;store the file descriptor
  mov [rsp + 8], rax
  ;read the content of the file
  syscall3 SYS_READ, [rsp + 8], db_content, 256
  ;store the size of the content
  mov [rel db_size], rax

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

  ;set c_cflag
  mov r15, CSIZE
  or  r15, PARENB
  not r15
  mov r14, [rel raw_termios + c_cflag]
  and r14, r15
  mov [rel raw_termios + c_cflag], r14

  mov r15, CS8
  mov r14, [rel raw_termios + c_cflag]
  or  r14, r15 
  mov [rel raw_termios + c_cflag], r14

  set_termios raw_termios

  ;hide cursor
  syscall3 SYS_WRITE, 1, hide_cursor_msg, hide_cursor_len

  call _load_todos_content
  mov [rel todos_cursor], 0
  call _main_loop

_main_loop:
  syscall3 SYS_WRITE, 1, clear_term_msg, clear_term_len

  funcall1 _strlen, todos_content
  mov r12, rax
  syscall3 SYS_WRITE, 1, todos_content, r12

  syscall3 SYS_READ, STDIN_FILENO, input_char, 1
  cmp byte[rel input_char], 113
  je _program_end

  cmp byte[rel input_char], 106
  je .increase_cursor

  cmp byte[rel input_char], 107
  je .decrease_cursor

  cmp byte[rel input_char], 13
  je .update_todo_state

  cmp byte[rel input_char], 111
  je .update_todo_state

  jmp _main_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.update_todo_state:
  movzx r9, byte[rel todos_cursor]
  lea r11, [rel todos_content]
  mov r12, 0
  jmp .compare_cursor_state_update

.increase_update_state_cursor:
  inc r12
  inc r11

.compare_cursor_state_update:
  cmp r12, r9
  je .content_todo_state_update

.update_todo_loop:
  mov al, [r11]
  cmp al, 10
  je .increase_update_state_cursor

  cmp al, 0
  je .update_todo_state_done

  inc r11
  jmp .update_todo_loop

.content_todo_state_update:
  ;; content
  ;;|> [X] title
  ;;|> [ ] title
  ;; ^
  ;; r11

  add r11, 3
  ;;|> [ ] title
  ;;|> [X] title
  ;;    ^
  ;;    r11
  mov al, [r11]
  cmp al, 32
  je .content_todo_state_set_done

  jmp .content_todo_state_set_undone

.content_todo_state_set_done:
  mov [r11], 88
  jmp .update_todo_state_done

.content_todo_state_set_undone:
  mov [r11], 32

.update_todo_state_done:
  jmp _main_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.decrease_cursor:
  movzx r9, byte[rel todos_cursor]
  cmp r9, 0
  je _main_loop

  mov rdi, r9
  dec r9
  mov [rel todos_cursor], r9b
  call _update_cursor_content
  jmp _main_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.increase_cursor:
  movzx r9, byte[rel todos_cursor]
  mov rdi , r9
  inc r9
  mov [rel todos_cursor], r9b
  call _update_cursor_content
  jmp _main_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; update cursor in the UI
;; rdi => old cursor
_update_cursor_content:
  lea r9, [rel todos_content]
  mov r12, 0
  jmp .cursor_comp

.tweaks_increase:
  inc r9
.cursor_comp:
  cmp rdi, r12
  je .erase_cursor

  cmp [rel todos_cursor], r12b
  je .add_cursor

.update_loop:   
  mov al, [r9]
  cmp al, 10
  je .tweaks_increase

  cmp al, 0
  je .cursor_done

  inc r9
  jmp .update_loop

.add_cursor:
  mov [r9], 62
  inc r12
  jmp .update_loop

.erase_cursor:
  mov [r9], 32
  inc r12
  jmp .update_loop

.cursor_done:
  ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_load_todos_content:
  ;; state... title
  ;; ^        ^
  ;; 1byte    256byte  
  ;; state is 0 or 1 (open or close)
  ;; eg: 0todo test
  ;; each entry separated by '\n'

  lea r9, [rel db_content] ; store the beginning of the content
  mov r12, 0  ; parsing cursor

.cursor_parsing:
  cmp [rel todos_cursor], r12
  je  .add_selected_char
  jmp .add_none_selected_char

.add_selected_char:
  funcall2 _strcat, todos_content, selected_todos_msg
  jmp .state_parsing

.add_none_selected_char:
  funcall2 _strcat, todos_content, none_selected_todos_msg

.state_parsing:
  inc r12
  mov al, [r9]

  cmp al, 0
  je .parsing_done

  cmp al, 48
  je .add_open_char
  cmp al, 49
  je .add_close_char

  inc r9
  jmp .state_parsing

.add_open_char:
  funcall2 _strcat, todos_content, open_state_msg
  jmp .after_state
.add_close_char:
  funcall2 _strcat, todos_content, close_state_msg
  jmp .after_state
  
.after_state:
  inc r9
  mov r10, r9

.content_loop:
  mov al, [r9]

  cmp al, 10
  je .end_of_line

  cmp al, 0
  je .end_of_file

  inc r9
  jmp .content_loop

.end_of_line:
  mov byte [r9], 0

  funcall2 _strcat, todos_content, r10
  funcall2 _strcat, todos_content, newline

  inc r9
  jmp .cursor_parsing

.end_of_file:
  cmp r10, r9
  je .parsing_done

  funcall2 _strcat, todos_content, r10

.parsing_done:
  ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
  syscall1 SYS_CLOSE, [rsp + 8]

  ;show cursor
  syscall3 SYS_WRITE, 1, show_cursor_msg, show_cursor_len

  ; reset termios to its base state
  set_termios orig_termios

  syscall1 SYS_EXIT, 0
