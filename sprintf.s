#################################################################################################################################
#	$s0	#	$s1	#	$s2	#	$s3	#	$s4	#	$s5	#	%s6	#	$s7	#
#      format	#	buffer	#	counter	#	min	#	max	#  +duplicate	#   duplicate	#	$ra	#
#################################################################################################################################
#	$t6	#	$t7	#
# +trap card	# +trap card	#
#################################		
MAINsprintf:
	#								 $t0     $t1	  $t2     $s7
	#				  $a0     $a1    $a2     $a3    16($sp) 20($sp) 24($sp) 28($sp) 
	#			sprintf(buffer, format,  str  , 255  ,  255  ,   250    , -255)   $ra
	#				 arg0    arg1   arg2    arg3    arg4     arg5     arg6 

	#Im going to duplicate everything in the array except buffer, $ra and format
	#$ra will be stored in $s7 for the rest of sprintf
	##########################################
	#|| arg6 || arg5 || arg4 || $a3 || $a2 ||#
	##########################################
	#20	16	12	8	4      0
	
	lw	$t0, 16($sp)
	lw	$t1, 20($sp)
	lw	$t2, 24($sp)	
	
	addi	$sp, $sp, -20
	sw	$a2, 0($sp)
	sw	$a3, 4($sp)
	sw	$t0, 8($sp)
	sw	$t1, 12($sp)
	sw	$t2, 16($sp)
	j	loop
	
	
DECIMALsprintf:
	#						  $t0      $t1	   $t2        $t3
	#	         $a0     $a1     $a2     $a3    16($sp)  20($sp)  24($sp)   28($sp) 
	#      sprintf(buffer, format,    1   ,   2   ,   3   ,    4    ,    5    ,   6   )
	#		arg0	arg1	arg2	arg3    arg4     arg5     arg6	   arg7 
	#$ra is already in $s7, $a1 = format = $s0, $a0 = buffer = $s1
	##################################################
	#|| arg7 || arg6 || arg5 || arg4 || $a3 || $a2 ||#
	##################################################
	#24	 20	 16	 12	 8	4      0
	
	lw	$t0, 16($sp)
	lw	$t1, 20($sp)
	lw	$t2, 24($sp)
	lw	$t3, 28($sp)
	
	addi	$sp, $sp, -24
	sw	$a2, 0($sp)
	sw	$a3, 4($sp)
	sw	$t0, 8($sp)
	sw	$t1, 12($sp)
	sw	$t2, 16($sp)
	sw	$t3, 20($sp)
	j	loop
	
STRINGsprintf:
	#						 
	#	         $a0     $a1     $a2     $a3    
	#      sprintf(buffer, format,  str1  ,  str2)
	#		arg0	arg1	arg2	arg3   
	#$ra is already in $s7, $a1 = format = $s0, $a0 = buffer = $s6
	##################
	#|| $a3 || $a2 ||#
	##################
	#8	4      0
	
	#no need to load, everything is already stored in $a2, $a3
	
	addi	$sp, $sp, -8
	sw	$a2, 0($sp)
	sw	$a3, 4($sp)
	j	loop
	
###################################################################################################################	
sprintf:
#IMPORTANT: There is a typo on line 61 of spf-decimal, instead of sw	$a3,16($sp) it should be sw $t0,16($sp)


	move	$s7, $ra	#save $ra which goes back to main code
	la	$s0, ($a1)	#put format in s0 so I can use a1 for something else
	addi	$s2, $0, 0	#this will be my counter
	li	$s3, 0		#this is my min
	li	$s4, 0		#this is my max
	la	$s1, ($a0)	#put buffer in s0 so I can use a0 for something else, I don't know what I'll use buffer for but just to be safe
	
	beq	$sp, 0x7fffefdc, MAINsprintf	#IMPORTANT: this only works in MARS. MARS simulator starts the stack pointer
	beq	$sp, 0x7fffefd8, DECIMALsprintf	#at 0x7fffeffc while other simulators start at 0x8000000. In other words,
	beq	$sp, 0x7fffefe8, STRINGsprintf	#this code will only work in MARS because of these three lines

