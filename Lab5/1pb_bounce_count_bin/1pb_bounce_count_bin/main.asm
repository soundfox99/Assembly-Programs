;
; pb_bounce_count_bin.asm
;
; Deescription: The program that keeps track of the number
;	of times a push button is pressed and displays the result
;	in binary to a bar graph LED.
;
; Author : Aditya Jindal 112835035
; Created: 10/1/2020 9:07:05 PM
;
; Inputs:
;	PORTE PIN0 = Push button input
;
; Outputs:
;	PortD = Bargraph LED output port.
;
; Refister Assignments/Purpose
;	r16 = GP = general purpose, assign initial port conditions
;	r17 = varaible push button count-up  value
;
; Registers altered: r16, r17
;
; Section no.: 4
; Experiment no.: 5
; Bench no.: 7

; Design Task 1
start:
    cbi VPORTE_DIR, 0		;Set input pin.
	ldi r16, 0xFF		
	out VPORTD_DIR, r16		;set output port.

	ldi r17, 0xFF			;initiialize empty counter
	out VPORTD_OUT, r17		;output inital counter value to the LEDs
	com r17

main_loop:
	sbic VPORTE_IN, 0		;skips next instruction if push button is pressed
	rjmp main_loop			;while push button is not pushed causes loop

	inc r17					;increment falling edge counter
	com r17					
	out VPORTD_OUT, r17		;output the incremented result
	com r17
	
	rjmp rising_edge		


rising_edge:
	sbis VPORTE_IN, 0		;skips next instruction if the push button is released
	rjmp rising_edge		;causes a loop while the push button is pressed
	
	rjmp main_loop			;loop back to main loop