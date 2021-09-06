;**************************************************
;*
;* Title: enter_digits
;* Author: Aditya Jindal
;* Version:	1.0
;* Last updated: 10292020
;* Target: ATmega4809
;*
;* DESCRIPTION: User enters digits conditionally which
;*				 are then output to LED display
;* 
;* 
;*
;*
;* VERSION HISTORY
;* 1.0 Original version
;******************************************************

.nolist
.include "m4809def.inc"
.list

;* Define varaibles
.dseg
bcd_entries: .byte 4
led_display: .byte 4
digit_num: .byte 1
.cseg

;Task 4
start:
	ldi r16,0x00
	out VPORTA_DIR,r16 ; make PORTA input
	
	ldi r16, 0xFF ;make r16 all 1s
	out VPORTD_DIR, r16; make portD to output

	ldi r16, 0xF0
	out VPORTC_DIR, r16 ;top pins of portC to output

	cbi VPORTE_DIR,0 ;PE0 ans push button input
	sbi VPORTE_DIR,1 ;PE1 as output

	cbi VPORTE_OUT, 1	;clear flip flop
	sbi VPORTE_OUT, 1	;stop clearing flip flop

	;Initialize vairables and arrays	
	ldi r16, 0x00;
	sts digit_num, r16 ;Initialize digit_num variable

	ldi YH, HIGH(bcd_entries)	;set pointer to end of array
	ldi YL, LOW(bcd_entries)	;set pointer to start of array
	
	std Y+0 ,r16
	std Y+1 ,r16
	std Y+2 ,r16
	std Y+3 ,r16

	ldi r16, 0xFF
	ldi XH, HIGH(led_display)	;set pointer to end of array
	ldi XL, LOW(led_display)	;set pointer to start of array

	st X+ ,r16 ;initalize LED display array
	st X+ ,r16 ;initalize LED display array
	st X+ ,r16 ;initalize LED display array
	st X+ ,r16 ;initalize LED display array


main_loop:
	rcall poll_digit_entry	
	rcall var_delay
	rcall multiplex_display

	rjmp main_loop 


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

;**************************************************
;* 
;* "multiplex_display"
;*
;* Description: outputs the segment values for the 
;*	next multiplexed digit to be displayed and turns
;*	ON that digit
;*
;* Author: Aditya Jindal
;* Version: 1.0
;* Last updated: 10-29-2020
;* Target: ATmega4809
;* Number of words: 32
;* Number of cycles: 36
;* Low registers modified: none
;* High registers modified: r16, r17, r18, r20, YH, YL
;*
;* Parameters: none
;* Returns: none
;*
;* Notes: 
;*
;***********************************************

multiplex_display:
	lds r16, digit_num ;load digit num into r16
	andi r16, 0x03	;mask it to get lsb
	mov r17,r16	;make a copy of r16
	
	sts digit_num, r17	;load r17 into variable

	ldi YL, LOW(led_display)	;set pointer
	ldi YH, HIGH(led_display)
	
	inc r16	;increment register
output_loop:
	dec r16	;decremnt register
	ld r18,Y+	;store incremented pointer value
	brne output_loop

	
	cpi r17,0 ;demux r17 to choose correct anode
	breq pos_zero	;branch to the right position
	cpi r17,1	
	breq pos_one
	cpi r17,2	
	breq pos_two
	cpi r17,3	
	breq pos_three

pos_zero:
	ldi r20, 0xEF	;set r20 to the PC value
	rjmp position	;branch to position
pos_one:
	ldi r20,0xDF
	rjmp position

pos_two:
	ldi r20,0xBF
	rjmp position

pos_three:
	ldi r20, 0x7F
	rjmp position

position:
	ldi r19, 0xFF
	out VPORTC_OUT, r19	;turn off digit to modigy
	out VPORTD_OUT, r18	;output the right segment value
	out VPORTC_OUT, r20 ;power common anode
	inc r17	;increment register
	sts digit_num, r17 ;store register in variable
	ret

;*******************************************
;* 
;* "poll_digit_entries" - title
;*
;* Description: 
;*
;* Author: Aditya Jindal
;* Version: 1.0
;* Last updated: 10-29-2020
;* Target: ATmega4809
;* Number of words: 27
;* Number of cycles: 282
;* Low registers modified:
;* High registers modified: r16,r17,r18,r19,r20,r21
;*							ZH, ZL, YH, YL
;*
;* Parameters: none
;* Returns: none
;*
;* Notes: 
;*
;*****************************************

poll_digit_entry:
	sbis VPORTE_IN, 0; wait for button press
	ret
	
	in r22, VPORTA_IN	;input values into register 
	
	mov r16, r22
	rcall reverse_bits

	cpi r18, 10
	brge brnch_grt_equ	;go back to main loop if not < 10
	
	ldi YH, HIGH(bcd_entries)	;set pointer to end of array
	ldi YL, LOW(bcd_entries)	;set pointer to start of array

	;Put pointer values in register to move array
	ldd r19,Y+0
	ldd r20,Y+1
	ldd r21,Y+2

	;move the array with r17 beign new value
	std Y+0 ,r22
	std Y+1 ,r19
	std Y+2 ,r20
	std Y+3 ,r21

	ldi XH, HIGH(led_display)	;set pointer to end of array
	ldi XL, LOW(led_display)	;set pointer to start of array

	ldd r16, Y+0	;move bcd entry to subroutine input
	rcall reverse_bits	;call subroutine to reverse r16
	rcall hex_to_7seg	;call subroutine
	st X+ ,r18	;store result in led array

	ldd r16, Y+1	;same as before
	rcall reverse_bits
	rcall hex_to_7seg
	st X+ ,r18

	ldd r16, Y+2	;same as first
	rcall reverse_bits
	rcall hex_to_7seg
	st X+,r18

	ldd r16, Y+3	;same as first
	rcall reverse_bits
	rcall hex_to_7seg
	st X+,r18

brnch_grt_equ:
	cbi VPORTE_OUT, 1	;clear flip flop
	sbi VPORTE_OUT, 1	;stop clearing flip flop

	ret	;return when done


;****************************************
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
;****************************************

hex_to_7seg:
	andi r18, 0x0F				;clear ms nibble
    ldi ZH, HIGH(hextable * 2)  ;set Z to point start table
    ldi ZL, LOW(hextable * 2)
    ldi r16, $00                ;add offset to Z pointer
    add ZL, r18
    adc ZH, r16
    lpm r18, Z                  ;load byte from table
	ret

    ;Table of segment values to display digits 0 - F
    ;!!! seven values must be added - verify all values
hextable: .db $01,$4F,$12,$06,$4C,$24,$20,$0F,$00,$0C,$08,$60,$31,$42,$30,$38

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