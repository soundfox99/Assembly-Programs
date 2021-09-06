;
; conditional_input_hdwe.asm
;
; Description: The program displays the result of a switch bank
;	to a bargraph LED, but the updated value is only displayed
;	when the push button is pressed.
;
; Author: Aditya Jindal 112835035
; Created: 10/10/2020 1:21:44 PM
;
; Inputs:
;	PORTA = Switch ban input.
;	PORTE PIN0 = Push button input from Flip Flop
;	PORTE PIN1 = Flip FLop clear
;
; Outputs:
;	PortD = Bargraph LED output port.
;
; Register Assignments/Purpose
;	r16 = GP = general purpose, assign initial port conditions
;		= used to read in switch values and output LED values
;
; Registers altered: r16
;
; Section no.: 4
; Experiment no.: 5
; Bench no.: 7

.nolist
.include"m4809def.inc"
.list

; Task 2
start:
    ldi r16, 0x00		;load with all zeros
	out VPORTA_DIR, r16	;PORTA - all pins configured as inputs
	
	ldi r16, 0xFF		
	out VPORTD_DIR, r16	;set output port.

	out VPORTD_OUT, r16	;output inital counter value to the LEDs

	cbi VPORTE_DIR, 0	;Set input pin for flip flop
	sbi VPORTE_DIR, 1	;set flip flop clear, asserted low

	cbi VPORTE_OUT, 1	;clear flip flop
	sbi VPORTE_OUT, 1	;stop clearing flip flop

main_loop:
	sbis VPORTE_IN, 0	;skips if push button is pressed
	rjmp main_loop		;while button not pushed loop

	in r16, VPORTA_IN	;read switch values
	com r16				;complement switch values to drive LEDs
	out VPORTD_OUT, r16	;output to LEDs complement input

	cbi VPORTE_OUT, 1	;clear flip flop
	sbi VPORTE_OUT, 1	;stop clearing flip flop

	rjmp main_loop		;loop back to main loop