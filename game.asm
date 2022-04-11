##################################################################### #
# CSCB58 Winter 2022 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Name, Student Number, UTorID, official email #
# Bitmap Display Configuration:
# - Unit width in pixels: 4
# - Unit height in pixels: 4
# - Display width in pixels: 256
# - Display height in pixels: 256 
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones) 
# - Milestone 3 (choose the one the applies)
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features) 
# 1. Health/score [2 marks]
# 2. Fail condition [1 mark]
# 3. Win condition [1 mark]
# 4. Moving objects: the monster [2 mark]
# 5.Start menu [1 mark]
# 6. Pick-up effects [2 marks]: blue one: gain one point
#				pink one: trap that can trap the monster
#				white one: recover one life
# Link to video demonstration for final submission:
# - https://www.youtube.com/watch?v=m4VY3sSiq3I
# Are you OK with us sharing the video with people outside course staff?
# - yes / no / yes, and please share this project github link as well! #
# Any additional information that the TA needs to know:
# - (write here, if any)
# #####################################################################
.eqv	DISPLAY_FIRST_ADDRESS	0x10008000
# width = 64, height = 64
.eqv	DISPLAY_LAST_ADDRESS	0x1000BFFC				# update this given the values below shift +(64*64-1)*4
.eqv	DISPLAY_LFTFST_ADDRESS	0x1000BF00				# left spot on last line for character + (64*64-63)*4
.eqv	DISPLAY_MIDLST_ADDRESS	0x1000BF80				
.eqv	SHIFT_NEXT_ROW		256					# next row shift = width*4 = 64*4
.eqv	DISPLAY_SCORE		0x10008130				# bottom right corner +(64*27-4)*4
.eqv	DISPLAY_LIVES		0x100081E8				# top right corner +(64*2-6)*4
.eqv	DISPLAY_DEAD		0x10008C58				# top right corner +(64*13-42)*4
.eqv	DISPLAY_SPLASH		0x10008C14				# top right corner +(64*13-59)*4
.eqv	COLOUR_BLACK		0x000000
.eqv	COLOUR_NIGHT		0x00112135
.eqv	COLOUR_RED		0x00FF0000
.eqv	COLOUR_ROCK_DARK	0x00424242
.eqv	COLOUR_ROCK_LIGHT	0x006c6c6c
.eqv 	COLOUR_GREEN		0x00ff00
.eqv	COLOUR_YELLOW		0xFFFF00
.eqv	COLOUR_HEART		0x00fb91b3
.eqv	COLOUR_BACK		0x00BBD4
.eqv	COLOUR_WHITE		0xFFFFFF
.eqv	COLOUR_NUMBER		0x0092aed1
.eqv	COLOUR_DIM_SHIFT	1122355						# colour shift 00x00112033
.eqv	COLOUR_FOOD		0x002195F3

.text
.globl main
main:	#jal draw_name
	# ------------------------------------
	# wait 2000 milliseconds
	#li	$v0, 32
	#li	$a0, 4000
	# ------------------------------------
	# clear screen
	li	$a0, DISPLAY_FIRST_ADDRESS
	li	$a1, DISPLAY_LAST_ADDRESS
	li	$a2, -SHIFT_NEXT_ROW						# negative width
	#jal	clear								# jump to clear and save position to $ra
	# ------------------------------------
	# draw a base line on the bottom
	
	main_menu:
		
		jal draw_menu
		jal draw_arrow_one
		
		start_choice:
			li $t1, 0xffff0000
			lw $t2, ($t1)			
			bne $t2, 1, start_choice
			jal move_arrow
			li $t0, 0x1000AA20
			addi $t0, $t0, 28
			lw $t3, ($t0)
			beq $t3, COLOUR_GREEN, initialize
			j start_choice
			
	initialize:
		#jal clear_screen
		jal draw_obstacle
		jal draw_medicine
		li $t1, 64
		li $t2, 1
		li $t3, COLOUR_GREEN
		sw $t3, ($t0)
		li $t8, 0x000000

		
	draw_line:
		beq $t2, $t1, draw_char_first
		mul $t4, $t2, 4
		add $t5, $t0, $t4
		li $v0, 32
		li $a0, 8
		syscall 
		sw $t3, ($t5)
		addi $t2, $t2, 1
		j draw_line
	
	li $t3, COLOUR_GREEN
	draw_char_first:
		addi $s0, $t0, -SHIFT_NEXT_ROW
		add $s1, $s0, $zero
		jal draw_char
	draw_enemy_first:
		jal draw_enemy
		li $s3, 0
		li $s4, 0
		li $s5, 3
		li $s6, 5
		li $s7, 0
	#draw_medicine_first:
		
	#--------------------------------------
	# s0: old location
	# s1: new location
	# s2: enemy location
	# s3: enemy go right flag
	# s4: update clock
	# s5: number of heart
	# s6: score
	# s7: state of the walk
	main_loop:
		li	$t8, 0xffff0000
		lw	$t9, 0($t8)
		bne	$t9, 1, main_update
		jal	keypress						# jump to keypress and save position to $ra		
		
		main_update:
			ble $s5, 0, end_game
			bge $s6, 12, win_game
			li $a0, DISPLAY_SCORE
			li $a1, COLOUR_NUMBER
			move	$a2, $s6
			li	$a3, COLOUR_NIGHT
			jal	draw_number
			
			li $a0, 0x100081E8
			addi $a1, $s5, 0
			jal draw_lives
			addi $s4, $s4, 1	# clock +1
			bne $s4, 5, main_collision	# update the enemy's possition once every 6 cycles
			li $v0, 32
			li $a0, 50
			syscall 
			jal shift_enemy
			jal draw_enemy
			addi $s4, $s4, -5
			
			addi $t0, $s1, SHIFT_NEXT_ROW
			lw $t3, ($t0)
			bne $t3, $t2, main_collision	# changed!!!!
			lw $t8, 256($s0)
			beq $t8, COLOUR_YELLOW, main_collision
			jal clear_char
			addi $s1, $s1, SHIFT_NEXT_ROW
			jal draw_char

			addi $s0, $s0, SHIFT_NEXT_ROW
			addi $t0, $s1, SHIFT_NEXT_ROW
			
		main_collision:
			# check if touches the medicine				
			bne $s1, $s2, main_draw
			li $s0, DISPLAY_LFTFST_ADDRESS
			li $s1, DISPLAY_LFTFST_ADDRESS
			addi $s0, $s0, -256
			addi $s1, $s1, -256
			addi $s5, $s5, -1
			#addi $s6, $s6, -3
			
		main_draw:
		# clear the char in s0
		# uodate new s1, draw new char in s1
		#addi $s0, $s1, 0
			jal clear_char
			jal draw_char
			addi $s0, $s1, 0
			#addi $t0, $s1, SHIFT_NEXT_ROW
			#li $t2, COLOUR_BLACK
			
		j main_loop
	
	continue:
		li $v0, 10 
		syscall 	
end_game:
	# clear last life
	li	$a0, DISPLAY_LIVES
	jal draw_heart_clear
	# draw dead
	jal	draw_dead
	# darken screen
	jal	draw_dark
	# end program
	li	$v0, 10								# $v0 = 10 terminate the program gracefully
	syscall
win_game:
	jal draw_win
	jal draw_dark
	li $v0, 10
	syscall 
	
draw_medicine:
	li $t3, COLOUR_WHITE
	li $t4, COLOUR_FOOD
	li $t2, DISPLAY_MIDLST_ADDRESS
	addi $t2, $t2, -3328
	sw $t3, ($t2)
	sw $t4, 4($t2)
	jr $ra
	
