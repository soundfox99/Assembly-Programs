;
; table_lookup_seg_test.asm
;
; Description: The program checks all of the 7-Segment
;	displays and segments to make sure they are working
;
; Author : Aditya Jindal 112835035
; Created: 10/19/2020 11:19:42 PM
;
; Register Assignments/Purpose
;	r16 = GP = general purpose, assign initial port conditions
;		= used to read input from VPORTA
;		= used in hex_to_7seg
;	r17 = used as decrement counter in reverse_bits
;	r18 = used to store altered input value 
;	r19 = used as a mask in rever_bits
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

; Task 2
start:
	ldi r16, 0x00		;load with all zeros
	out VPORTA_DIR, r16	;Set port A to input

	sbi VPORTC_DIR, 4	;set 7 bit to output

	cbi VPORTC_OUT, 4	;set PC7 to on

	ldi r16, 0xFF		;load with all ones
	out VPORTD_DIR, r16		;Set Port D to output
	
	cbi VPORTE_DIR, 0	;set PE0 to input
	sbi VPORTE_DIR, 1	;set flip flop clear, asserted low

	cbi VPORTE_OUT, 1	;clear flip flop
	sbi VPORTE_OUT, 1	;stop clearing flip flop

main_loop:
	sbis VPORTE_IN, 0	;skips if push button is pressed
	rjmp main_loop		;while push button is not pushed causes loop

	in r16, VPORTA_IN	;load the switch values
	rcall reverse_bits	;call subroutine to reverse bits
	rcall hex_to_7seg	;call the convert sbrt
	out VPORTD_OUT, r18		;output result

	cbi VPORTE_OUT, 1	;clear flip flop
	sbi VPORTE_OUT, 1	;stop clearing flip flop

rising_edge:
	sbic VPORTE_IN, 0	;skips if the push button is released
	rjmp rising_edge	;causes loop while the button is pressed

	rjmp main_loop


;**********************************************************
;* 
;* "reverse_bits" - Reverse the order of a registers bits
;*
;* Description: Subroutine reverses the order of a registers bits
;*
;* Author:						Aditya Jindal
;* Version:						1.0						
;* Last updated:				10202020
;* Target:						ATmega4809
;* Number of words:				11
;* Number of cycles:			63
;* Low registers modified:		r16, r17, r18, r19		
;* High registers modified:		r18
;*
;* Parameters: r16: with loaded register value
;* Returns: r18: reversed register value
;*
;* Notes: 
;*
;********************************************************

reverse_bits:
	ldi r17, 7
	ldi r18, 0x00
reverse_bit_loop:
	ldi r19, 0x80
	and r19, r16
	or r18, r19
	lsr r18
	lsl r16
	dec r17
	brne reverse_bit_loop
	
	ret

;******************************************************
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
;*****************************************************

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