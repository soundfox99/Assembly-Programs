;**************************************************
;*
;* Title: bdc_to_hex_mux_intr
;* Author: Aditya Jindal
;* Version:	1.0
;* Last updated: 11082020
;* Target: ATmega4809
;*
;* DESCRIPTION: User enters digits conditionally which
;* are then output to LED display, if the first
;* button is pressed. If the second push button is 
;* pressed then the the numbers in bcd_entried are
;* taken in a a 4-digit value and displayed in HEX 
;* this program uses interupts instead of polling
;* also uses clocks instead of delay subroutine
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

.equ PERIOD_EXAMPLE_VALUE = 64

;* Define varaibles
.dseg
bcd_entries: .byte 4
led_display: .byte 4
digit_num: .byte 1

;Task 2
.cseg			;start of code segment
reset:
 	jmp start	;reset vector executed a power on

.org TCA0_OVF_vect
	jmp toggle_pin_ISR
.org PORTE_PORT_vect
	jmp porte_isr;vector for all PORTE pin change IRQs


start:
	ldi r16,0x00
	out VPORTA_DIR,r16 ; make PORTA input
	
	ldi r16, 0xFF ;make r16 all 1s
	out VPORTD_DIR, r16; make portD to output

	ldi r16, 0xF0
	out VPORTC_DIR, r16 ;top pins of portC to output

	cbi VPORTE_DIR,0 ;PE0 as first pushbutton
	cbi VPORTE_DIR,2 ;PE2 as second pushbutton

	;Initialize vairables and arrays	
	ldi r16, 0x00;
	sts digit_num, r16 ;Initialize digit_num variable

	ldi YH, HIGH(bcd_entries)	;set pointer to end of array
	ldi YL, LOW(bcd_entries)	;set pointer to start of array
	
	std Y+0 ,r16		;initialize bcd_entried
	std Y+1 ,r16
	std Y+2 ,r16
	std Y+3 ,r16

	ldi r16, 0xFF
	ldi XH, HIGH(led_display);set pointer to end of array
	ldi XL, LOW(led_display);set pointer to start of array

	st X+ ,r16 ;initalize LED display array
	st X+ ,r16 ;initalize LED display array
	st X+ ,r16 ;initalize LED display array
	st X+ ,r16 ;initalize LED display array

	;Configure interrupts
	lds r16, PORTE_PIN0CTRL	;set ISC for PE0 to pos. edge
	ori r16, 0x02		;set ISC for rising edge
	sts PORTE_PIN0CTRL, r16

	lds r16, PORTE_PIN2CTRL	;set ISC for PE2 to pos. edge
	ori r16, 0x02		;set ISC for rising edge
	sts PORTE_PIN2CTRL, r16

	;configure TCA0
	ldi r16, TCA_SINGLE_WGMODE_NORMAL_gc	;WGMODE normal
	sts TCA0_SINGLE_CTRLB, r16

	ldi r16, TCA_SINGLE_OVF_bm		;enable overflow interrupt
	sts TCA0_SINGLE_INTCTRL, r16

	;load period low byte then high byte
	ldi r16, LOW(PERIOD_EXAMPLE_VALUE)	;set the period
	sts TCA0_SINGLE_PER, r16
	ldi r16, HIGH(PERIOD_EXAMPLE_VALUE)	;set the period
	sts TCA0_SINGLE_PER + 1, r16

	;set clock and start timer
	ldi r16, TCA_SINGLE_CLKSEL_DIV256_gc | TCA_SINGLE_ENABLE_bm
	sts TCA0_SINGLE_CTRLA, r16

	sei		;enable global interrupts


main_loop:	
	rjmp main_loop ;loop back