loop:	
	lb	$a0, 0($s0)
	beq	$a0,'%', function
	beqz 	$a0, end
	sb	$a0, 0($s1)
	addi	$s1, $s1, 1
	addi	$s2, $s2, 1
	addi	$s0, $s0, 1
	j	loop
end:
	addi	$s1, $s1, 1
	li	$t0, '\n'
	sb	$t0, 0($s1)
	addi	$v0, $s2, 0
	addi	$ra, $s7, 0
	jr	$ra		#this sprintf implementation rocks!

############################################################################# first char
function:
	add	$s0, $s0, 1	#this is to shift one, because we already know the current iteration is is %
	lb	$a1, 0($s0)
	beq	$a1,'o', o
	beq	$a1,'x', x
	beq	$a1,'u', u
	beq	$a1,'s', s
	beq	$a1,'d', d	
	beq	$a1,'+', plus
	beq	$a1,'-', minus
	beq	$a1,'.', .
	j	num		#if none of the conditions apply and we don't need to catch errors, we assume it's a num

#################################################################################################################		
u:	#end of function
	add	$s0, $s0, 1	
	la	$t0,0($sp)
	lw	$a0, 0($t0)
	addi	$sp, $sp, 4
	jal	unsignedLoop 
	j	loop
 			
unsignedLoop:
	addi	$sp, $sp,-8
	sw	$ra, 4($sp)
	remu	$t0,$a0,10
	addi	$t0, $t0, '0'
	divu	$a0, $a0, 10
	beqz	$a0, unsignedDig
	sw	$t0, 0($sp)	
	jal	unsignedLoop		
	lw	$t0, 0($sp)
	
unsignedDig:	
	move	$a0, $t0
	sb	$a0, 0($s1)
	addi	$s1, $s1, 1
	addi	$s2, $s2, 1
	lw	$ra, 4($sp)
	addi	$sp, $sp, 8
	jr	$ra
		
##########################################################################################################	
x:	#end of function	hexa
	add	$s0, $s0, 1	#this is kinda dangerous because im manipulating the stack which holds 
	la	$t0,0($sp)	#sprintf(arg0...), MAKE SURE YOU DECREMENT THE RIGHT AMOUNT FROM THE STACK(you did)
	lw	$a0, 0($t0)
	addi	$sp, $sp, 4
	jal	hexLoop 
	j	loop
 		
		
hexLoop:
	addi	$sp, $sp,-8
	sw	$ra, 4($sp)
	remu	$t0,$a0,16
	addi	$t0, $t0, '0'
	divu	$a0, $a0, 16
	beqz	$a0, hexDig
	sw	$t0, 0($sp)	#this is flipped compared to putint, but it should work because lw is in the next loop instead of out
	jal	hexLoop		#screw it I switched it back, thats what I get for trying to be fancy
	lw	$t0, 0($sp)
	
hexDig:	
	move	$a0, $t0
	bgt	$a0, '9', hexDigSpecial
	sb	$a0, 0($s1)
	addi	$s1, $s1, 1
	addi	$s2, $s2, 1
	lw	$ra, 4($sp)
	addi	$sp, $sp, 8
	jr	$ra
	
	
hexDigSpecial:
	
	beq	$a0, 58, A	#techniquely this char is not '10' in ascii but, it is what the system reads 10 as
	beq	$a0, 59, B
	beq	$a0, 60, C
	beq	$a0, 61, D
	beq	$a0, 62, E
	beq	$a0, 63, F
A:
	addi	$a0, $0, 'a'
	sb	$a0, 0($s1)
	addi	$s1, $s1, 1
	addi	$s2, $s2, 1
	lw	$ra, 4($sp)
	addi	$sp, $sp, 8
	jr	$ra	
B:
	addi	$a0, $0, 'b'
	sb	$a0, 0($s1)
	addi	$s1, $s1, 1
	addi	$s2, $s2, 1
	lw	$ra, 4($sp)
	addi	$sp, $sp, 8
	jr	$ra	
	
C:
	addi	$a0, $0, 'c'
	sb	$a0, 0($s1)
	addi	$s1, $s1, 1
	addi	$s2, $s2, 1
	lw	$ra, 4($sp)
	addi	$sp, $sp, 8
	jr	$ra	
	
