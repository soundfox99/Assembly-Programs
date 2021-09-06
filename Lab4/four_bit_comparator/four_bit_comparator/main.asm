;
; four_bit_comparator.asm
;
; Created: 9/24/2020 4:28:10 PM
; Author : Aditya Jindal 112835035
;


; Replace with your application code
start:
    ; Congigure I/O ports
	ldi r16, 0xFF		;load r16 with all 1s
	out VPORTD_DIR, r16	;PORTD - all pins configured as outputs
	ldi r16, 0x00		;load r16 with all 0s
	out VPORTA_DIR, r16	;PORTA - all pins configured as inputs

main_loop:
	;main loop for the four bit comparator
	;for the code r17 is value A and r16 is value B
	
	;Get user's input
	in r16, VPORTA_IN		;read in switch values
	mov r17, r16			;mask for the inputs
	andi r16, 0x0F			;isolate the last four bits of Port A
	andi r17, 0xF0			;isolate the first four bits of Port A
	lsr r17					;move the r17's bits so the line up with r17
	lsr r17
	lsr r17
	lsr r17

	;Process the input and display the appropriate information.
	cp r17, r16				;Compare the values for A and B, allowing us to use the conditional branches later on.
	
	breq equal_to
	brsh greater_than
	brlo less_than

	rjmp main_loop

equal_to:
	in r18, VPORTD_OUT		;read led port into a register
	ori r18, 0xFF
	andi r18, 0xBF
	out VPORTD_OUT, r18		;Set PD6 to low which would turn the LED on
	rjmp main_loop


greater_than:
	in r18, VPORTD_OUT		;read led port into a register
	ori r18, 0xFF
	andi r18, 0x7F
	out VPORTD_OUT, r18		;Set PD7 to low which would turn the LED on
	rjmp main_loop


less_than:
	in r18, VPORTD_OUT		;read led port into a register
	ori r18, 0xFF
	andi r18, 0xDF
	out VPORTD_OUT, r18		;Set PD5 to low which would turn the LED on
	rjmp main_loop