;Interrupt service routine for any PORTE pin change IRQ
porte_ISR:
	push r16		;save r16
	push r17		;save r17
	push r18		;save r18
	push r20		;save r20
	push YH			;save YH pointer
	push YL			;save YL pointer
	in r16, CPU_SREG ;save SREG
	push r16
	cli				;clear global interrupt enable

	;Determine which pins of PORTE have IRQs
	lds r16, PORTE_INTFLAGS	;check for PE0 IRQ flag set
	sbrc r16, 0
	rcall poll_digit_entry		;execute subroutine for PE0

	lds r16, PORTE_INTFLAGS	;check for PE2 IRQ flag set
	sbrc r16, 2
	rcall pol_bcd_hex			;execute subroutine for PE2

	pop r16			;restore SREG then other registers
	out CPU_SREG, r16
	pop YL
	pop YH
	pop r20
	pop r18
	pop r17
	pop r16
	reti			;return from PORTE pin change ISR

toggle_pin_ISR:
	push r16
	in r16, CPU_SREG
	push r16
	push r17
	push r18
	push r19
	push r20
	push YH			;save YH pointer
	push YL			;save YL pointer

	rcall multiplex_display

	ldi r16, TCA_SINGLE_OVF_bm	;clear OVF flag
	sts TCA0_SINGLE_INTFLAGS, r16

	pop YL
	pop YH
	pop r20
	pop r19
	pop r18
	pop r17
	pop r16
	out CPU_SREG, r16
	pop r16

	reti

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
	in r16, VPORTA_IN	;input values into register 
	
	rcall reverse_bits
	andi r18, 0x0F

	cpi r18, 10
	brge brnch_grt_equ	;go back to main loop if not < 10
	
	ldi YH, HIGH(bcd_entries)	;set pointer to end of array
	ldi YL, LOW(bcd_entries)	;set pointer to start of array

	;Put pointer values in register to move array
	ldd r19,Y+0
	ldd r20,Y+1
	ldd r21,Y+2

	;move the array with r17 beign new value
	std Y+0 ,r18
	std Y+1 ,r19
	std Y+2 ,r20
	std Y+3 ,r21

	ldi XH, HIGH(led_display)	;set pointer to end of array
	ldi XL, LOW(led_display)	;set pointer to start of array

	ldd r18, Y+0	;move bcd entry to subroutine input
	rcall hex_to_7seg	;call subroutine
	st X+ ,r18	;store result in led array

	ldd r18, Y+1	;same as before
	rcall hex_to_7seg
	st X+ ,r18

	ldd r18, Y+2	;same as first
	rcall hex_to_7seg
	st X+,r18

	ldd r18, Y+3	;same as first
	rcall hex_to_7seg
	st X+,r18

brnch_grt_equ:
	ldi r16, PORT_INT0_bm	;clear IRQ flag for PE0
	sts PORTE_INTFLAGS, r16
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


;********************************************
;*
;* "BCD2bin16" - BCD to 16-Bit Binary Conversion
;*
;* This subroutine converts a 5-digit 
;* packed BCD number represented by 3 bytes 
;* (fBCD2:fBCD1:fBCD0) to a 16-bit number (tbinH:tbinL). 
;* MSD of the 5-digit number must be placed 
;* in the lowermost nibble of fBCD2.
;*
;* Let "abcde" denote the 5-digit number. 
;* The conversion is done by computing the formula: 
;* 10(10(10(10a+b)+c)+d)+e. The subroutine "mul10a"/"mul10b" 
;* does the multiply-and-add operation which is repeated
;* four times during the computation.
;*
;* Number of words	:30
;* Number of cycles	:108
;* Low registers used	:4 
;*						(copyL,copyH,mp10L/tbinL,mp10H/tbinH)
;* High registers used  :4 (fBCD0,fBCD1,fBCD2,adder)	
;*
;***************************************************

;***** "mul10a"/"mul10b" Subroutine Register Variables

.def	copyL	=r12;temporary register
.def	copyH	=r13;temporary register
.def	mp10L	=r14;Low byte of number to be multiplied by 10
.def	mp10H	=r15;High byte of number to be multiplied by 10
.def	adder	=r19;value to add after multiplication	

;***** Code

mul10a:	;***** multiplies 
;*"mp10H:mp10L" with 10 and adds "adder" high nibble
	swap	adder