# draw dark
draw_dark:
	li	$a0, DISPLAY_FIRST_ADDRESS
	li	$a1, DISPLAY_LAST_ADDRESS

	draw_dark_loop:
		lw	$t7, 0($a0)
		addi	$t7, $t7, -COLOUR_DIM_SHIFT
		sw	$t7, 0($a0)
		addi	$a0, $a0, 4
		bgt	$a1, $a0, draw_dark_loop
	jr	$ra

draw_obstacle:
		
		addi $sp, $sp, -4
		sw $ra, ($sp)
		jal clear_screen
		li $t0, DISPLAY_LFTFST_ADDRESS
		li $t3, COLOUR_GREEN
		li $t4, DISPLAY_MIDLST_ADDRESS
		addi $t4, $t4, -SHIFT_NEXT_ROW
		li $t5, COLOUR_HEART
		sw $t5, 124($t4)
		addi $t4, $t4, -SHIFT_NEXT_ROW
		addi $t4, $t4, -SHIFT_NEXT_ROW
		addi $t4, $t4, -SHIFT_NEXT_ROW
		sw $t3, -20($t4)
		sw $t3, -24($t4)
		addi $t4, $t4, -SHIFT_NEXT_ROW
		addi $t4, $t4, -16
		sw $t3, 0($t4)
		sw $t3, 4($t4)
		sw $t3, 8($t4)
		sw $t3, 12($t4)
		sw $t3, 16($t4)
		sw $t3, 20($t4)
		sw $t3, 24($t4)
		sw $t3, 28($t4)
		addi $t4, $t4, -SHIFT_NEXT_ROW
		li $t5, COLOUR_FOOD
		sw $t5, 12($t4)
		sw $t3, 32($t4)
		sw $t3, 36($t4)
		addi $t4, $t4, -SHIFT_NEXT_ROW
		addi $t5, $t4, -SHIFT_NEXT_ROW
		addi $t5, $t5, -SHIFT_NEXT_ROW
		addi $t5, $t5, -SHIFT_NEXT_ROW
		addi $t5, $t5, -SHIFT_NEXT_ROW
		addi $t5, $t5, -SHIFT_NEXT_ROW
		#addi $t5, $t5, -SHIFT_NEXT_ROW
		#addi $t5, $t5, -SHIFT_NEXT_ROW
		sw $t3, ($t5)
		sw $t3, 4($t5)
		sw $t3, 8($t5)
		sw $t3, 12($t5)
		sw $t3, 16($t5)
		sw $t3, 20($t5)
		sw $t3, 24($t5)
		sw $t3, 28($t5)
		sw $t3, 32($t5)
		addi $t5, $t5, -SHIFT_NEXT_ROW
		addi $t5, $t5, -SHIFT_NEXT_ROW
		addi $t5, $t5, -SHIFT_NEXT_ROW
		addi $t5, $t5, -SHIFT_NEXT_ROW
		addi $t5, $t5, -SHIFT_NEXT_ROW
		addi $t5, $t5, -SHIFT_NEXT_ROW
		addi $t5, $t5, -SHIFT_NEXT_ROW
		addi $t5, $t5, -SHIFT_NEXT_ROW
		sw $t3, 20($t5)
		sw $t3, 24($t5)
		sw $t3, 28($t5)
		sw $t3, 32($t5)
		sw $t3, 36($t5)
		sw $t3, 40($t5)
		sw $t3, 44($t5)
		sw $t3, 48($t5)
		sw $t3, 52($t5)
		sw $t3, 56($t5)
		sw $t3, 60($t5)
		addi $t5, $t5, -SHIFT_NEXT_ROW
		li $t6, COLOUR_FOOD
		sw $t6, 36($t5)
		addi $t4, $t4, -32
		addi $t4, $t4, 72
		addi $s2, $t4, -SHIFT_NEXT_ROW
		sw $t3, ($t4)
		sw $t3, 4($t4)
		sw $t3, 8($t4)
		sw $t3, 12($t4)
		sw $t3, 16($t4)
		sw $t3, 20($t4)
		sw $t3, 24($t4)
		sw $t3, 28($t4)
		sw $t3, 32($t4)
		sw $t3, 36($t4)
		sw $t3, 40($t4)
		sw $t3, 44($t4)
		sw $t3, 48($t4)
		sw $t3, 52($t4)
		sw $t3, 56($t4)
		sw $t3, 60($t4)
		sw $t3, 64($t4)
		sw $t3, 68($t4)
		sw $t3, 72($t4)
		sw $t3, 76($t4)
		sw $t3, 80($t4)
		sw $t3, 84($t4)
		sw $t3, 88($t4)
		sw $t3, 92($t4)
		addi $t4, $t4, -SHIFT_NEXT_ROW
		addi $t4, $t4, -SHIFT_NEXT_ROW
		addi $t4, $t4, -SHIFT_NEXT_ROW
		addi $t4, $t4, -SHIFT_NEXT_ROW
		addi $t4, $t4, -SHIFT_NEXT_ROW
		addi $t4, $t4, -SHIFT_NEXT_ROW
		addi $t4, $t4, -SHIFT_NEXT_ROW
		sw $t3, 24($t4)
		sw $t3, 28($t4)
		sw $t3, 32($t4)
		sw $t3, 36($t4)
		sw $t3, 40($t4)
		sw $t3, 44($t4)
		sw $t3, 48($t4)
		sw $t3, 52($t4)
		sw $t3, 56($t4)
		sw $t3, 60($t4)
		sw $t3, 64($t4)
		sw $t3, 68($t4)
		sw $t3, 72($t4)
		sw $t3, 76($t4)
		sw $t3, 80($t4)
		sw $t3, 84($t4)
		sw $t3, 88($t4)
		sw $t3, 92($t4)
		addi $t4, $t4, -SHIFT_NEXT_ROW
		li $t5, COLOUR_FOOD
		sw $t5, 56($t4)
		lw $ra, ($sp)
		jr $ra
		
move_arrow:
	lw $t2, 4($t1)
	beq $t2, 0x77, keyw						# ASCII code of 'w' is 0x77
	beq $t2, 0x64, keyd						# ASCII code of 'd' is 0x64
	beq $t2, 0x73, keys
	
	keyw:
		li $t0, COLOUR_GREEN
		li $t1, 0x1000AA20
		lw $t2, ($t1)
		beq $t2, $t0, okle
		addi $sp, $sp, -4
		sw $ra, ($sp)
		jal draw_arrow_one
		jal clear_arrow_two
		lw $ra, ($sp)
		addi $sp, $sp, 4
		j okle
	keyd:
		li $t0, COLOUR_GREEN
		li $t2, 0x1000B320
		lw $t1, ($t2)
		beq $t1, COLOUR_GREEN, bu_wan_le
		
		li $t1, 0x1000AA20
		lw $t2, ($t1)
		bne $t2, $t0, okle
		sw $t0, 28($t1)
	keys:
		li $t0, COLOUR_GREEN
		li $t1, 0x1000B320
		lw $t2, ($t1)
		beq $t2, $t0, okle
		addi $sp, $sp, -4
		sw $ra, ($sp)
		jal draw_arrow_two
		jal clear_arrow_one
		lw $ra, ($sp)
		addi $sp, $sp, 4
		j okle
	okle: 
		jr $ra
	bu_wan_le:
		li $v0, 10
		syscall 
		
		
