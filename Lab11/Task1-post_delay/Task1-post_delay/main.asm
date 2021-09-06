;**************************************************
;*
;* Title: bdc_to_hex_mux_intr
;* Author: Aditya Jindal
;* Version:	1.0
;* Last updated: 11082020
;* Target: ATmega4809
;*
;* DESCRIPTION: User enters digits conditionally which
;* are then output to LED display, if the first
;* button is pressed. If the second push button is 
;* pressed then the the numbers in bcd_entried are
;* taken in a a 4-digit value and displayed in HEX 
;* this program uses interupts instead of polling
;* also uses clocks instead of delay subroutine
;* 
;* 
;*
;*
;* VERSION HISTORY
;* 1.0 Original version
;******************************************************

.nolist
.include "m4809def.inc"
.list

.equ PERIOD_EXAMPLE_VALUE = 64

;* Define varaibles
.dseg
bcd_entries: .byte 4
led_display: .byte 4
digit_num: .byte 1

;Task 1
.cseg			;start of code segment
reset:
 	jmp start	;reset vector executed a power on

.org TCA0_OVF_vect
	jmp toggle_pin_ISR

start:
	ldi r16, 0xFF ;make r16 all 1s
	out VPORTD_DIR, r16; make portD to output

	ldi r16, 0xF0
	out VPORTC_DIR, r16 ;top pins of portC to output

	;Initialize vairables and arrays	
	ldi r16, 0x00;
	sts digit_num, r16 ;Initialize digit_num variable

	ldi YH, HIGH(bcd_entries)	;set pointer to end of array
	ldi YL, LOW(bcd_entries)	;set pointer to start of array
	
	std Y+0 ,r16		;initialize bcd_entried
	std Y+1 ,r16
	std Y+2 ,r16
	std Y+3 ,r16

	ldi r16, 0xFF
	ldi XH, HIGH(led_display);set pointer to end of array
	ldi XL, LOW(led_display);set pointer to start of array

	st X+ ,r16 ;initalize LED display array
	st X+ ,r16 ;initalize LED display array
	st X+ ,r16 ;initalize LED display array
	st X+ ,r16 ;initalize LED display array

	;configure TCA0
	ldi r16, TCA_SINGLE_WGMODE_NORMAL_gc	;WGMODE normal
	sts TCA0_SINGLE_CTRLB, r16

	ldi r16, TCA_SINGLE_OVF_bm		;enable overflow interrupt
	sts TCA0_SINGLE_INTCTRL, r16

	;load period low byte then high byte
	ldi r16, LOW(PERIOD_EXAMPLE_VALUE)	;set the period
	sts TCA0_SINGLE_PER, r16
	ldi r16, HIGH(PERIOD_EXAMPLE_VALUE)	;set the period
	sts TCA0_SINGLE_PER + 1, r16

	;set clock and start timer
	ldi r16, TCA_SINGLE_CLKSEL_DIV256_gc | TCA_SINGLE_ENABLE_bm
	sts TCA0_SINGLE_CTRLA, r16

	sei		;enable global interrupts

	rcall post_display

main_loop:	
	rjmp main_loop ;loop back

toggle_pin_ISR:
	push r16
	in r16, CPU_SREG
	push r16
	push r17
	push r18
	push r19
	push r20
	push YH			;save YH pointer
	push YL			;save YL pointer

	rcall multiplex_display

	ldi r16, TCA_SINGLE_OVF_bm	;clear OVF flag
	sts TCA0_SINGLE_INTFLAGS, r16

	pop YL
	pop YH
	pop r20
	pop r19
	pop r18
	pop r17
	pop r16
	out CPU_SREG, r16
	pop r16

	reti

;**************************************************
;* 
;* "post_display"
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
;* High registers modified: r16, XH, XL
;*
;* Parameters: none
;* Returns: none
;*
;* Notes: 
;*
;***********************************************

post_display:
	;Turn on all segements
	ldi r16, 0x00
	ldi XH, HIGH(led_display);set pointer to end of array
	ldi XL, LOW(led_display);set pointer to start of array

	st X+ ,r16 ;initalize LED display array
	st X+ ,r16 ;initalize LED display array
	st X+ ,r16 ;initalize LED display array
	st X+ ,r16 ;initalize LED display array
	
	ldi r18, 39
	rcall one_sec_delay	;one second delay

	;Turn all segments off
	ldi r16, 0xFF
	ldi XH, HIGH(led_display);set pointer to end of array
	ldi XL, LOW(led_display);set pointer to start of array

	st X+ ,r16 ;initalize LED display array
	st X+ ,r16 ;initalize LED display array
	st X+ ,r16 ;initalize LED display array
	st X+ ,r16 ;initalize LED display array

	ret

;*******************************************
;* 
;* "var_delay"
;*
;* Description: 25ms program software delay 
;*
;* Author: Aditya Jindal
;* Version: 1.0
;* Last updated: 10-29-2020
;* Target: ATmega4809
;* Number of words: 27
;* Number of cycles: 282
;* Low registers modified:
;* High registers modified: r16,r17
;*
;* Parameters: none
;* Returns: none
;*
;* Notes: 
;*
;*****************************************

var_delay:
	ldi r16, 255		;load r16 with 1-25ms
outer_loop:
	ldi r17, 110		;load r17 with a second delay variable
inner_loop:				;delay for the total decided time.
	dec r17
	brne inner_loop
	dec r16
	brne outer_loop

	ret

;*******************************************
;* 
;* "one_sec_delay"
;*
;* Description: Program to repeatedly call
;*	var_delay for bigger delays 
;*
;* Author: Aditya Jindal
;* Version: 1.0
;* Last updated: 10-29-2020
;* Target: ATmega4809
;* Number of words: 27
;* Number of cycles: 282
;* Low registers modified: none
;* High registers modified: r18
;*
;* Parameters: r18
;* Returns: none
;*
;* Notes: 
;*
;*****************************************

one_sec_delay:
	rcall var_delay
	dec r18
	cpi r18, 0x00
	brne one_sec_delay	;keep looping till r18 zero
	ret

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