D:
	addi	$a0, $0, 'd'
	sb	$a0, 0($s1)
	addi	$s1, $s1, 1
	addi	$s2, $s2, 1
	lw	$ra, 4($sp)
	addi	$sp, $sp, 8
	jr	$ra	

E:
	addi	$a0, $0, 'e'
	sb	$a0, 0($s1)
	addi	$s1, $s1, 1
	addi	$s2, $s2, 1
	lw	$ra, 4($sp)
	addi	$sp, $sp, 8
	jr	$ra	

F:

	addi	$a0, $0, 'f'
	sb	$a0, 0($s1)
	addi	$s1, $s1, 1
	addi	$s2, $s2, 1
	lw	$ra, 4($sp)
	addi	$sp, $sp, 8
	jr	$ra	
	
##########################################################################################################

o:	#end of function	octa

	add	$s0, $s0, 1	#should be the same as hexa except with 8 and no special characters
	la	$t0,0($sp)
	lw	$a0, 0($t0)
	addi	$sp, $sp, 4
	jal	octaLoop 
	j	loop
 			
octaLoop:
	addi	$sp, $sp,-8
	sw	$ra, 4($sp)
	remu	$t0,$a0,8
	addi	$t0, $t0, '0'
	divu	$a0, $a0, 8
	beqz	$a0, octaDig
	sw	$t0, 0($sp)	
	jal	octaLoop		
	lw	$t0, 0($sp)
	
octaDig:	
	move	$a0, $t0
	sb	$a0, 0($s1)
	addi	$s1, $s1, 1
	addi	$s2, $s2, 1
	lw	$ra, 4($sp)
	addi	$sp, $sp, 8
	jr	$ra
	

#################################################################################################################
s:	
	add	$s0, $s0, 1
	lw	$t0,0($sp)	#s3<------thirty-nine LOAD WORD NOT ADDRESS	
	addi	$sp,$sp, 4	#decrement for next value
sLoop:	lb	$a0, 0($t0)
	beqz	$a0, loop
	sb	$a0, 0($s1)
	addi	$s1, $s1, 1
	addi	$s2, $s2, 1
	addi	$t0, $t0, 1
	j	sLoop

	
#################################################################################################################
d:	#end of function
	li	$s3, 0
	li	$s4, 2000
	j	GoldilockD

	
#################################################################################################################
plus:		#1
	add	$s0, $s0, 1	#+---->next
	li	$t6, 0
	la	$t0,0($s0)
	lb	$a1, 0($t0)
	addi	$a1, $a1, -48 
	# do not decrement, we need this value again
	bge	$a1, 0, addsign
	j	plusSendoff
	
addsign:
	
	li 	$t6, 1	#trap card to catch '+'

plusSendoff:
	la	$t0,0($s0)
	lb	$a0, 0($t0)
	beq	$a0, 'd', d
	beq	$a0, '.', .
	j	num
		



#################################################################################################################
minus:		#1
	addi	$s0, $s0, 1 
	li 	$t7, 1	#trap card to catch '-'

minusSendoff:
	la	$t0,0($s0)
	lb	$a0, 0($t0)
	beq	$a0, 'd', d
	beq	$a0, '.', .
	j	num
		


#################################################################################################################
.:	#1
	li	$s3, 0		#resets	MIN(if you're only required a max that means there is no min, min = 0)
	li	$s4, 0		#resets	MAX
	add	$s0, $s0, 1
	lb	$a0, 0($s0)	#if .num the next variable will always be a # a0 <----'5'
	j	.num
	

.num:	#2
	addi	$s4, $a0, -48	#(s4 is designated as max)
	add	$s0, $s0, 1	#shift one
	lb	$a0, 0($s0)	#load new char into a0
	beq	$a0,'s',GoldilockS
	beq	$a0, 'd',GoldilockD

#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||#
#.numS:	#3	End of Function
	#addi	$s3, $0, 0	#if you're only required a max that means there is no min
#	j	GoldilockS


#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||#
#.numD:	#3	End of Function


#################################################################################################################
num:	#1	
	li	$s3, 0		#resets	MIN
	li	$s4, 0		#resets	MAX
	la	$t0,0($s0)
	lb	$a0, 0($t0)
	addi	$s3, $a0, -48	#(s3 is designated as min)
	add	$s0, $s0, 1	#shift one
	lb	$a0, 0($s0)	#load new char into a0
	beq	$a0,'.',num.	#BE CAREFUL, now we are dealing with both chars from the format and from your own work
	beq	$a0,'s',numS
	beq	$a0,'d',numD
	j	numD
	