draw_arrow_one:
	li $t0, 0x1000AA20
	li $t1, COLOUR_GREEN
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)	
	sw $t1, 16($t0)	
	sw $t1, 20($t0)	
	sw $t1, 24($t0)	
	addi $t0, $t0, 256
	sw $t1, 16($t0)	
	sw $t1, 20($t0)	
	addi $t0, $t0, 256
	sw $t1, 16($t0)	
	addi $t0, $t0, -256
	addi $t0, $t0, -256
	addi $t0, $t0, -256
	sw $t1, 16($t0)	
	sw $t1, 20($t0)
	addi $t0, $t0, -256
	sw $t1, 16($t0)	
	jr $ra
	
clear_arrow_one:
	li $t0, 0x1000AA20
	li $t1, COLOUR_BACK
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)	
	sw $t1, 16($t0)	
	sw $t1, 20($t0)	
	sw $t1, 24($t0)	
	addi $t0, $t0, 256
	sw $t1, 16($t0)	
	sw $t1, 20($t0)	
	addi $t0, $t0, 256
	sw $t1, 16($t0)	
	addi $t0, $t0, -256
	addi $t0, $t0, -256
	addi $t0, $t0, -256
	sw $t1, 16($t0)	
	sw $t1, 20($t0)
	addi $t0, $t0, -256
	sw $t1, 16($t0)	
	jr $ra
	
	
draw_arrow_two:
	li $t0, 0x1000B320
	li $t1, COLOUR_GREEN
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)	
	sw $t1, 16($t0)	
	sw $t1, 20($t0)	
	sw $t1, 24($t0)	
	addi $t0, $t0, 256
	sw $t1, 16($t0)	
	sw $t1, 20($t0)	
	addi $t0, $t0, 256
	sw $t1, 16($t0)	
	addi $t0, $t0, -256
	addi $t0, $t0, -256
	addi $t0, $t0, -256
	sw $t1, 16($t0)	
	sw $t1, 20($t0)
	addi $t0, $t0, -256
	sw $t1, 16($t0)	
	jr $ra
	
clear_arrow_two:
	li $t0, 0x1000B320
	li $t1, COLOUR_BACK
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)	
	sw $t1, 16($t0)	
	sw $t1, 20($t0)	
	sw $t1, 24($t0)	
	addi $t0, $t0, 256
	sw $t1, 16($t0)	
	sw $t1, 20($t0)	
	addi $t0, $t0, 256
	sw $t1, 16($t0)	
	addi $t0, $t0, -256
	addi $t0, $t0, -256
	addi $t0, $t0, -256
	sw $t1, 16($t0)	
	sw $t1, 20($t0)
	addi $t0, $t0, -256
	sw $t1, 16($t0)	
	jr $ra
	
	
# ------------------------------------
draw_lives:
	b	draw_heart
	draw_lives_next:
	addi	$a1, $a1, -1
	addi	$a0, $a0, -SHIFT_NEXT_ROW
	addi	$a0, $a0, -SHIFT_NEXT_ROW
	addi	$a0, $a0, -SHIFT_NEXT_ROW
	addi	$a0, $a0, -24
	bgt	$a1, $zero, draw_lives
	# clear last heart
	b draw_heart_clear
	draw_lives_end:
	jr	$ra
# ------------------------------------
# draw heart
	# $a0: position
		# $t9: COLOUR_HEART
