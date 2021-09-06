;
; logic_ops.asm
;
; Created: 9/16/2020 10:32:29 PM
; Author : Aditya Jindal 112835035
;


; Replace with your application code
start:
    ;Configure I/0 ports
	ldi r16, 0xFF		;load r16 with all 1s
	out VPORTD_DIR,	r16	;PORTD - all pins configured as outputs
	ldi r16, 0x00		;load r16 with all 0s
	out VPORTA_DIR, r16	;PORTA - all pins configured as inputs

main_loop:
	in r16, VPORTA_IN	;read switch values
	mov r17, r16		;image for A
	mov r18, r16		;image for B
	andi r17, 0xE0		;mask for A
	andi r18, 0x1C		;mask for B
	lsl r18				;left justify A
	lsl r18
	lsl r18
	andi r16, 0x03		;mask for F
	cpi r16, 0x00		;is it an AND function
	breq and_fcn
	cpi r16, 0x01		;is it an OR function
	breq or_fcn
	cpi r16, 0x02		;is it an XOR fucntion
	breq xor_fcn
not_fcn:				;compute NOT, default
	com r17
	mov r18, r17
	rjmp output
and_fcn:				;compute AND
	and r18, r17
	rjmp output
or_fcn:					;compute OR
	or r18, r17
	rjmp output
xor_fcn:
	eor r18, r17
output:
	andi r18, 0xE0		;output result
	com r18
	out VPORTD_OUT, r18
	rjmp main_loop