#_______________________________________________________________________________________________________________#
num.:	#2
	addi	$s0, $s0, 1	#shift one
	lb	$a0, 0($s0)	#if num. the next variable will always be a # a0 <----'5'
	j	num.num

num.num:#3
	addi	$s4, $a0, -48	#(s4 is designated as max)
	add	$s0, $s0, 1	#shift one
	lb	$a0, 0($s0)	#load new char into a0
	beq	$a0,'s',GoldilockS
	beq	$a0,'d',GoldilockD

#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||#
GoldilockS:#4	End of Function num.numS(min($s3),max($s4), value ($a1))
	addi	$s0, $s0, 1	#we shift now so we don't need to worry about it later (format)
	li	$t1, 0		#t1 will be my char counter ("Kevin"  t1=5)
	lw	$t5, 0($sp)	#load "abcdefghi"
	beq	$s4, 0, DExit	#this catches if $s4 is zero, if not we are in a world of hurt
	j	Scounter
	#addi	$sp, $sp,4      We dont want to do this yet because we need to retrieve it again
	#step 1, have a counter
Scounter:

	lb	$a0, 0($t5)
	beqz	$a0, Schecker
	addi	$t1, $t1, 1	#char counter
	addi	$t5, $t5, 1
	j	Scounter
	#step 2, check if char counter < min
Schecker:
	lw	$t5, 0($sp)	#resets the value of t5 to "abcdefghi"
	sub	$t3, $s3, $t1	#t3 =(min-char counter) this is only for filler, useless otherwise
	blt	$t1, $s3, STooCold	#if t1 (char counter) < s3 (min)
	#bgt	$t1, $s4, STooHot
	j	SMiddle
	#step 3, fill spaces (min-char counter)
STooCold:	#This function adds filler until it reaches enough values to satisfy min
	beqz	$t3, SMiddle	#assumption that if it didn't even reach min, then you would never reach max
	li	$a0, ' '
	sb	$a0, 0($s1)
	addi	$s1, $s1, 1
	addi	$s2, $s2, 1
	addi	$t3, $t3, -1	#t3 is filler = min-char
	j	STooCold

SMiddle:
	lb	$a0, 0($t5)	#reload again because a0 was manipulated, t5 is already resetted to point at 1st value
	beqz	$a0, SExit	#exit to loop
	sb	$a0, 0($s1)
	addi	$s1, $s1, 1
	addi	$s2, $s2, 1
	addi	$t5, $t5, 1
	addi	$s4, $s4, -1
	beqz	$s4, SExit	#if max counter goes to zero, max value exceeded
	j	SMiddle

SExit:
	addi	$sp, $sp,4 	#this is because we didn't delete this earlier
	j	loop

#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||#
GoldilockD:#4	End of Function decimal(min($s3),max($s4), value ($a1))
	addi	$s0, $s0, 1	#we shift now so we don't need to worry about it later (format)
	li	$t1, 0		#t1 will be my num counter ("10020"  t1=5)
	li	$t3, 0		#this caused me so many problems
	la	$t0, 0($sp)	#load "10020" as an int
	lw	$a0, 0($t0)
	addi	$sp, $sp,4 	#unlike char, we are going to delete this now because we will be using the stack quite extensively
	blt	$s4, 0, DExit	#this catches if $s4 is zero or less then because of '+', if not we are in a world of hurt
	addi	$s6, $a0, 0	#a0 duplicate, it will be saved in s6
	jal	GoldilockPlusChecker
	blt	$a0, 0, GoldilockMinustoPlus
	move	$s5, $a0	#$s5 = positive duplicate
	j	Dcounter
	
GoldilockPlusChecker:
	beq	$t6, 1,	addPlus
	jr	$ra
	
addPlus:
	add	$a1, $a0, 0
	li 	$a0, '+'
	sb	$a0, 0($s1)
	addi	$s1, $s1, 1
	add	$s2, $s2, 1
	addi 	$s4, $s4, -1
	add	$a0, $a1, 0
	li	$t6, 0	#reset trap card
	jr	$ra
	
