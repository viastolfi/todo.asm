;;  int strlen(char* s)
;;  return the length of s
;;  rdi - char* s
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

;; void strcpy(char* s1, char* s2)
;; copy s2 on s1
;; rdi - char* s1
;; rsi - char* s2
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
;; rdi - char* s1
;; rsi - char* s2
_strcat:
  mov rbx, rdi; keep the beggining of the string in rdi
parse:
  cmp byte [rdi], 0
  je concat
  inc rdi 
  jmp parse
concat:
  cmp byte[rsi], 0
  je finish
  mov cl, byte[rsi]
  mov byte[rdi], cl
  inc rdi
  inc rsi
  jmp concat
finish:
  mov rax, rbx; return the beggining of the string
  ret
 
