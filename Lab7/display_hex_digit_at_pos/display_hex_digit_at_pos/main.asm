;
; display_hex_digit_at_pos.asm
;
; Description: The program conditionally sets
;	the displays of 4 7-seg displays based
;	on switch input and a push button
;
; Author : Aditya Jindal 112835035
; Created: 10/20/2020 4:07:40 PM
;
; Register Assignments/Purpose
;	r16 = Initialize Ports and r21-24
;		= Read in VPORTA
;		= Used in hex_to_7seg
;	r17 = Used as a counter in reverse bits
;	r18 = Used to store reversed bits
;		= Used in hex_to_7seg
;		= Used to output to 7seg display
;	r19 = Used as a mask in reverse bits
;	r20 = Used to figure out which position ot change
;	r21 = Store the display value of 0 pos 7-seg display
;	r22 = Store the display value of 1 pos 7-seg display
;	r23 = Store the display value of 2 pos 7-seg display
;	r24 = Store the display value of 3 pos 7-seg display
;
; Registers altered: r16, r17, r18, r19,
;					 r20, r21, r22, r23, r24
;
; Section no.: 4
; Experiment no.: 7
; Bench no.: 7

.nolist
.include "m4809def.inc"
.list

; Design Task 3
start:
    ldi r16, 0x00		;load with all zeros
	out VPORTA_DIR, r16	;Set port A to input.

	ldi r16, 0xF0		;initial Port C
	out VPORTC_DIR, r16

	ldi r16, 0xFF		;load with all ones
	out VPORTD_DIR, r16	;Set Port D to output
	
	cbi VPORTE_DIR, 0	;set PE0 to input
	sbi VPORTE_DIR, 1	;set flip flop clear, asserted low

	ldi r16, 0xFF		;set initial output
	out VPORTD_OUT, r16 ;turn Port D off

	cbi VPORTE_OUT, 1	;clear flip flop
	sbi VPORTE_OUT, 1	;stop clearing flip flop
	
	;Have registers for the individual 7-seg
	mov r21, r16	;Position 0
	mov r22, r16	;Position 1
	mov r23, r16	;Position 2
	mov r24, r16	;Position 3

main_loop:
	ldi r19, 0x10
	com r19
	out VPORTD_OUT, r21	;output the display value
	out VPORTC_OUT, r19 ;give power to right most 7-seg
	rcall var_delay
	ldi r19, 0xFF

	
	ldi r19, 0x20
	com r19
	out VPORTD_OUT, r22	;output the display value
	out VPORTC_OUT, r19 ;give power to right most 7-seg
	rcall var_delay
	ldi r19, 0xFF

	ldi r19, 0x40
	com r19
	out VPORTD_OUT, r23	;output the display value
	out VPORTC_OUT, r19 ;give power to right most 7-seg
	rcall var_delay
	ldi r19, 0xFF

	ldi r19, 0x80
	com r19
	out VPORTD_OUT, r24	;output the display value
	out VPORTC_OUT, r19 ;give power to right most 7-seg
	rcall var_delay
	ldi r19, 0xFF

	sbis VPORTE_IN, 0	;skips if push button is pressed
	rjmp main_loop		;push button not pushed causes loop

	in r16, VPORTA_IN	;load the switch values
	
	rcall reverse_bits	;call subroutine to reverse bits
	
	mov r20, r18		;make copy of r16
	andi r20, 0xC0		;mask r20
	
	rcall hex_to_7seg	;call the convert sbrt

	;Copy r18 to the right register
	;Decide which 7-seg need to be changed
	cpi r20, 0x00
	breq change_pos_0

	cpi r20, 0x40
	breq change_pos_1

	cpi r20, 0x80
	breq change_pos_2

	cpi r20, 0xC0
	breq change_pos_3

rising_edge:
;	sbis VPORTE_IN, 0	;skips if the push button is released
;	rjmp rising_edge	;causes loop while the button is pressed

	cbi VPORTE_OUT, 1	;clear flip flop
	sbi VPORTE_OUT, 1	;stop clearing flip flop

	rjmp main_loop

change_pos_0:	;change right most segment
	mov r21, r18
	rjmp rising_edge

change_pos_1:	;change second right most segment
	mov r22, r18
	rjmp rising_edge

change_pos_2:
	mov r23, r18
	rjmp rising_edge

change_pos_3:	;change left most segment
	mov r24, r18
	rjmp rising_edge

var_delay:
	ldi r16, 6		;load r16 with 1-25ms
outer_loop:
	ldi r17, 110		;load r17 with a second delay variable
inner_loop:				;delay for the total decided time.
	dec r17
	brne inner_loop
	dec r16
	brne outer_loop

	ret


;*******************************************************
;* 
;* "reverse_bits" - Reverse the order of a registers bits
;*
;* Description: Subroutine reverses the order of a register
;*
;* Author:						Aditya Jindal
;* Version:						1.0						
;* Last updated:				10202020
;* Target:						ATmega4809
;* Number of words:				11
;* Number of cycles:			63
;* Low registers modified:		none	
;* High registers modified:		r16, r17, r18, r19
;*
;* Parameters: r16: with loaded register value
;* Returns: r18: reversed register value
;*
;* Notes: 
;*
;***********************************************************

reverse_bits:
	ldi r17, 8		;have a counter
reverse_bit_loop:
	lsl r16			;move r16
	ror r18
	dec r17			;decrement counter
	brne reverse_bit_loop
	
	ret	;return after counter done

;*********************************************************
;* 
;* "hex_to_7seg" - Hexadecimal to Seven Segment Conversion
;*
;* Description: Converts a right justified hexadecimal digit 
;*to the seven segment pattern required to display it. 
;*Pattern is right justified a through g. 
;*Pattern uses 0s to turn segments on ON.
;*
;* Author:						Ken Short
;* Version:						1.0						
;* Last updated:				101620
;* Target:						ATmega4809
;* Number of words:				8
;* Number of cycles:			13
;* Low registers modified:		none		
;* High registers modified:		r16, r18, ZL, ZH
;*
;* Parameters: r18: right justified hex digit, high nibble 0
;* Returns: r18: segment values a through g right justified
;*
;* Notes: 
;*
;*************************************************************

hex_to_7seg:
	andi r18, 0x0F				;clear ms nibble
    ldi ZH, HIGH(hextable * 2)  ;set Z to point to start of table
    ldi ZL, LOW(hextable * 2)
    ldi r16, $00                ;add offset to Z pointer
    add ZL, r18
    adc ZH, r16
    lpm r18, Z                  ;load byte from table pointed by Z
	ret

    ;Table of segment values to display digits 0 - F
    ;!!! seven values must be added - verify all values
hextable: .db $01,$4F,$12,$06,$4C,$24,$20,$0F,$00,$0C,$08,$60,$31,$42,$30,$38