GoldilockMinustoPlus:
	addi	$t2, $a0, 0
	li	$t4, -1
	mult	$t2, $t4
	mflo	$s5
	move	$a0, $s5
	blt 	$s6, 0, GoldilockNegative
	j	Dcounter
	
GoldilockNegative:
	li 	$a0, '-'
	sb	$a0, 0($s1)
	addi	$s1, $s1, 1
	add	$s2, $s2, 1
	addi 	$s4, $s4 , -1	#Because '-' counts as a char we need to subract 1 ( also the reason we can be in a world of hurt)
	move	$a0, $s5
	j Dcounter
	
Dcounter:
	addi	$t1, $t1, 1	#deci counter
	divu	$a0, $a0, 10
	beqz	$a0, Dchecker
	j	Dcounter
	#step 2, check if char counter < min
Dchecker:
	move	$a0, $s5	#everything we replace we are going to replace with a positive version of that number
	sub	$t3, $s3, $t1	#t3 =(min-num counter) this is only for filler, useless otherwise
	blt	$t1, $s3, DTooCold	#if t1 (num counter) < s3 (min)
	#bgt	$t1, $s4, DTooHot	#if t1 (num counter) > s4 (max)
	j	DMiddle


	#step 3, fill spaces (min-char counter)
DTooCold:	#This function adds filler until it reaches enough values to satisfy min
	beq	$t7, 1, DMiddle	#completely skips DTooCold step
	beqz	$t3, DMiddle	#assumption that if it didn't even reach min, then you would never reach max
	li	$a0, '0'
	sb	$a0, 0($s1)
	addi	$s1, $s1, 1
	addi	$s2, $s2, 1
	addi	$t3, $t3, -1	#t3 is filler = min-char
	j	DTooCold



DMiddle:

	
GoldilockPositive:	
	#lw	$t5, 0($sp)	#reset just to make sure
	#lb	$a0, 0($t5)	#for char we would need to convert to byte but we can just load word for int
	move	$a0, $s5	#everything we replace we are going to replace with a positive version of num
	jal	GoldilockLoop 
	j	DExit

GoldilockLoop:
	addi	$sp, $sp,-8
	sw	$ra, 4($sp)
	remu	$t0,$a0,10
	addi	$t0, $t0, '0'
	divu	$a0, $a0, 10
	addi	$s4, $s4, -1
	beqz	$s4, GoldilockDig	#if max counter goes to zero, the prgram will be forced to recur
	beqz	$a0, GoldilockDig
	sw	$t0, 0($sp)
	jal	GoldilockLoop		
	lw	$t0, 0($sp)
	
GoldilockDig:	
	move	$a0, $t0
	sb	$a0, 0($s1)
	addi	$s1, $s1, 1
	addi	$s2, $s2, 1
	lw	$ra, 4($sp)
	addi	$sp, $sp, 8
	jr	$ra

implementMinus:
	beq	$t7, 1, reverseSpace
	jr	$ra

reverseSpace:
	beqz	$t3, minusEnd	
	li	$a0, ' '
	sb	$a0, 0($s1)
	addi	$s1, $s1, 1
	addi	$s2, $s2, 1
	addi	$t3, $t3, -1	#t3 is filler = min-char
	j	reverseSpace
	
minusEnd:
	li 	$t7, 0	#reset trapcard
	jr	$ra
DExit:	
	jal	implementMinus
	li	$s3, 0
	li	$s4, 0
	li	$t3, 0
	li	$t1, 0
	li	$t4, 0
	j	loop

#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||#
#_______________________________________________________________________________________________________________#
numS:	#2	End of Function
	addi	$s4, $0, 2000	#If number only have a min requirement, then the max will have to be 2000, because the 
				#string will never exceed the buffer it is given
	j	GoldilockS

#_______________________________________________________________________________________________________________#
numD:	#2	End of Function
	addi	$s4, $0, 2000#If number only have a min requirement, then the max will have to be 2000, because the 
			     #string will never exceed the buffer it is given	
			     #no need to shift, code already does it	   
	j	GoldilockD


#################################
#Test cases:
#	Works for main
#	Works for string assuming the given number is between 0-9 ex %0.3s %5.9s
#	Works for everything (knock on wood)
#
#