draw_heart:
	li	$t9, COLOUR_HEART
	
	sw	$t9, 0($a0)
	sw	$t9, 4($a0)
	sw	$t9, 12($a0)
	sw	$t9, 16($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$t9, 0($a0)
	sw	$t9, 4($a0)
	sw	$t9, 8($a0)
	sw	$t9, 12($a0)
	sw	$t9, 16($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$t9, 4($a0)
	sw	$t9, 8($a0)
	sw	$t9, 12($a0)	
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$t9, 8($a0)
	
	b	draw_lives_next
# ------------------------------------

# ------------------------------------
# draw heart clear
	# $a0: position
		# $t9: COLOUR_BLACK
draw_heart_clear:
	li	$t9, COLOUR_BLACK
	sw	$t9, 0($a0)
	sw	$t9, 4($a0)
	sw	$t9, 12($a0)
	sw	$t9, 16($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$t9, 0($a0)
	sw	$t9, 4($a0)
	sw	$t9, 8($a0)
	sw	$t9, 12($a0)
	sw	$t9, 16($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$t9, 4($a0)
	sw	$t9, 8($a0)
	sw	$t9, 12($a0)	
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$t9, 8($a0)
	
	b	draw_lives_end
# ------------------------------------

draw_char:	li $t0, COLOUR_RED
		sw $t0, ($s1)
		addi $t1, $s1, -SHIFT_NEXT_ROW
		sw $t0, ($t1)
		addi $t1, $t1, -SHIFT_NEXT_ROW
		sw $t0, ($t1)
		jr $ra		
		

keypress:
	lw $t2, 4($t8)
	li $t1, SHIFT_NEXT_ROW
	beq $t2, 0x61, key_a						# ASCII code of 'a' is 0x61 or 97 in decimal
	beq $t2, 0x77, key_w						# ASCII code of 'w' is 0x77
	beq $t2, 0x64, key_d						# ASCII code of 'd' is 0x64
	#beq $t2, 0x73, key_s						# ASCII code of 's' is 0x73
	beq $t2, 0x70, key_p						# ASCII code of 'p' is 0x70
	
	# t8 black, t7 red
	key_a:	div $s0, $t1
		mfhi $t8
		beq $t8, $zero, done
		addi $t0, $s0, -4
		lw $t1, ($t0)
		li $t2, COLOUR_GREEN
		beq $t1, $t2, done
		addi $t0, $t0, -SHIFT_NEXT_ROW
		lw $t1, ($t0)
		beq $t1, $t2, done
		addi $t0, $t0, -SHIFT_NEXT_ROW
		lw $t1, ($t0)
		beq $t1, $t2, done
		addi $s1, $s0, -4
		
		li $t3, COLOUR_FOOD
		lw $t4, ($s1)
		bne $t4, $t3, check_white
		addi $s6, $s6, 1
		
		check_white:
		# check if touches the white block
			li $t3, COLOUR_WHITE
		#lw $t4, ($s1)
			bne $t4, $t3, check_trap
			addi $s5, $s5, 1
			addi $s6, $s6, 3
			j a_done
		check_trap:
			li $t3, COLOUR_HEART
			bne $t4, $t3, a_done
			li $t3, COLOUR_GREEN
			li $t2, DISPLAY_MIDLST_ADDRESS
			addi $t2, $t2, -2048
			addi $t2, $t2, 44
			sw $t3, ($t2)
			sw $t3, -256($t2)
			sw $t3, -512($t2)
			sw $t3, -768($t2)
		
		a_done:
			j done
		
	key_w:	li $t0, DISPLAY_FIRST_ADDRESS	# t0 stores the largest adddress to jump
		addi $t0, $t0, SHIFT_NEXT_ROW
		addi $t0, $t0, SHIFT_NEXT_ROW
		addi $t0, $t0, SHIFT_NEXT_ROW
		addi $t0, $t0, SHIFT_NEXT_ROW
		blt $s0, $t0, done
		addi $s1, $s0, 0
		addu $t9, $s0, SHIFT_NEXT_ROW
		lw $t8, ($t9)
		li $t1, COLOUR_BLACK
		beq $t1, $t8, done
		addi $t0, $s0, -SHIFT_NEXT_ROW
		addi $t0, $t0, -SHIFT_NEXT_ROW
		addi $t0, $t0, -SHIFT_NEXT_ROW
		li $t2, COLOUR_RED
		lw $t3, ($t0)
		bne $t3, $t1, done		
		li $v0, 32
		li $a0, 100
		syscall 
		addi $s1, $s0, -SHIFT_NEXT_ROW
		sw $t1, ($s0)
		sw $t2, ($t0)
		addi $t0, $t0, -SHIFT_NEXT_ROW
		lw $t3, ($t0)
		bne $t3, $t1, done
		li $v0, 32
		li $a0, 100
		syscall
		addi $s0, $s0, -SHIFT_NEXT_ROW
		addi $s1, $s0, -SHIFT_NEXT_ROW
		sw $t1, ($s0)
		sw $t2, ($t0)
		addi $t0, $t0, -SHIFT_NEXT_ROW
		lw $t3, ($t0)
		bne $t3, $t1, done
		li $v0, 32
		li $a0, 60
		syscall
		addi $s0, $s0, -SHIFT_NEXT_ROW
		addi $s1, $s0, -SHIFT_NEXT_ROW
		sw $t1, ($s0)
		sw $t2, ($t0)
		addi $t0, $t0, -SHIFT_NEXT_ROW
		lw $t3, ($t0)
		bne $t3, $t1, done
		li $v0, 32
		li $a0, 20
		syscall
		addi $s0, $s0, -SHIFT_NEXT_ROW
		addi $s1, $s0, -SHIFT_NEXT_ROW
		sw $t1, ($s0)
		sw $t2, ($t0)
		addi $t0, $t0, -SHIFT_NEXT_ROW
		lw $t3, ($t0)
		bne $t3, $t1, done
		li $v0, 32
		li $a0, 10
		syscall
		addi $s0, $s0, -SHIFT_NEXT_ROW
		addi $s1, $s0, -SHIFT_NEXT_ROW
		sw $t1, ($s0)
		sw $t2, ($t0)
		addi $t0, $t0, -SHIFT_NEXT_ROW
		lw $t3, ($t0)
		bne $t3, $t1, done
		li $v0, 32
		li $a0, 100
		syscall
		addi $s0, $s0, -SHIFT_NEXT_ROW
		addi $s1, $s0, -SHIFT_NEXT_ROW
		sw $t1, ($s0)
		sw $t2, ($t0)
		addi $t0, $t0, -SHIFT_NEXT_ROW
		lw $t3, ($t0)
		bne $t3, $t1, done
		li $v0, 32
		li $a0, 100
		syscall
		addi $s0, $s0, -SHIFT_NEXT_ROW
		addi $s1, $s0, -SHIFT_NEXT_ROW
		sw $t1, ($s0)
		sw $t2, ($t0)
		j done
	
	key_d:	div $s0, $t1
		mfhi $t8
		addi $t3, $zero, 252
		beq $t8, $t3, done
		li $t2, COLOUR_GREEN
		addi $t0, $s0, 4
		lw $t1, ($t0)
		beq $t1, $t2, done
		addi $t0, $t0, -SHIFT_NEXT_ROW
		lw $t1, ($t0)
		beq $t1, $t2, done
		addi $t0, $t0, -SHIFT_NEXT_ROW
		lw $t1, ($t0)
		beq $t1, $t2, done
		addi $s1, $s0, 4
		
		li $t3, COLOUR_FOOD
		lw $t4, ($s1)
		bne $t4, $t3, check_white_d
		addi $s6, $s6, 1
		check_white_d:
		# check if touches the white block
			li $t3, COLOUR_WHITE
			lw $t4, ($s1)
			bne $t4, $t3, checktrap
			addi $s5, $s5, 1
			addi $s6, $s6, 3
			j d_done
		checktrap:
			li $t3, COLOUR_HEART
			bne $t4, $t3, d_done
			li $t3, COLOUR_GREEN
			li $t2, DISPLAY_MIDLST_ADDRESS
			addi $t2, $t2, -2048
			addi $t2, $t2, 44
			sw $t3, ($t2)
			sw $t3, -256($t2)
			sw $t3, -512($t2)
			sw $t3, -768($t2)
		
		d_done:
			j done
	
	key_s:	li $t0, DISPLAY_LAST_ADDRESS
		addi $t0, $t0, -SHIFT_NEXT_ROW
		addi $t0, $t0, -SHIFT_NEXT_ROW
		bgt $s0, $t0, done
		addi $s1, $s0, SHIFT_NEXT_ROW
		j done
	
	key_p:
		la $ra, main
		b done
	done:	
		jr $ra
		
# ------------------------------------
clear_char:	# clear at give s0
	li $t1, COLOUR_BLACK
	li $t0, COLOUR_RED
	clear_first:
		lw $t4, ($s0)
		bne $t0, $t4, clear_second
		sw $t1, ($s0)
	clear_second:
		addi $t3, $s0, -SHIFT_NEXT_ROW
		lw $t4, ($t3)
		bne $t4, $t0, clear_third
		sw $t1, ($t3)
	clear_third:
		addi $t3, $t3, -SHIFT_NEXT_ROW
		lw $t4, ($t3)
		bne $t0, $t4, clear_done
		sw $t1, ($t3)
	clear_done:
		jr $ra			
# ------------------------------------
shift_enemy:
	beq $s3, 0, move_right
	beq $s3, 1, move_left
	move_right:
		li $t2, COLOUR_BLACK
		sw $t2, ($s2)
		sw $t2, -256($s2)
		sw $t2, -512($s2)
		sw $t2, -768($s2)
		sw $t2, -1024($s2)
		sw $t2, -1280($s2)
		addi $s2, $s2, 4
		addi $t3, $s2, 284
		lw $t4, ($t3)
		bne $t4, COLOUR_BLACK, finish
		addi $s3, $s3, 1
		jr $ra
		
	move_left:
		li $t2, COLOUR_BLACK
		addi $t3, $s2, 16
		sw $t2, ($t3)
		sw $t2, -256($t3)
		sw $t2, -512($t3)
		sw $t2, -768($t3)
		sw $t2, -1024($t3)
		sw $t2, -1280($t3)
		addi $s2, $s2, -4
		lw $t4, -4($s2)
		beq $t4, COLOUR_GREEN, end_left
		addi $t3, $s2, 252
		lw $t4, ($t3)
		bne $t4, COLOUR_BLACK, finish
		addi $s3, $s3, -1
		jr $ra
	end_left:
		addi $s3, $s3, -1
		jr $ra
	finish:
		jr $ra
		
draw_enemy:
	li $t0, COLOUR_RED
	li $t1, COLOUR_YELLOW
	li $t2, COLOUR_BLACK
	sw $t1, ($s2)
	sw $t1, 4($s2)
	sw $t1, 8($s2)
	sw $t1, 12($s2)
	sw $t1, 16($s2)
	addi $t3, $s2, -SHIFT_NEXT_ROW
	sw $t1, ($t3)
	sw $t0, 4($t3)
	sw $t0, 8($t3)
	sw $t0, 12($t3)
	sw $t1, 16($t3)
	addi $t3, $t3, -SHIFT_NEXT_ROW
	sw $t1, ($t3)
	sw $t0, 4($t3)
	sw $t1, 8($t3)
	sw $t0, 12($t3)
	sw $t1, 16($t3)
	addi $t3, $t3, -SHIFT_NEXT_ROW
	sw $t1, ($t3)
	sw $t1, 4($t3)
	sw $t1, 8($t3)
	sw $t1, 12($t3)
	sw $t1, 16($t3)
	addi $t3, $t3, -SHIFT_NEXT_ROW
	sw $t1, ($t3)
	sw $t0, 4($t3)
	sw $t1, 8($t3)
	sw $t0, 12($t3)
	sw $t1, 16($t3)
	addi $t3, $t3, -SHIFT_NEXT_ROW
	sw $t1, ($t3)
	sw $t1, 4($t3)
	sw $t1, 8($t3)
	sw $t1, 12($t3)
	sw $t1, 16($t3)
	jr $ra

draw_menu:
	li $t0, COLOUR_BACK
	li $t1, COLOUR_RED
	li $t2, COLOUR_YELLOW
	li $t7, COLOUR_WHITE
	addi $t5, $a0, 0
	
	li $t3, 0
	li $t9, 0
	add_column:
		bge $t9, 64, draw_other_colour
		addi $t9, $t9, 1
		addi $t3, $t3, -64
	draw_first:
		bge $t3, 64, finish_row
		mul $t6, $t3, 4
		add $t4, $t5, $t6
		sw $t0, ($t4)
		addi $t3, $t3, 1
		j draw_first
	finish_row:
		addi $t5, $t5, 256
		j add_column
	
	draw_other_colour:
		li $t3, DISPLAY_FIRST_ADDRESS
		addi $t3, $t3, 256
		sw $t1, 76($t3)
              	sw $t1, 80($t3)
              	sw $t1, 84($t3)
              	sw $t1, 88($t3)
              	sw $t1, 92($t3)
              	sw $t1, 96($t3)
              	sw $t1, 100($t3)
              	sw $t1, 104($t3)
             	sw $t1, 108($t3)
             	sw $t1, 112($t3)
              	sw $t1, 116($t3)
            	sw $t1, 120($t3)
              	sw $t1, 124($t3)
              	sw $t1, 128($t3)
              	sw $t1, 132($t3)
              	sw $t1, 136($t3)
              	sw $t1, 140($t3)
              	sw $t1, 144($t3)
              	sw $t1, 148($t3)
              	sw $t1, 152($t3)
              	sw $t1, 156($t3)
		addi $t3, $t3, 256
		sw $t1, 76($t3)
		sw $t7, 80($t3)
                sw $t7, 84($t3)
                sw $t7, 88($t3)
                sw $t7, 92($t3)
                sw $t7, 96($t3)
                sw $t7, 100($t3)
                sw $t7, 104($t3)
                sw $t7, 108($t3)
                sw $t7, 112($t3)
                sw $t7, 116($t3)
                sw $t7, 120($t3)
                sw $t7, 124($t3)
                sw $t7, 128($t3)
                sw $t7, 132($t3)
                sw $t7, 136($t3)
                sw $t7, 140($t3)
                sw $t7, 144($t3)
                sw $t7, 148($t3)
                sw $t7, 152($t3)
		sw $t1, 156($t3)
		addi $t3, $t3, 256
		sw $t1, 76($t3)
		sw $t7, 80($t3)
		sw $t2, 84($t3)
                sw $t2, 88($t3)
                sw $t2, 92($t3)
                sw $t2, 96($t3)
                sw $t2, 100($t3)
		sw $t7, 104($t3)
                sw $t7, 108($t3)
                sw $t7, 112($t3)
                sw $t7, 116($t3)
                sw $t7, 120($t3)
                sw $t7, 124($t3)
                sw $t7, 128($t3)
		sw $t2, 132($t3)
                sw $t2, 136($t3)
                sw $t2, 140($t3)
                sw $t2, 144($t3)
                sw $t2, 148($t3)
		sw $t7, 152($t3)
		sw $t1, 156($t3)
		addi $t3, $t3, 256
		sw $t1, 76($t3)
		sw $t7, 80($t3)
		sw $t2, 84($t3)
                sw $t2, 88($t3)
                sw $t2, 92($t3)
                sw $t2, 96($t3)
                sw $t2, 100($t3)
		sw $t7, 104($t3)
                sw $t7, 108($t3)
                sw $t7, 112($t3)
                sw $t7, 116($t3)
                sw $t7, 120($t3)
                sw $t7, 124($t3)
                sw $t7, 128($t3)
		sw $t2, 132($t3)
                sw $t2, 136($t3)
                sw $t2, 140($t3)
                sw $t2, 144($t3)
                sw $t2, 148($t3)
		sw $t7, 152($t3)
		sw $t1, 156($t3)
		addi $t3, $t3, 256
		sw $t1, 76($t3)
		sw $t7, 80($t3)
		sw $t2, 84($t3)
                sw $t1, 88($t3)
                sw $t2, 92($t3)
                sw $t1, 96($t3)
                sw $t2, 100($t3)
		sw $t7, 104($t3)
                sw $t7, 108($t3)
                sw $t7, 112($t3)
                sw $t7, 116($t3)
                sw $t7, 120($t3)
                sw $t7, 124($t3)
                sw $t7, 128($t3)
		sw $t2, 132($t3)
                sw $t1, 136($t3)
                sw $t2, 140($t3)
                sw $t1, 144($t3)
                sw $t2, 148($t3)
		sw $t7, 152($t3)
		sw $t1, 156($t3)
		addi $t3, $t3, 256
		sw $t1, 76($t3)
		sw $t7, 80($t3)
		sw $t2, 84($t3)
                sw $t2, 88($t3)
                sw $t2, 92($t3)
                sw $t2, 96($t3)
                sw $t2, 100($t3)
		sw $t7, 104($t3)
                sw $t7, 108($t3)
                sw $t7, 112($t3)
                sw $t1, 116($t3)
                sw $t7, 120($t3)
                sw $t7, 124($t3)
                sw $t7, 128($t3)
		sw $t2, 132($t3)
                sw $t2, 136($t3)
                sw $t2, 140($t3)
                sw $t2, 144($t3)
                sw $t2, 148($t3)
		sw $t7, 152($t3)
		sw $t1, 156($t3)
		addi $t3, $t3, 256
		sw $t1, 76($t3)
		sw $t7, 80($t3)
		sw $t2, 84($t3)
                sw $t1, 88($t3)
                sw $t2, 92($t3)
                sw $t1, 96($t3)
                sw $t2, 100($t3)
		sw $t7, 104($t3)
                sw $t7, 108($t3)
                sw $t7, 112($t3)
                sw $t1, 116($t3)
                sw $t7, 120($t3)
                sw $t7, 124($t3)
                sw $t7, 128($t3)
		sw $t2, 132($t3)
                sw $t1, 136($t3)
                sw $t1, 140($t3)
                sw $t1, 144($t3)
                sw $t2, 148($t3)
		sw $t7, 152($t3)
		sw $t1, 156($t3)
		addi $t3, $t3, 256
		sw $t1, 76($t3)
		sw $t7, 80($t3)
		sw $t2, 84($t3)
                sw $t1, 88($t3)
                sw $t1, 92($t3)
                sw $t1, 96($t3)
                sw $t2, 100($t3)
		sw $t7, 104($t3)
                sw $t7, 108($t3)
                sw $t7, 112($t3)
                sw $t1, 116($t3)
                sw $t7, 120($t3)
                sw $t7, 124($t3)
                sw $t7, 128($t3)
		sw $t2, 132($t3)
                sw $t1, 136($t3)
                sw $t2, 140($t3)
                sw $t1, 144($t3)
                sw $t2, 148($t3)
		sw $t7, 152($t3)
		sw $t1, 156($t3)
		addi $t3, $t3, 256
		sw $t1, 76($t3)
		sw $t7, 80($t3)
		sw $t2, 84($t3)
                sw $t2, 88($t3)
                sw $t2, 92($t3)
                sw $t2, 96($t3)
                sw $t2, 100($t3)
		sw $t7, 104($t3)
                sw $t7, 108($t3)
                sw $t7, 112($t3)
                sw $t1, 116($t3)
                sw $t7, 120($t3)
                sw $t7, 124($t3)
                sw $t7, 128($t3)
		sw $t2, 132($t3)
                sw $t2, 136($t3)
                sw $t2, 140($t3)
                sw $t2, 144($t3)
                sw $t2, 148($t3)
		sw $t7, 152($t3)
		sw $t1, 156($t3)
		addi $t3, $t3, 256
		sw $t1, 76($t3)
		sw $t7, 80($t3)
                sw $t7, 84($t3)
                sw $t7, 88($t3)
                sw $t7, 92($t3)
                sw $t7, 96($t3)
                sw $t7, 100($t3)
                sw $t7, 104($t3)
                sw $t7, 108($t3)
                sw $t7, 112($t3)
                sw $t7, 116($t3)
                sw $t7, 120($t3)
                sw $t7, 124($t3)
                sw $t7, 128($t3)
                sw $t7, 132($t3)
                sw $t7, 136($t3)
                sw $t7, 140($t3)
                sw $t7, 144($t3)
                sw $t7, 148($t3)
                sw $t7, 152($t3)
		sw $t1, 156($t3)
		addi $t3, $t3, 256
		sw $t1, 76($t3)
		sw $t1, 80($t3)
                sw $t7, 84($t3)
                sw $t7, 88($t3)
                sw $t7, 92($t3)
                sw $t7, 96($t3)
                sw $t7, 100($t3)
                sw $t7, 104($t3)
                sw $t7, 108($t3)
                sw $t7, 112($t3)
                sw $t7, 116($t3)
                sw $t7, 120($t3)
                sw $t7, 124($t3)
                sw $t7, 128($t3)
                sw $t7, 132($t3)
                sw $t7, 136($t3)
                sw $t7, 140($t3)
                sw $t7, 144($t3)
                sw $t7, 148($t3)
                sw $t1, 152($t3)
		sw $t1, 156($t3)
		addi $t3, $t3, 256
		sw $t1, 80($t3)
                sw $t7, 84($t3)
                sw $t7, 88($t3)
                sw $t7, 92($t3)
                sw $t1, 96($t3)
                sw $t7, 100($t3)
                sw $t7, 104($t3)
                sw $t7, 108($t3)
                sw $t7, 112($t3)
                sw $t7, 116($t3)
                sw $t7, 120($t3)
                sw $t7, 124($t3)
                sw $t7, 128($t3)
                sw $t7, 132($t3)
                sw $t1, 136($t3)
                sw $t7, 140($t3)
                sw $t7, 144($t3)
                sw $t7, 148($t3)
                sw $t1, 152($t3)
		addi $t3, $t3, 256
		sw $t1, 80($t3)
                sw $t7, 84($t3)
                sw $t7, 88($t3)
                sw $t7, 92($t3)
                sw $t1, 96($t3)
                sw $t7, 100($t3)
                sw $t7, 104($t3)
                sw $t7, 108($t3)
                sw $t7, 112($t3)
                sw $t7, 116($t3)
                sw $t7, 120($t3)
                sw $t7, 124($t3)
                sw $t7, 128($t3)
                sw $t7, 132($t3)
                sw $t1, 136($t3)
                sw $t7, 140($t3)
                sw $t7, 144($t3)
                sw $t7, 148($t3)
                sw $t1, 152($t3)
		addi $t3, $t3, 256
		sw $t1, 80($t3)
                sw $t1, 84($t3)
                sw $t7, 88($t3)
                sw $t7, 92($t3)
                sw $t1, 96($t3)
                sw $t1, 100($t3)
                sw $t7, 104($t3)
                sw $t7, 108($t3)
                sw $t7, 112($t3)
                sw $t7, 116($t3)
                sw $t7, 120($t3)
                sw $t7, 124($t3)
                sw $t7, 128($t3)
                sw $t1, 132($t3)
                sw $t1, 136($t3)
                sw $t7, 140($t3)
                sw $t7, 144($t3)
                sw $t1, 148($t3)
                sw $t1, 152($t3)
		addi $t3, $t3, 256
                sw $t1, 84($t3)
                sw $t7, 88($t3)
                sw $t7, 92($t3)
                sw $t7, 96($t3)
                sw $t1, 100($t3)
                sw $t1, 104($t3)
                sw $t1, 108($t3)
                sw $t1, 112($t3)
                sw $t1, 116($t3)
                sw $t1, 120($t3)
                sw $t1, 124($t3)
                sw $t1, 128($t3)
                sw $t1, 132($t3)
                sw $t7, 136($t3)
                sw $t7, 140($t3)
                sw $t7, 144($t3)
                sw $t1, 148($t3)
		addi $t3, $t3, 256
                sw $t1, 84($t3)
                sw $t1, 88($t3)
                sw $t1, 92($t3)
                sw $t7, 96($t3)
                sw $t7, 100($t3)
                sw $t7, 104($t3)
                sw $t7, 108($t3)
                sw $t7, 112($t3)
                sw $t7, 116($t3)
                sw $t7, 120($t3)
                sw $t7, 124($t3)
                sw $t7, 128($t3)
                sw $t7, 132($t3)
                sw $t7, 136($t3)
                sw $t1, 140($t3)
                sw $t1, 144($t3)
                sw $t1, 148($t3)
		addi $t3, $t3, 256
		sw $t1, 92($t3)
                sw $t1, 96($t3)
                sw $t1, 100($t3)
                sw $t7, 104($t3)
                sw $t7, 108($t3)
                sw $t7, 112($t3)
                sw $t7, 116($t3)
                sw $t7, 120($t3)
                sw $t7, 124($t3)
                sw $t7, 128($t3)
                sw $t1, 132($t3)
                sw $t1, 136($t3)
                sw $t1, 140($t3)
                addi $t3, $t3, 256
                sw $t1, 40($t3)
                sw $t1, 44($t3)
                sw $t1, 100($t3)
                sw $t1, 104($t3)
                sw $t1, 108($t3)
                sw $t1, 112($t3)
                sw $t1, 116($t3)
                sw $t1, 120($t3)
                sw $t1, 124($t3)
                sw $t1, 128($t3)
                sw $t1, 132($t3)
		addi $t3, $t3, 256
		sw $t1, 36($t3)
		sw $t1, 48($t3)
		addi $t3, $t3, 256
		sw $t1, 36($t3)
		sw $t1, 52($t3)
		addi $t3, $t3, 256
		sw $t1, 36($t3)
		sw $t1, 52($t3)
		sw $t1, 100($t3)
		sw $t1, 112($t3)
		addi $t3, $t3, 256
		sw $t1, 36($t3)
		sw $t1, 48($t3)
		sw $t1, 68($t3)
		sw $t1, 72($t3)
		sw $t1, 100($t3)
		sw $t1, 112($t3)
		addi $t3, $t3, 256
		sw $t1, 36($t3)
		sw $t1, 40($t3)
		sw $t1, 44($t3)
		sw $t1, 64($t3)
		sw $t1, 76($t3)
		sw $t1, 100($t3)
		sw $t1, 112($t3)
		addi $t3, $t3, 256
		sw $t1, 36($t3)
		sw $t1, 48($t3)
		sw $t1, 60($t3)
		sw $t1, 80($t3)
		sw $t1, 100($t3)
		sw $t1, 112($t3)
		sw $t1, 124($t3)
		sw $t1, 128($t3)
		sw $t1, 144($t3)
		sw $t1, 148($t3)
		sw $t1, 152($t3)
		sw $t1, 168($t3)
		sw $t1, 172($t3)
		sw $t1, 176($t3)
		sw $t1, 192($t3)
		sw $t1, 212($t3)
		addi $t3, $t3, 256
		sw $t1, 36($t3)
		sw $t1, 52($t3)
		sw $t1, 60($t3)
		sw $t1, 64($t3)
		sw $t1, 68($t3)
		sw $t1, 72($t3)
		sw $t1, 76($t3)
		sw $t1, 80($t3)
		sw $t1, 100($t3)
		sw $t1, 104($t3)
		sw $t1, 108($t3)
		sw $t1, 112($t3)
		sw $t1, 120($t3)
		sw $t1, 132($t3)
		sw $t1, 144($t3)
		sw $t1, 156($t3)
		sw $t1, 168($t3)
		sw $t1, 180($t3)
		sw $t1, 212($t3)
		sw $t1, 192($t3)
		addi $t3, $t3, 256
		sw $t1, 36($t3)
		sw $t1, 52($t3)
		sw $t1, 36($t3)
		sw $t1, 60($t3)
		sw $t1, 100($t3)
		sw $t1, 112($t3)
		sw $t1, 120($t3)
		sw $t1, 132($t3)
		sw $t1, 144($t3)
		sw $t1, 156($t3)
		sw $t1, 168($t3)
		sw $t1, 180($t3)
		sw $t1, 212($t3)
		sw $t1, 192($t3)
		addi $t3, $t3, 256
		sw $t1, 36($t3)
		sw $t1, 48($t3)
		sw $t1, 64($t3)
		sw $t1, 76($t3)
		sw $t1, 100($t3)
		sw $t1, 112($t3)
		sw $t1, 120($t3)
		sw $t1, 132($t3)
		sw $t1, 144($t3)
		sw $t1, 148($t3)
		sw $t1, 152($t3)
		sw $t1, 168($t3)
		sw $t1, 172($t3)
		sw $t1, 176($t3)
		sw $t1, 208($t3)
		sw $t1, 196($t3)
		sw $t1, 212($t3)
		addi $t3, $t3, 256
		sw $t1, 40($t3)
		sw $t1, 44($t3)
		sw $t1, 68($t3)
		sw $t1, 72($t3)
		sw $t1, 100($t3)
		sw $t1, 112($t3)
		sw $t1, 124($t3)
		sw $t1, 128($t3)
		sw $t1, 144($t3)
		sw $t1, 168($t3)
		sw $t1, 204($t3)
		sw $t1, 200($t3)
		sw $t1, 212($t3)
		addi $t3, $t3, 256
		sw $t1, 144($t3)
		sw $t1, 168($t3)
		sw $t1, 212($t3)
		addi $t3, $t3, 256
		sw $t1, 144($t3)
		sw $t1, 168($t3)
		sw $t1, 212($t3)
		addi $t3, $t3, 256
		sw $t1, 144($t3)
		sw $t1, 168($t3)
		sw $t1, 208($t3)
		addi $t3, $t3, 256
		sw $t1, 144($t3)
		sw $t1, 168($t3)
		sw $t1, 200($t3)
		sw $t1, 204($t3)
		addi $t3, $t3, 256
		addi $t3, $t3, 256
		addi $t3, $t3, 256
		addi $t3, $t3, 256
		addi $t3, $t3, 256
		addi $t3, $t3, 256
		addi $t3, $t3, 256
		addi $t3, $t3, 256
		sw $t7, 80($t3)
		sw $t7, 84($t3)
		sw $t7, 96($t3)
		sw $t7, 100($t3)
		sw $t7, 104($t3)
		sw $t7, 116($t3)
		sw $t7, 120($t3)
		sw $t7, 132($t3)
		sw $t7, 136($t3)
		sw $t7, 140($t3)
		sw $t7, 156($t3)
		sw $t7, 160($t3)
		sw $t7, 164($t3)
		addi $t3, $t3, 256
		sw $t7, 76($t3)
		sw $t7, 100($t3)
		sw $t7, 112($t3)
		sw $t7, 124($t3)
		sw $t7, 132($t3)
		sw $t7, 144($t3)
		sw $t7, 160($t3)
		addi $t3, $t3, 256
		sw $t7, 80($t3)
		sw $t7, 84($t3)
		sw $t7, 100($t3)
		sw $t7, 112($t3)
		sw $t7, 116($t3)
		sw $t7, 120($t3)
		sw $t7, 124($t3)
		sw $t7, 132($t3)
		sw $t7, 136($t3)
		sw $t7, 140($t3)
		sw $t7, 160($t3)
		addi $t3, $t3, 256
		sw $t7, 88($t3)
		sw $t7, 100($t3)
		sw $t7, 112($t3)
		sw $t7, 124($t3)
		sw $t7, 132($t3)
		sw $t7, 144($t3)
		sw $t7, 160($t3)
		addi $t3, $t3, 256
		sw $t7, 80($t3)
		sw $t7, 84($t3)
		sw $t7, 100($t3)
		sw $t7, 112($t3)
		sw $t7, 124($t3)
		sw $t7, 132($t3)
		sw $t7, 148($t3)
		sw $t7, 160($t3)
		addi $t3, $t3, 256
		addi $t3, $t3, 256
		addi $t3, $t3, 256
		addi $t3, $t3, 256
		sw $t7, 96($t3)
		sw $t7, 100($t3)
		sw $t7, 104($t3)
		sw $t7, 112($t3)
		sw $t7, 120($t3)
		sw $t7, 128($t3)
		sw $t7, 136($t3)
		sw $t7, 140($t3)
		sw $t7, 144($t3)
		addi $t3, $t3, 256
		sw $t7, 96($t3)
		sw $t7, 112($t3)
		sw $t7, 120($t3)
		sw $t7, 128($t3)
		sw $t7, 140($t3)
		addi $t3, $t3, 256
		sw $t7, 96($t3)
		sw $t7, 100($t3)
		sw $t7, 104($t3)
		sw $t7, 116($t3)
		sw $t7, 128($t3)
		sw $t7, 140($t3)
		addi $t3, $t3, 256
		sw $t7, 96($t3)
		sw $t7, 112($t3)
		sw $t7, 120($t3)
		sw $t7, 128($t3)
		sw $t7, 140($t3)
		addi $t3, $t3, 256
		sw $t7, 96($t3)
		sw $t7, 100($t3)
		sw $t7, 104($t3)
		sw $t7, 112($t3)
		sw $t7, 120($t3)
		sw $t7, 128($t3)
		sw $t7, 140($t3)
		jr $ra

# draw DEAD
	# uses:
		# $a0: DISPLAY_DEAD
		# $a1: COLOUR_NUMBER
		# #t9: hold old $ra
draw_dead:
	li	$a1, COLOUR_NUMBER
	move 	$t9, $ra

	li	$a0, DISPLAY_DEAD
	jal	draw_D
	li	$a0, DISPLAY_DEAD
	addi	$a0, $a0, 20
	jal	draw_E
	li	$a0, DISPLAY_DEAD
	addi	$a0, $a0, 40
	jal	draw_A
	li	$a0, DISPLAY_DEAD
	addi	$a0, $a0, 60
	jal	draw_D
	
	jr	$t9
# ------------------------------------

# draw WIN
draw_win:
	li	$a1, COLOUR_NUMBER
	move 	$t9, $ra

	li	$a0, DISPLAY_DEAD
	jal	draw_W
	li	$a0, DISPLAY_DEAD
	addi	$a0, $a0, 32
	jal	draw_I
	li	$a0, DISPLAY_DEAD
	addi	$a0, $a0, 48
	jal	draw_N
	jr	$t9

clear_screen:
	li $t0, COLOUR_BLACK
	addi $t5, $a0, 0
	li $t3, 0
	li $t9, 0
	ad_column:
		bge $t9, 64, finish_clear
		addi $t9, $t9, 1
		addi $t3, $t3, -64
	dra_first:
		bge $t3, 64, finish_ro
		mul $t6, $t3, 4
		add $t4, $t5, $t6
		sw $t0, ($t4)
		addi $t3, $t3, 1
		j dra_first
	finish_ro:
		addi $t5, $t5, 256
		j ad_column
	finish_clear:
		jr $ra

# ------------------------------------
# draw number
	# $a0: position
	# $a1: COLOUR_NUMBER
	# $a2: number to draw
	# $a3: COLOUR_NIGHT
		# $t7: temp
		# $t8: tens place we are looking at
		# $t9: current digit to draw 
draw_number:
	li	$t8, 10
	div	$a2, $t8							# $a2 / $t8
	mflo	$a2								# $a2 = floor($a2 / $t8) 
	mfhi	$t9								# $t9 = $a2 mod $t8 

	# if both the division and the remainder are 0 than stop
	bne	$a2, $zero, draw_number_zero
	bne	$t9, $zero, draw_number_zero
	jr	$ra

	draw_number_zero: 
	li	$t7, 0
	bne	$t9, $t7, draw_number_one
	b	draw_zero
	draw_number_one: 
	li	$t7, 1
	bne	$t9, $t7, draw_number_two
	b	draw_one
	draw_number_two: 
	li	$t7, 2
	bne	$t9, $t7, draw_number_three
	b	draw_two
	draw_number_three: 
	li	$t7, 3
	bne	$t9, $t7, draw_number_four
	b	draw_three
	draw_number_four: 
	li	$t7, 4
	bne	$t9, $t7, draw_number_five
	b	draw_four
	draw_number_five: 
	li	$t7, 5
	bne	$t9, $t7, draw_number_six
	b	draw_five
	draw_number_six: 
	li	$t7, 6
	bne	$t9, $t7, draw_number_seven
	b	draw_six
	draw_number_seven: 
	li	$t7, 7
	bne	$t9, $t7, draw_number_eight
	b	draw_seven
	draw_number_eight: 
	li	$t7, 8
	bne	$t9, $t7, draw_number_nine
	b	draw_eight
	draw_number_nine: 
	li	$t7, 9
	bne	$t9, $t7, draw_number_next
	b	draw_nine

	draw_number_next:
	# shift draw number position
	addi	$a0, $a0, -SHIFT_NEXT_ROW
	addi	$a0, $a0, -SHIFT_NEXT_ROW
	addi	$a0, $a0, -SHIFT_NEXT_ROW
	addi	$a0, $a0, -SHIFT_NEXT_ROW
	addi	$a0, $a0, -16

	b draw_number

# ------------------------------------

# ------------------------------------
# draw_zero
	# $a0: position
	# $a1: COLOUR_NUMBER
	# $a3: COLOUR_NIGHT
draw_zero:
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)

	b	draw_number_next
# ------------------------------------

# ------------------------------------
# draw_one
	# $a0: position
	# $a1: COLOUR_NUMBER
	# $a3: COLOUR_NIGHT
draw_one:
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)

	b	draw_number_next
# ------------------------------------

# ------------------------------------
# draw_two
	# $a0: position
	# $a1: COLOUR_NUMBER
	# $a3: COLOUR_NIGHT
draw_two:
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a3, 4($a0)
	sw	$a3, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)

	b	draw_number_next
# ------------------------------------

# ------------------------------------
# draw_three
	# $a0: position
	# $a1: COLOUR_NUMBER
	# $a3: COLOUR_NIGHT
draw_three:
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)

	b	draw_number_next
