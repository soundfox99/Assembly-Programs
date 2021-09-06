;*************************************************
;*
;* Title: multiplex_display
;* Author:	Aditya Jindal
;* Version: 1.0
;* Last updated: 10-29-2020
;* Target: ATmega4809
;*
;* DESCRIPTION: outputs the segment values for the 
;*	next multiplexed digit to be displayed and turns
;*	ON that digit
;* 
;* 
;*
;*
;* VERSION HISTORY
;* 1.0 Original version
;***************************************************

.nolist
.include "m4809def.inc"
.list

;* Define varaibles
.dseg
led_display: .byte 4
digit_num: .byte 1
.cseg

;Task 2
start:
	ldi r16, 0xFF ;make r16 all 1s
	out VPORTD_DIR, r16; make portD to output
	ldi r16, 0xF0
	out VPORTC_DIR, r16 ;top pins of portC to output

	ldi r16, 0x00;
	sts digit_num, r16 ;Initialize digit_num variable 

main_loop:
	rcall multiplex_display

	rjmp main_loop

;**************************************************
;* 
;* "multiplex_display"
;*
;* Description: outputs the segment values for the 
;*	next multiplexed digit to be displayed and turns
;*	ON that digit
;*
;* Author: Aditya Jindal
;* Version: 1.0
;* Last updated: 10-29-2020
;* Target: ATmega4809
;* Number of words: 32
;* Number of cycles: 36
;* Low registers modified: none
;* High registers modified: r16, r17, r18, r20, YH, YL
;*
;* Parameters: none
;* Returns: none
;*
;* Notes: 
;*
;***********************************************

multiplex_display:
	lds r16, digit_num ;load digit num into r16
	andi r16, 0x03	;mask it to get lsb
	mov r17,r16	;make a copy of r16
	
	sts digit_num, r17	;load r17 into variable

	ldi YL, LOW(led_display)	;set pointer
	ldi YH, HIGH(led_display)
	
	inc r16	;increment register
output_loop:
	dec r16	;decremnt register
	ld r18,Y+	;store incremented pointer value
	brne output_loop

	
	cpi r17,0 ;demux r17 to choose correct anode
	breq pos_zero	;branch to the right position
	cpi r17,1	
	breq pos_one
	cpi r17,2	
	breq pos_two
	cpi r17,3	
	breq pos_three

pos_zero:
	ldi r20, 0xEF	;set r20 to the PC value
	rjmp position	;branch to position
pos_one:
	ldi r20,0xDF
	rjmp position

pos_two:
	ldi r20,0xBF
	rjmp position

pos_three:
	ldi r20, 0x7F
	rjmp position

position:
	ldi r19, 0xFF
	out VPORTC_OUT, r19	;turn off digit to modigy
	out VPORTD_OUT, r18	;output the right segment value
	out VPORTC_OUT, r20 ;power common anode
	inc r17	;increment register
	sts digit_num, r17 ;store register in variable
	ret