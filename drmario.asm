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

.macro beqal(%x %y %z)
    beq %x %y beqal1
    j beqal2
    beqal1:
      jal %z
    beqal2:
  .end_macro

.macro bgtal(%x %y %z)
  bgt %x %y bgtal1
  j bgtal2
  bgtal1:
    jal %z
  bgtal2:
  .end_macro

.macro generate_color(%n)
  li $v0 42
  li $a0, 0
  li $a1, 3
  syscall
  beq $a0 0 match_red
  beq $a0 1 match_blue
  lw %n yellow
  j end_match
  match_red:
  lw %n red
  j end_match
  match_blue:
  lw %n blue
  end_match:
  .end_macro

.macro push()
  sub $sp, $sp,4
  sw  $ra, 0($sp)	# push %reg
  .end_macro
  
.macro pop()
  lw  $ra, 0($sp)	# pop %reg
  add $sp, $sp,4
  .end_macro

.macro jal2(%f)
  push()
  jal %f
  pop()
  .end_macro

.macro repeat(%j %n)
  li $t3, 0
  rep:
  jal %j
  addi $t3 $t3 1
  bne $t3 %n rep
  .end_macro

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
cream: .word 0xede8d0
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
    # $t3 = loop condition for repeat
    # $a0 = x coordinates in functions
    # $a1 = y coordinates in functions
    # $a2 = color 0 in functions
    # $a3 = color 1 in functions
    # $s0 = counter
main:
    # Initialize the game
    jal draw_background
    jal draw_bottle
    li $s0, 0
    repeat(generate_virus, 4)
    j generate_pill
    
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

set_t0: # Set $t0 to the coordinates on the bitmap to draw
  lw $t0, ADDR_BOTTLE
  li $t9, 8
  mult $a0, $t9
  mflo $t8
  add $t0, $t0, $t8 # Move pill to correct x
  li $t9, 512
  mult $a1, $t9
  mflo $t8
  add $t0, $t0, $t8 # Move pill to correct y
  jr $ra

draw_pill: # Draws a pill with (color0, color1) = ($a2, $a3) at coordinates ($a0, $a1). Color0 on the left/top and Color1 on the right/bottom.
  # x goes from 0 to 7, y goes from 0 to 15.
  jal2(set_t0)
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

draw_virus: # Draws a pill with color = $a2 at coordinates ($a0, $a1)
  jal2(set_t0)
  lw $t9 cream
  sw $a2 0($t0)
  sw $t9 4($t0)
  sw $a2 260($t0)
  sw $t9 256($t0)
  jr $ra

draw_cell: # Draws cell at ($a0, $a1) with color ($a2)
  jal2(set_t0)
  sw $a2 0($t0) # Clear cell
  sw $a2 4($t0)
  sw $a2 256($t0)
  sw $a2 260($t0)
  jr $ra

clear_cell: # Clears a cell with coordinates ($a0, $a1)
  jal2(set_t0)
  lw $a2 true_black
  sw $a2 0($t0) # Clear cell
  sw $a2 4($t0)
  sw $a2 256($t0)
  sw $a2 260($t0)
  # Checks if any pills were on top of current cleared cell
  addi $t0 $t0 -256
  lw $a2 0($t0)
  addi $t0 $t0 -256
  beq $a2 0xff0000 drop_cell
  beq $a2 0xffff00 drop_cell
  beq $a2 0x0000ff drop_cell
  addi $t0 $t0 512
  jr $ra

drop_cell:
  addi $t2 $t0 0
  addi $t7 $a1 -1
  addi $a1 $a1 -1
  drop_to:
  addi $t2 $t2 512
  lw $t9 512($t2)
  addi $a1 $a1 1
  beq $t9 0 drop_to
  jal2(draw_cell)
  addi $a1 $t7 0
  jal2(clear_cell)
  addi $a1 $a1 1
  jr $ra

generate_pill: # Generates pill and store (color0, color1) in ($a2, $a3)
  lw $t0 ADDR_BOTTLE
  lw $t9 24($t0)
  bne $t9 0 exit
  lw $t9 32($t0)
  bne $t9 0 exit
  generate_color($a2)
  generate_color($a3)
  sb $zero orientation
  li $a0, 3
  li $a1, 0
  jal update_coordinates
  jal draw_pill
  j game_loop

