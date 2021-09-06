;
; segment_and_digit_test.asm
;
; Description: The program checks all of the 7-Segment
;	displays and segments to make sure they are working
;
; Author : Aditya Jindal 112835035
; Created: 10/19/2020 10:29:55 PM
;
; Register Assignments/Purpose
;	r16 = GP = general purpose, assign initial port conditions
;		= used as decrement counter in var dealy to specify 1-25 us
;	r17 = used as decrement counter in var delay
;	r18 = counter to call var delay multiple 
;	r19 = variable to multiplex LEDs
;
;
; Registers altered: r16, r17, r18, r19
;
; Section no.: 4
; Experiment no.: 7
; Bench no.: 7

.nolist
.include "m4809def.inc"
.list

; Design Task 1
start:
    cbi VPORTE_DIR, 0	;Set input pin
	
	ldi r16, 0xFF		
	out VPORTD_DIR, r16	;set output port.

	ldi r16, 0xF0		;initial Port C
	out VPORTC_DIR, r16

	ldi r16, 0x00		;initiialize empty counter
	out VPORTD_OUT, r16	;output inital counter

main_loop:
	ldi r19, 0x10
	com r19
	out VPORTC_OUT, r19
	ldi r18, 39			;call var 39 times for 1s
	rcall one_sec_delay

	ldi r19, 0x20
	com r19
	out VPORTC_OUT, r19
	ldi r18, 39			;call var 39 times for 1s
	rcall one_sec_delay

	ldi r19, 0x40
	com r19
	out VPORTC_OUT, r19 ;give power to next 7-seg dis
	ldi r18, 39			;call var 39 times for 1s
	rcall one_sec_delay

	ldi r19, 0x80
	com r19
	out VPORTC_OUT, r19 ;give power to right most 7-seg
	ldi r18, 39			;call var 39 times for 1s	
	rcall one_sec_delay	;variable to delay for a second

	rjmp main_loop		;loop back to the main loop

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

one_sec_delay:
	rcall var_delay
	dec r18
	cpi r18, 0x00
	brne one_sec_delay	;keep looping till r18 zero
	ret
