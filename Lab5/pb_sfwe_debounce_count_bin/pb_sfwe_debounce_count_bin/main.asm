;
; pb_sfwe_debounce_count_bin.asm
;
; Description: The program that keeps track of the number
;	of times a push button is pressed and displays the result
;	in binary to a bar graph LED. The program includes software
;	debouncing to minimize false activations.
;
; Author : Aditya Jindal 112835035
; Created: 10/1/2020 10:51:14 PM
;
; Register Assignments/Purpose
;	r16 = GP = general purpose, assign initial port conditions
;		= used as decrement counter in var dealy to specify 1-25 us
;	r17 = GP = assign initial LED outputs
;		= used as decrement counter in var delay
;	r18 = varaible push button count-up  value 
;
; Registers altered: r16, r17, r18
;
; Section no.: 4
; Experiment no.: 5
; Bench no.: 7

; Design Task 3
start:
    cbi VPORTE_DIR, 0		;Set input pin
	ldi r16, 0xFF		
	out VPORTD_DIR, r16	;set output port.

	ldi r17, 0xFF		;initiialize empty counter
	out VPORTD_OUT, r17	;output inital counter value to the LEDs
	com r17

main_loop:
	sbic VPORTE_IN, 0		;skips next instruction if push button is pressed
	rjmp main_loop			;while push button is not pushed causes loop

	rjmp var_delay			;jump in var delay for software debouncing

	rjmp rising_edge		;jump in to loop to detect when push button in released

	rjmp main_loop			;jump back to the main loop

rising_edge:
	sbis VPORTE_IN, 0		;skips next instruction if the push button is released
	rjmp rising_edge		;causes a loop while the push button is pressed


	rjmp main_loop

change_barled:				;loop to change the bar graph led
	sbic VPORTE_IN, 0		;loop back to the main loop if the push button is not longer pressed
	rjmp main_loop
	
	inc r18					;increment falling edge counter
	com r18
	out VPORTD_OUT, r18		;output the incremented result
	com r18

	rjmp rising_edge		;jump to the rising_edge loop

var_delay:
	ldi r16, 25				;load r16 with how many micro seconds you want to delay for 1-25
outer_loop:
	ldi r17, 110			;load r17 with a second delay variable
inner_loop:					;delay for the total decided time.
	dec r17
	brne inner_loop
	dec r16
	brne outer_loop

	rjmp change_barled