# ------------------------------------

# ------------------------------------
# draw_four
	# $a0: position
	# $a1: COLOUR_NUMBER
	# $a3: COLOUR_NIGHT
draw_four:
	sw	$a1, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)

	b	draw_number_next
# ------------------------------------

# ------------------------------------
# draw_five
	# $a0: position
	# $a1: COLOUR_NUMBER
	# $a3: COLOUR_NIGHT
draw_five:
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a3, 4($a0)
	sw	$a3, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)

	b	draw_number_next
# ------------------------------------

# ------------------------------------
# draw_six
	# $a0: position
	# $a1: COLOUR_NUMBER
	# $a3: COLOUR_NIGHT
draw_six:
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a3, 4($a0)
	sw	$a3, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)

	b	draw_number_next
# ------------------------------------

# ------------------------------------
# draw_seven
	# $a0: position
	# $a1: COLOUR_NUMBER
	# $a3: COLOUR_NIGHT
draw_seven:
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)

	b	draw_number_next
# ------------------------------------

# ------------------------------------
# draw_eight
	# $a0: position
	# $a1: COLOUR_NUMBER
	# $a3: COLOUR_NIGHT
draw_eight:
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)

	b	draw_number_next
# ------------------------------------

# ------------------------------------
# draw_nine
	# $a0: position
	# $a1: COLOUR_NUMBER
	# $a3: COLOUR_NIGHT
