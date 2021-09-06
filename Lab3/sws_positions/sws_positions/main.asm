;
; sws_positions.asm
;
; Created: 9/16/2020 10:26:16 PM
; Author : Aditya Jindal 112835035
;


; Replace with your application code
start:
    ; Congigure I/O ports
	ldi r16, 0xFF		;load r16 with all 1s
	out VPORTD_DIR, r16	;PORTD - all pins configured as outputs
	ldi r16, 0x00		;load r16 with all 0s
	out VPORTA_DIR, r16	;PORTA - all pins configured as inputs

	;Continuall input switch values and output to LEDs
again:
	in r16, VPORTA_IN	;read switch values
	com r16				;complement switch values to drive LEDs
	out VPORTD_OUT, r16	;output to LEDs complement input from switches
	rjmp again			;continually repeat previous three instructions
