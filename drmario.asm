################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Dr Mario.
#
# Student 1: Punnawit Payapvattanavong, 1010071663
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       256
# - Unit height in pixels:      256
# - Display width in pixels:    4
# - Display height in pixels:   4
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of where the bottle starts.
ADDR_BOTTLE:
    .word 0x10009268
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

##############################################################################
# Mutable Data
##############################################################################
red: .word 0xff0000
yellow: .word 0xffff00
blue: .word 0x0000ff
grey: .word 0x808080
black: .word 0x161616
white: .word 0xc0c0c0
light_blue: .word 0x50c878
true_black: .word 0x000000
pill_xy: .space 8 # The (x,y) coordinates of the current pill being dropped. x is in [0, 7], y is in [0, 15]
pill_color: .space 8 # The current pill color (color0, color1)
orientation: .byte 0 # 0 if the current pill is horizontally oriented. 1 if vertically oriented.
direction: .byte
##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.
    # For simplicity, I am allocating some variables for specific uses. 
    # $t0 = the memory address of the display
    # $t1 = the memory address of the keyboard
    # $a0 = x coordinates in functions
    # $a1 = y coordinates in functions
    # $a2 = color 0 in functions
    # $a3 = color 1 in functions
main:
    # Initialize the game
    jal draw_background
    jal draw_bottle
    jal generate_pill
    li $a0, 3
    li $a1, 0
    jal update_coordinates
    jal draw_pill
    j game_loop
    
draw_background: # Draws the background
  lw $t0, ADDR_DSPL # t0 = display address
  li $a0, 0 # a0 be the outer loop condition
  draw_col:
    li $a1, 0 #a1 be the inner loop condition
    li $a3, 2
    div $a0, $a3 # Configure the colors into t8 and t9 depending on the current row % 2
    mfhi $a3
    beq $a3 $zero set_color0
    lw $t8, black
    lw $t9, grey
    j draw_row
    set_color0:
    lw $t8, grey
    lw $t9, black
    draw_row:
      li $a3, 2
      div $a1, $a3 # Configure the colors into a2 depending on the current x % 2
      mfhi $a3
      beq $a3 $zero set_color1
      add $a2, $t8, $zero
      j draw_grid
      set_color1:
        add $a2, $t9, $zero
      draw_grid: # Now draw 2x2 grid
      sw $a2, 0($t0)
      addi $t0, $t0, 4
      sw $a2, 0($t0)
      addi $t0, $t0, 252
      sw $a2, 0($t0)
      addi $t0, $t0, 4
      sw $a2, 0($t0)
      addi $t0, $t0, -252
      addi $a1, $a1, 1
      bge $a1, 32, row_done
    j draw_row
    row_done:
    addi $t0, $t0, 256
    addi $a0, $a0, 1
    bge $a0, 32, draw_done
  j draw_col
  draw_done:
  jr $ra

draw_bottle:
  lw $t0, ADDR_DSPL
  lw $a0, white
  lw $a2, light_blue
  li $a1, 0 # loop condition
  add $t0, $t0, 4192 # Start drawing at 12x and 8y which is = 12 * 4 * 2 + 256 * 8 * 2
  draw_left:
    sw $a2, 0($t0)
    addi $t0, $t0, 4
    sw $a0, 0($t0)
    addi $t0, $t0, 252
    sw $a2, 0($t0)
    addi $t0, $t0, 4
    sw $a0, 0($t0)
    addi $t0, $t0, 252
    addi $a1, $a1, 1
    bge $a1, 17, draw_bottom
    j draw_left
  draw_bottom:
    sw $a0, 0($t0)
    addi $t0, $t0, 4
    sw $a0, 0($t0)
    addi $t0, $t0, 252
    sw $a2, 0($t0)
    addi $t0, $t0, 4
    sw $a2, 0($t0)
    addi $t0, $t0, -252
    addi $a1, $a1, 1
    bge $a1, 26, draw_right
    j draw_bottom
  draw_right:
    sw $a0, 0($t0)
    addi $t0, $t0, 4
    sw $a2, 0($t0)
    addi $t0, $t0, 252
    sw $a0, 0($t0)
    addi $t0, $t0, 4
    sw $a2, 0($t0)
    addi $t0, $t0, -772
    addi $a1, $a1, -1
    ble $a1, 9, draw_top
    j draw_right
  draw_top:
    sw $a2, 0($t0)
    addi $t0, $t0, 4
    sw $a2, 0($t0)
    addi $t0, $t0, 252
    sw $a0, 0($t0)
    addi $t0, $t0, 4
    sw $a0, 0($t0)
    addi $t0, $t0, -268
    addi $a1, $a1, -1
    ble $a1, 0, draw_back
    j draw_top
  draw_back:
    lw $t0, ADDR_DSPL
    addi $t0, $t0, 4712
    lw $a0, true_black
    li $a1, 0
    li $a3, 0
    back_x:
    sw $a0, 0($t0)
    addi $t0, $t0, 4
    addi $a1, $a1, 1
    bge $a1, 16, back_y
    j back_x
    back_y:
    addi $t0, $t0, 192
    li $a1, 0
    addi $a3, $a3, 1
    bge $a3, 32, bottle_done
    j back_x
  bottle_done:
  lw $t0, ADDR_DSPL
  sw $a2, 4196($t0) # fill in the holes
  sw $a2, 12896($t0)
  sw $a2, 13224($t0)
  sw $a2, 4524($t0)
  sw $a0, 4224($t0)
  sw $a0, 4228($t0)
  sw $a0, 4480($t0)
  sw $a0, 4484($t0)
  sw $a0, 4232($t0)
  sw $a0, 4236($t0)
  sw $a0, 4492($t0)
  sw $a0, 4488($t0)
  jr $ra

