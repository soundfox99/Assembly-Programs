;
; three_to_eight_decoder.asm
;
; Created: 9/24/2020 9:00:11 PM
; Author : Aditya Jindal
;


start:
    ; Congigure I/O ports
	ldi r16, 0xFF		;load r16 with all 1s
	out VPORTD_DIR, r16	;PORTD - all pins configured as outputs
	out VPORTD_OUT, r16
	ldi r16, 0x00		;load r16 with all 0s
	out VPORTA_DIR, r16	;PORTA - all pins configured as inputs

main_loop:
	in r16, VPORTA_IN	;read switch values
	andi r16, 0xFC

	;Use if else statement to determine which LED to turn on by putting to 0.
	cpi r16, 0xF0
	breq light_seven
	cpi r16, 0xD0
	breq light_six
	cpi r16, 0xB0
	breq light_five
	cpi r16, 0x90
	breq light_four
	cpi r16, 0x70
	breq light_three
	cpi r16, 0x50
	breq light_two
	cpi r16, 0x30
	breq light_one
	cpi r16, 0x10
	breq light_zero

	ldi r17, 0xFF
	out VPORTD_OUT, r17

	rjmp main_loop

light_seven:
	ldi r17, 0x7F
	out VPORTD_OUT, r17
	rjmp main_loop

light_six:
	ldi r17, 0xBF
	out VPORTD_OUT, r17
	rjmp main_loop

light_five:
	ldi r17, 0xDF
	out VPORTD_OUT, r17
	rjmp main_loop

light_four:
	ldi r17, 0xEF
	out VPORTD_OUT, r17
	rjmp main_loop

light_three:
	ldi r17, 0xF7
	out VPORTD_OUT, r17
	rjmp main_loop

light_two:
	ldi r17, 0xFB
	out VPORTD_OUT, r17
	rjmp main_loop

light_one:
	ldi r17, 0xFD
	out VPORTD_OUT, r17
	rjmp main_loop

light_zero:
	ldi r17, 0xFE
	out VPORTD_OUT, r17
	rjmp main_loop
