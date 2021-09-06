;
; conditional_input_sftwe.asm
;
; Description: The program displays the result of a switch bank
;	to a bargraph LED, but the updated value is only displayed
;	when the push button is pressed.
;
; Author : Aditya Jindal 112835035
; Created: 10/2/2020 10:33:18 AM
;
; Inputs:
;	PORTA = Switch ban input.
;	PORTE PIN0 = Push button input
;
; Outputs:
;	PortD = Bargraph LED output port.
;
; Register Assignments/Purpose
;	r16 = GP = general purpose, assign initial port conditions
;		= decrement delay variable in var_delay
;	r17 = varaible push button count-up  value
;		= decrement delay variable in var_delay
;
; Registers altered: r16, r17
;
; Section no.: 4
; Experiment no.: 5
; Bench no.: 7

start:
    ldi r16, 0x00			;load with all zeros
	out VPORTA_DIR, r16		;PORTA - all pins configured as inputs
	
	cbi VPORTE_DIR, 0		;Set input pin
	ldi r16, 0xFF		
	out VPORTD_DIR, r16		;set output port.

	ldi r17, 0xFF			;initiialize empty counter
	out VPORTD_OUT, r17		;output inital counter value to the LEDs
	com r17

main_loop:
	sbic VPORTE_IN, 0		;skips next instruction if push button is pressed
	rjmp main_loop			;while push button is not pushed causes loop

	rjmp var_delay

	rjmp rising_edge

	rjmp main_loop			;loop back to main loop

rising_edge:
	sbis VPORTE_IN, 0		;skips next instruction if the push button is released
	rjmp rising_edge		;causes a loop while the push button is pressed


	rjmp main_loop

change_barled:
	sbic VPORTE_IN, 0		;loop back to main loop if push button value changes back to logic 1
	rjmp main_loop
	
	in r16, VPORTA_IN		;read switch values
	com r16					;complement switch values to drive LEDs
	out VPORTD_OUT, r16		;output to LEDs complement input from switches

	rjmp rising_edge

var_delay:
	ldi r16, 25				;first delay variable set to value 1-25
outer_loop:
	ldi r17, 110			;second delay variable
inner_loop:					;delay for total variable time r16 * r17
	dec r17
	brne inner_loop
	dec r16
	brne outer_loop

	rjmp change_barled		;jump to loop to update the Bar LED