draw_pill: # Draws a horizontal pill with (color0, color1) = ($a2, $a3) at coordinates ($a0, $a1). Color0 on the left and Color1 on the right.
  # x goes from 0 to 6, y goes from 0 to 15.
  lw $t0, ADDR_BOTTLE
  li $t9, 8
  mult $a0, $t9
  mflo $t8
  add $t0, $t0, $t8 # Move pill to correct x
  li $t9, 512
  mult $a1, $t9
  mflo $t8
  add $t0, $t0, $t8 # Move pill to correct y
  sw $a2 0($t0) # Draw left pill
  sw $a2 4($t0)
  sw $a2 256($t0)
  sw $a2 260($t0)
  lb $t9, orientation # handle y case
  beq $t9, 1, draw_pill_y
  sw $a3 8($t0)
  sw $a3 12($t0)
  sw $a3 264($t0)
  sw $a3 268($t0)
  jr $ra
  draw_pill_y:
  sw $a3 512($t0)
  sw $a3 516($t0)
  sw $a3 768($t0)
  sw $a3 772($t0)
  jr $ra

generate_pill: # Generates pill and store (color0, color1) in ($a2, $a3)
  li $v0, 42
  li $a0, 0
  li $a1, 3
  syscall
  beq $a0, 0, red0
  beq $a0, 1, blue0
  lw $a2, yellow
  j second_pill
  red0:
    lw $a2, red
    j second_pill
  blue0:
    lw $a2, blue
  second_pill:
  li $a0, 0
  syscall
  beq $a0, 0, red1
  beq $a0, 1, blue1
  lw $a3, yellow
  j generate_pill_done
  red1:
    lw $a3, red
    j generate_pill_done
  blue1:
    lw $a3, blue
  generate_pill_done:
  jr $ra

move_left:
  jal load_clear
  li $t9, 0
  sb $t9, direction
  jal check_collision
  jal draw_pill
  jal load_pill
  addi $a0 $a0, -1
  jal update_coordinates
  jal draw_pill
  j game_loop

move_right:
  jal load_clear
  li $t9, 1
  sb $t9, direction
  jal check_collision
  jal draw_pill 
  jal load_pill
  addi $a0, $a0, 1
  jal update_coordinates
  jal draw_pill
  j game_loop

move_down:
  jal load_clear
  li $t9, 2
  sb $t9, direction
  jal check_collision
  jal draw_pill 
  jal load_pill
  addi $a1, $a1, 1
  jal update_coordinates
  jal draw_pill
  j game_loop

load_pill: # load (x,y) into (a0, a1) and (color0, color1) into (a2, a3)
  la $t9, pill_xy
  lw $a0, 0($t9)
  lw $a1, 4($t9)
  la $t9, pill_color
  lw $a2, 0($t9)
  lw $a3, 4($t9)
  jr $ra

load_clear: # load (x,y) into (a0, a1) and true black into (a2, a3)
  la $t9, pill_xy
  lw $a0, 0($t9)
  lw $a1, 4($t9)
  lw $a2, true_black
  lw $a3, true_black
  jr $ra
  
rotate:
  li $t9, 3
  sb $t9, direction
  jal load_clear
  jal check_collision
  jal draw_pill
  lb $t9 orientation
  beq $t9, 1, flip_down
  li $t9, 1
  sb $t9, orientation
  la $t9, pill_xy
  lw $a1 4($t9)
  addi $a1, $a1, -1
  sw $a1 4($t9)
  jal load_pill
  jal draw_pill
  j game_loop
  flip_down:
  sb $zero, orientation
  jal load_pill
  addi $a1, $a1, 1
  add $t9, $a2, $zero
  add $a2, $a3, $zero
  add $a3, $t9, $zero
  jal update_coordinates
  jal draw_pill
  j game_loop

check_collision:
  lb $t9 orientation
  lb $t8 direction
  beq $t8, 0, left_collision
  beq $t8, 1, right_collision
  beq $t8, 3, rotate_collision
  add $t9, $t9, $a1
  beq $t9, 15, game_loop
  jr $ra
  left_collision:
  beq $a0, 0, game_loop
  jr $ra
  right_collision:
  sub $t9, $a0, $t9
  beq $t9, 6, game_loop
  jr $ra
  rotate_collision:
  seq $t8, $a0, 7
  and $t8, $t9, $t8
  la $t7, pill_xy
  sub $t8, $a0, $t8
  sw $t8, 0($t7)
  jr $ra
  
update_coordinates:
  la $t9, pill_xy
  sw $a0, 0($t9)
  sw $a1, 4($t9)
  la $t9, pill_color
  sw $a2, 0($t9)
  sw $a3, 4($t9)
  jr $ra

game_loop:
  lw $t1, ADDR_KBRD
  lw $t2, 0($t1)
  beq $t2, 1, keyboard_input
  j game_loop
  keyboard_input: # WASD: 0x77, 0x61, 0x73, 0x64
    lw $t2, 4($t1)
    beq $t2, 0x71, exit
    beq $t2, 0x61, move_left
    beq $t2, 0x64, move_right
    beq $t2, 0x73, move_down
    beq $t2, 0x77, rotate
    j game_loop
    
  j game_loop
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
	# 4. Sleep
    # 5. Go back to Step 1
    # j game_loop

exit:
  lw $t2, 4($t1)
  li $v0, 10
  syscall