;
; sws_level.asm
;
; Created: 9/16/2020 10:50:54 PM
; Author : Aditya Jindal 112835035
;


; Replace with your application code
start:
    ; Configure I/O ports
	ldi r16, 0xFF		;load r16 with all 1s
	out VPORTD_DIR, r16	;PORTD - all pins configred as outputs
	ldi r16, 0x00		;load r16 with all 0s
	out VPORTA_DIR, r16	;PORTA - all pins configure as inputs

main_loop:
	in r16, VPORTA_IN	;read switch values

	;Code to count switches in '1's position and output to bargraph
	ldi r17, 8			;loop parameter for inner loop
	ldi r18, $00		;initial value of image to be output to bargraph LEDs

next_bit:

	lsl r16				;shift msb of r16 into carry
	brcc dec_bitcounter	;branch if carry clear
	rol r18				;rotate 1 from carry int bar

dec_bitcounter:
	dec r17
	brne next_bit		;branch if result after dec is not zero
	com r18				;complement bargraph image
	out VPORTD_OUT, r18	;output image to bargraph
	rjmp main_loop