mul10b:	;***** multiplies 
;*"mp10H:mp10L" with 10 and adds "adder" low nibble
	mov	copyL,mp10L	;make copy
	mov	copyH,mp10H
	lsl	mp10L;multiply original by 2
	rol	mp10H
	lsl	copyL;multiply copy by 2
	rol	copyH		
	lsl	copyL	;multiply copy by 2 (4)
	rol	copyH		
	lsl	copyL	;multiply copy by 2 (8)
	rol	copyH		
	add	mp10L,copyL	;add copy to original
	adc	mp10H,copyH	
	andi	adder,0x0f	;mask away upper nibble of adder
	add	mp10L,adder	;add lower nibble of adder
	brcc	m10_1		;if carry not cleared
	inc	mp10H		;	inc high byte
m10_1:	ret	

;***** Main Routine Register Variables

.def	tbinL	=r14;Low byte of binary result (same as mp10L)
.def	tbinH	=r15;High byte of binary result (same as mp10H)
.def	fBCD0	=r16;BCD value digits 1 and 0
.def	fBCD1	=r17;BCD value digits 2 and 3
.def	fBCD2	=r18;BCD value digit 5

;***** Code

BCD2bin16:
	andi	fBCD2,0x0f	;mask away upper nibble of fBCD2
	clr	mp10H		
	mov	mp10L,fBCD2	;mp10H:mp10L = a
	mov	adder,fBCD1
	rcall	mul10a	;mp10H:mp10L = 10a+b
	mov	adder,fBCD1
	rcall	mul10b	;mp10H:mp10L = 10(10a+b)+c
	mov	adder,fBCD0		
	rcall	mul10a	;mp10H:mp10L = 10(10(10a+b)+c)+d
	mov	adder,fBCD0
	rcall	mul10b	;mp10H:mp10L = 10(10(10(10a+b)+c)+d)+e
	ret

;**************************************************
;* 
;* "poll_bcd_hex" - Polls Pushbutton 2 for Conditional
;*	Conversion of BCD to Hex.
;*
;* Description:
;* Polls the flag associated with pushbutton 2. This flag
;* is connected to PE2. If the flag is set, the digits in the
;* bcd_entires array are read and passed to the prewritten
;* subroutine BCD2bin16. This subroutine performs a BCD to
;* binary conversion. The binary result is partitioned into
;* hexadecimal and placed into the array hex_results. The
;* contents of the hex_results array is converted to seven
;* segemnt values and placed into the led_display array.
;*
;* Author: Aditya Jindal
;* Version: 1.0
;* Last updated: 10-30-2020
;* Target: ATmega4809
;* Number of words:
;* Number of cycles:
;* Low registers modified:
;* High registers modified:
;*
;* Parameters: none
;* Returns: none
;*
;* Notes: 
;*
;***********************************************

pol_bcd_hex:
	ldi YH, HIGH(bcd_entries)	;set pointer to end of array
	ldi YL, LOW(bcd_entries)	;set pointer to start of array


	ldd r17, Y+3	;load last value in bcd
	ldd r18, Y+2	;load second to last value

	lsl r17			;shift first value to msb
	lsl r17
	lsl r17
	lsl r17

	or r17, r18		;make r17 parameter

	ldd r16, Y+1	;load last value in bcd
	ldd r18, Y+0	;load second to last value

	lsl r16			;shift first value to msb
	lsl r16
	lsl r16
	lsl r16

	or r16, r18		;cobine values

	ldi r18, 0x00	;fill one parameter

	rcall BCD2bin16	;call subroutine

	ldi XH, HIGH(led_display)	;set pointer to end of array
	ldi XL, LOW(led_display)	;set pointer to start of array

	mov r18, r14
	rcall hex_to_7seg	;call subroutine
	st X+ ,r18	;store result in led array

	mov r18, r14
	lsr r18			;shift first value to msb
	lsr r18
	lsr r18
	lsr r18
	
	rcall hex_to_7seg
	st X+ ,r18

	mov r18, r15
	rcall hex_to_7seg
	st X+,r18

	mov r18, r15
	lsr r18			;shift first value to msb
	lsr r18
	lsr r18
	lsr r18
	
	rcall hex_to_7seg
	st X+,r18

	ldi r16, PORT_INT2_bm	;clear IRQ flag for PE2
	sts PORTE_INTFLAGS, r16
	ret	;return when done