generate_virus:
  generate_color($a2)
  li $v0, 42
  li $a0, 0
  li $a1, 8
  syscall
  addi $t9, $a0, 0
  li $a0, 0
  syscall
  addi $a1, $a0, 8
  addi $a0, $t9, 0
  jal2(draw_virus)
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
  lw $t0 ADDR_BOTTLE
  lb $t9 orientation
  lb $t8 direction
  beq $t8, 0, left_collision
  beq $t8, 1, right_collision
  beq $t8, 3, rotate_collision
  add $t7, $t9, $a1
  li $t8, 512
  mult $t7, $t8
  mflo $t8
  add $t0 $t0 $t8
  li $t8 8
  mult $t8, $a0
  mflo $t7
  add $t0 $t0 $t7
  lw $t7 512($t0)
  bne $t7, 0, check_combo #generate_pill
  seq $t9 $t9 0
  mult $t8 $t9
  mflo $t9
  add $t0 $t0 $t9
  lw $t9 512($t0)
  bne $t9, 0, check_combo #generate_pill
  jr $ra
  left_collision:
  li $t8, 512
  mult $a1, $t8
  mflo $t8
  add $t0 $t0 $t8
  li $t8 8
  mult $t8, $a0
  mflo $t8
  add $t0 $t0 $t8
  lw $t8 -8($t0)
  bne $t8, 0, game_loop
  li $t8, 512
  mult $t8 $t9
  mflo $t9
  add $t0 $t0 $t9
  lw $t9 -8($t0)
  bne $t9, 0, game_loop
  jr $ra
  right_collision:
  li $t8, 512
  mult $a1, $t8
  mflo $t8
  add $t0 $t0 $t8
  li $t8 8
  sub $t7, $a0, $t9
  mult $t8, $t7
  mflo $t8
  add $t0 $t0 $t8
  lw $t8 16($t0)
  bne $t8, 0, game_loop
  li $t8, 512
  mult $t8 $t9
  mflo $t9
  add $t0 $t0 $t9
  lw $t9 16($t0)
  bne $t9, 0, game_loop
  jr $ra
  rotate_collision:
  li $t8, 512
  mult $a1, $t8
  mflo $t8
  add $t0 $t0 $t8
  li $t8 8
  mult $t8, $a0
  mflo $t8
  add $t0 $t0 $t8
  lw $t8 520($t0)
  sgt $t7, $t8, 0
  and $t7, $t9, $t7
  lw $t8 504($t0)
  sgt $t8, $t8, 0
  and $t8, $t7, $t8
  beq $t8, 1, game_loop
  seq $t8, $t8, 0
  and $t7, $t8, $t7
  sub $t8, $a0, $t7
  la $t7, pill_xy
  sw $t8, 0($t7)
  jr $ra

check_combo:
  lw $t0 ADDR_BOTTLE
  li $a1 -1
  addi $t0, $t0, -448
  combo_x_loop:
  lw $t1 white # Color
  li $t2 0 # Color counter
  li $a0 0 # Inner loop counter
  addi $a1, $a1, 1
  addi $t0, $t0, 448
  combo_x:
    lw $t9 0($t0)
    seq $t1, $t9, $t1
    add $t2, $t2, $t1
    mult $t2, $t1
    mflo $t2
    sne $t8, $t9, 0 #
    mult $t8, $t2 #
    mflo $t2 #
    add $t1, $t9, $zero
    beqal($t2, 3, clear_row)
    bgtal($t2, 3, clear_cell)
    addi $a0, $a0, 1
    addi $t0, $t0, 8
    beq $a1, 16, check_combo_y #generate_pill
    beq $a0, 8, combo_x_loop
    j combo_x
  check_combo_y:
  lw $t0 ADDR_BOTTLE
  li $a0 -1
  addi $t0, $t0, 8184
  combo_y_loop:
  lw $t1 white # Color
  li $t2 0 # Color counter
  li $a1 0 # Inner loop counter
  addi $a0, $a0, 1
  addi $t0, $t0, -8184
  combo_y:
    lw $t9 0($t0)
    seq $t1, $t9, $t1
    add $t2, $t2, $t1
    mult $t2, $t1
    mflo $t2
    sne $t8, $t9, 0 #
    mult $t8, $t2 #
    mflo $t2 #
    add $t1, $t9, $zero
    beqal($t2, 3, clear_col)
    bgtal($t2, 3, clear_cell)
    addi $a1, $a1, 1
    addi $t0, $t0, 512
    beq $a0, 8, generate_pill
    beq $a1, 16, combo_y_loop
    j combo_y
  
clear_row:
  push()
  addi $a0 $a0 -3
  jal clear_cell
  addi $a0 $a0 1
  jal clear_cell
  addi $a0 $a0 1
  jal clear_cell
  addi $a0 $a0 1
  jal clear_cell
  pop()
  jr $ra

clear_col:
  push()
  addi $a1 $a1 -3
  jal clear_cell
  addi $a1 $a1 1
  jal clear_cell
  addi $a1 $a1 1
  jal clear_cell
  addi $a1 $a1 1
  jal clear_cell
  pop()
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
  li $v0, 32
  li $a0, 1
  syscall
  addi $s0 $s0 1
  beq $s0, 50, move_down
  slti $t9 $s0, 50
  mult $s0, $t9
  mflo $s0
  j game_loop
  keyboard_input: # WASD: 0x77, 0x61, 0x73, 0x64
    lw $t2, 4($t1)
    beq $t2, 0x71, exit
    beq $t2, 0x61, move_left
    beq $t2, 0x64, move_right
    beq $t2, 0x73, move_down
    beq $t2, 0x77, rotate
  
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
  li $v0, 10
  syscall
