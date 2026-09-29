.section .data
prompt: .asciz "$ "
buffer: .space 256
argv_array: .space 44

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
  push {r4-r11, lr}
  ldr r0, =buffer

  ldrb r1, [r0]
  cmp r1, #0
  beq parse_fail

  ldr r2, =argv_array
  str r0, [r2], #4

  mov r3, #0
_parse_loop:
  ldrb r4, [r0, r3]
  cmp r4, #0
  beq parse_done

  cmp r4, #' '
  bne _next_char

  mov r5, #0
  strb r5, [r0, r3]

  add r6, r0, r3
  add r6, r6, #1
  str r6, [r2], #4
_next_char:
  add r3, r3, #1
  b _parse_loop

parse_done:
  mov r5, #0
  str r5, [r2]
  mov r0, #1
  b parse_exit
parse_fail:
  mov r0, #0
parse_exit:
  pop {r4-r11, pc}

fork_process:
  push {r4-r11, lr}
  mov r7, #2
  svc #0

  cmp r0, #0
  blt fork_error

  pop {r4-r11, pc}

fork_error:
  mov r7, #1
  mov r0, #1
  svc #0
  pop {r4-r11, pc}

child_process:
  push {r4-r11, lr}
  ldr r0, =buffer
  ldr r1, =argv_array
  mov r2, #0
  mov r7, #11
  svc #0

  mov r7, #1
  mov r0, #1
  svc #0
  pop {r4-r11, pc}

wait_for_child:
  push {r4-r11, lr}
  sub sp, sp, #4

  mov r7, #0x72
  mov r0, #-1
  mov r1, sp
  mov r2, #0
  mov r3, #0 
  svc #0
  
  add sp, sp, #4
  pop {r4-r11, pc}