draw_nine:
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a3, 0($a0)
	sw	$a3, 4($a0)
	sw	$a1, 8($a0)

	b	draw_number_next
# ------------------------------------
# draw A
	# $a0: position
	# $a1: colour
draw_A:
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 12($a0)
	
	jr	$ra
# ------------------------------------
# draw D
	# $a0: position
	# $a1: colour
draw_D:
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	
	jr	$ra
# ------------------------------------
# draw E
	# $a0: position
	# $a1: colour
draw_E:
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	sw	$a1, 12($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw	$a1, 0($a0)
	sw	$a1, 4($a0)
	sw	$a1, 8($a0)
	sw	$a1, 12($a0)
	jr	$ra
# ------------------------------------
draw_W:
	sw $a1, 0($a0)
	sw $a1, 24($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw $a1, 0($a0)
	sw $a1, 24($a0) 
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw $a1, 0($a0)
	sw $a1, 12($a0)
	sw $a1, 24($a0) 
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw $a1, 4($a0)
	sw $a1, 12($a0)
	sw $a1, 20($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw $a1, 8($a0)
	sw $a1, 16($a0)
	jr $ra
	
draw_I:
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw $a1, 4($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw $a1, 4($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw $a1, 4($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	jr $ra
	
draw_N:
	sw $a1, 0($a0)
	sw $a1, 16($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 16($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw $a1, 0($a0)
	sw $a1, 8($a0)
	sw $a1, 16($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw $a1, 0($a0)
	sw $a1, 12($a0)
	sw $a1, 16($a0)
	addi	$a0, $a0, SHIFT_NEXT_ROW
	sw $a1, 0($a0)
	sw $a1, 16($a0)
	jr $ra





