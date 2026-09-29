.section .data
prompt: .asciz "$ "
buffer: .space 256

.section .text
.global _start

_start:
  bl main

main:
  bl display_prompt
  bl read_input
  bl execute_command
  b main

display_prompt:
  push {r4-r11, lr}
  ldr r0, =prompt
  bl print_string
  pop {r4-r11, pc}

print_string:
  push {r4-r11, lr}
  mov r1, r0
  mov r2, #0
_print_loop:
  ldrb r3, [r1, r2]
  cmp r3, #0
  beq _end_print
  add r2, r2, #1
  b _print_loop
_end_print:
  mov r2, r2
  mov r7, #4
  mov r0, #1
  svc #0
  pop {r4-r11, pc} 

read_input:
  push {r4-r11, lr}
  ldr r1, =buffer
  mov r2, #256
  mov r7, #3
  mov r0, #0
  svc #0
  bl strip_input
  pop {r4-r11, pc}

strip_input:
  push {r4-r11, lr}
  mov r2, #0
  ldr r1, =buffer
_strip_loop:
  ldrb r3, [r1, r2]
  cmp r3, #0xa
  beq _remove_newline
  cmp r3, #0x0
  beq _end_loop
  add r2, r2, #1
  b _strip_loop
_remove_newline:
  mov r0, #0
  add r3, r1, r2
  strb r0, [r3]
_end_loop:
  pop {r4-r11, pc}

execute_command:
  push {r4-r11, lr}
  ldr r0, =buffer
  bl parse_command
  cmp r0, #0
  beq end_execute
  bl fork_process
  cmp r0, #0
  beq child_process
  bl wait_for_child
end_execute:
  pop {r4-r11, pc}

parse_command:
  push {lr}
  mov r0, r0
  pop {pc}

fork_process:
  push {r4-r11, lr}
  mov r7, #2
  svc #0
  pop {r4-r11, pc}

child_process:
  push {r4-r11, lr}
  ldr r0, =buffer
  mov r1, #0
  mov r2, #0
  mov r7, #11
  svc #0
  mov r7, #1
  svc #0

wait_for_child:
  mov r7, #0x72
  mov r0, #-1
  mov r1, #0
  mov r2, #0 
  svc #0
  pop {r4-r11, pc}

