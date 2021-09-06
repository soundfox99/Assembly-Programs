;
; color_computer.asm
;
; Created: 9/24/2020 9:44:17 PM
; Author : Hermes
;


start:
    ; Congigure I/O ports
	ldi r16, 0xFF		;load r16 with all 1s
	out VPORTD_DIR, r16	;PORTD - all pins configured as outputs
	out VPORTC_DIR, r16	;PORTC - all pins configured as outputs
	ldi r16, 0x00		;load r16 with all 0s
	out VPORTA_DIR, r16	;PORTA - all pins configured as inputs

main_loop:
	in r16, VPORTA_IN		;read in switch values
	andi r16, 0xE0

	out VPORTC_OUT, r16		;output to muliLED
	com r16					;take ones compliment
	out VPORTD_OUT, r16		;output to single LEDs
	
	rjmp main_loop