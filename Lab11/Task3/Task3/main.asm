;**************************************************
;*
;* Title: ADC_sgnl_conv
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

;Task 1
.cseg			;start of code segment
reset:
 	jmp start	;reset vector executed a power on

.org TCA0_OVF_vect
	jmp toggle_pin_ISR
.org ADC0_RESRDY_vect
	jmp analog_pin_ISR

start:
	ldi r16, 0x20	;set 2.5V as teh reference
	sts VREF_CTRLA, r16

	ldi r16, 0x04 	;configure PE3 to work as ADC
	sts PORTE_PIN3CTRL, r16

	ldi r16, 0x01
	sts ADC0_CTRLA, r16

	ldi r16, 0x05
	sts ADC0_CTRLC, r16

	ldi r16, 0x0B
	sts ADC0_MUXPOS, r16

	ldi r16, 0x01
	sts ADC0_COMMAND, r16 


	ldi r16, 0xFF ;make r16 all 1s
	out VPORTD_DIR, r16; make portD to output

	ldi r16, 0xF0
	out VPORTC_DIR, r16 ;top pins of portC to output

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

	rcall post_display

main_loop:
	rcall signal_conv ;poll signal conerstion	
	rjmp main_loop ;loop back

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


analog_pin_ISR:
	push r16
	in r16, CPU_SREG
	push r16
	push r17
	push r18
	push r19
	push r20
	push YH			;save YH pointer
	push YL			;save YL pointer

	rcall signal_conv 

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
;* "signal_conv"
;*
;* Description: convert the temperature signal from
;* analog to digital
;*
;* Author: Aditya Jindal
;* Version: 1.0
;* Last updated:
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

signal_conv:
	;Get the temperature sensors data and load it into LED display

	lds r14, ADC0_RESL	;store result in registers
	lds r15, ADC0_RESH	

	ldi XH, HIGH(led_display);set pointer to end of array
	ldi XL, LOW(led_display);set pointer to start of array

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

	ldi r16, 0x01	;start the converstion
	sts ADC0_COMMAND, r16

	ret


;**************************************************
;* 
;* "post_display"
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
;* High registers modified: r16, XH, XL
;*
;* Parameters: none
;* Returns: none
;*
;* Notes: 
;*
;***********************************************

post_display:
	;Turn on all segements
	ldi r16, 0x00
	ldi XH, HIGH(led_display);set pointer to end of array
	ldi XL, LOW(led_display);set pointer to start of array

	st X+ ,r16 ;initalize LED display array
	st X+ ,r16 ;initalize LED display array
	st X+ ,r16 ;initalize LED display array
	st X+ ,r16 ;initalize LED display array
	
	ldi r18, 39
	rcall one_sec_delay	;one second delay

	;Turn all segments off
	ldi r16, 0xFF
	ldi XH, HIGH(led_display);set pointer to end of array
	ldi XL, LOW(led_display);set pointer to start of array

	st X+ ,r16 ;initalize LED display array
	st X+ ,r16 ;initalize LED display array
	st X+ ,r16 ;initalize LED display array
	st X+ ,r16 ;initalize LED display array

	ret

;*******************************************
;* 
;* "var_delay"
;*
;* Description: 25ms program software delay 
;*
;* Author: Aditya Jindal
;* Version: 1.0
;* Last updated: 10-29-2020
;* Target: ATmega4809
;* Number of words: 27
;* Number of cycles: 282
;* Low registers modified:
;* High registers modified: r16,r17
;*
;* Parameters: none
;* Returns: none
;*
;* Notes: 
;*
;*****************************************

var_delay:
	ldi r16, 255		;load r16 with 1-25ms
outer_loop:
	ldi r17, 110		;load r17 with a second delay variable
inner_loop:				;delay for the total decided time.
	dec r17
	brne inner_loop
	dec r16
	brne outer_loop

	ret

;*******************************************
;* 
;* "one_sec_delay"
;*
;* Description: Program to repeatedly call
;*	var_delay for bigger delays 
;*
;* Author: Aditya Jindal
;* Version: 1.0
;* Last updated: 10-29-2020
;* Target: ATmega4809
;* Number of words: 27
;* Number of cycles: 282
;* Low registers modified: none
;* High registers modified: r18
;*
;* Parameters: r18
;* Returns: none
;*
;* Notes: 
;*
;*****************************************

one_sec_delay:
	rcall var_delay
	dec r18
	cpi r18, 0x00
	brne one_sec_delay	;keep looping till r18 zero
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

    ;***************************************************************************
;*
;* "bin2BCD16" - 16-bit Binary to BCD conversion
;*
;* This subroutine converts a 16-bit number (fbinH:fbinL) to a 5-digit
;* packed BCD number represented by 3 bytes (tBCD2:tBCD1:tBCD0).
;* MSD of the 5-digit number is placed in the lowermost nibble of tBCD2.
;*
;* Number of words	:25
;* Number of cycles	:751/768 (Min/Max)
;* Low registers used	:3 (tBCD0,tBCD1,tBCD2)
;* High registers used  :4(fbinL,fbinH,cnt16a,tmp16a)	
;* Pointers used	:Z
;*
;***************************************************************************

;***** Subroutine Register Variables

.dseg
tBCD0: .byte 1  // BCD digits 1:0
tBCD1: .byte 1  // BCD digits 3:2
tBCD2: .byte 1  // BCD digits 4

.cseg
.def	tBCD0_reg = r13		;BCD value digits 1 and 0
.def	tBCD1_reg = r14		;BCD value digits 3 and 2
.def	tBCD2_reg = r15		;BCD value digit 4

.def	fbinL = r16		;binary value Low byte
.def	fbinH = r17		;binary value High byte

.def	cnt16a	=r18		;loop counter
.def	tmp16a	=r19		;temporary value

;***** Code

bin2BCD16:
    push fbinL
    push fbinH
    push cnt16a
    push tmp16a


	ldi	cnt16a, 16	;Init loop counter	
    ldi r20, 0x00
    sts tBCD0, r20 ;clear result (3 bytes)
    sts tBCD1, r20
    sts tBCD2, r20
bBCDx_1:
    // load values from memory
    lds tBCD0_reg, tBCD0
    lds tBCD1_reg, tBCD1
    lds tBCD2_reg, tBCD2

    lsl	fbinL		;shift input value
	rol	fbinH		;through all bytes
	rol	tBCD0_reg		;
	rol	tBCD1_reg
	rol	tBCD2_reg

    sts tBCD0, tBCD0_reg
    sts tBCD1, tBCD1_reg
    sts tBCD2, tBCD2_reg

	dec	cnt16a		;decrement loop counter
	brne bBCDx_2		;if counter not zero

    pop tmp16a
    pop cnt16a
    pop fbinH
    pop fbinL
ret			; return
    bBCDx_2:
    // Z Points tBCD2 + 1, MSB of BCD result + 1
    ldi ZL, LOW(tBCD2 + 1)
    ldi ZH, HIGH(tBCD2 + 1)
    bBCDx_3:
	    ld tmp16a, -Z	    ;get (Z) with pre-decrement
	    subi tmp16a, -$03	;add 0x03

	    sbrc tmp16a, 3      ;if bit 3 not clear
	    st Z, tmp16a	    ;store back

	    ld tmp16a, Z	;get (Z)
	    subi tmp16a, -$30	;add 0x30

	    sbrc tmp16a, 7	;if bit 7 not clear
        st Z, tmp16a	;	store back

	    cpi	ZL, LOW(tBCD0)	;done all three?
    brne bBCDx_3
        cpi	ZH, HIGH(tBCD0)	;done all three?
    brne bBCDx_3
rjmp bBCDx_1		



;***************************************************************************
;*
;* "BCD2bin16" - BCD to 16-Bit Binary Conversion
;*
;* This subroutine converts a 5-digit packed BCD number represented by
;* 3 bytes (fBCD2:fBCD1:fBCD0) to a 16-bit number (tbinH:tbinL).
;* MSD of the 5-digit number must be placed in the lowermost nibble of fBCD2.
;*
;* Let "abcde" denote the 5-digit number. The conversion is done by
;* computing the formula: 10(10(10(10a+b)+c)+d)+e.
;* The subroutine "mul10a"/"mul10b" does the multiply-and-add operation
;* which is repeated four times during the computation.
;*
;* Number of words	:30
;* Number of cycles	:108
;* Low registers used	:4 (copyL,copyH,mp10L/tbinL,mp10H/tbinH)
;* High registers used  :4 (fBCD0,fBCD1,fBCD2,adder)	
;*
;***************************************************************************

;***** "mul10a"/"mul10b" Subroutine Register Variables

.def	copyL	=r12		;temporary register
.def	copyH	=r13		;temporary register
.def	mp10L	=r14		;Low byte of number to be multiplied by 10
.def	mp10H	=r15		;High byte of number to be multiplied by 10
.def	adder	=r19		;value to add after multiplication	

;***** Code

mul10a:	;***** multiplies "mp10H:mp10L" with 10 and adds "adder" high nibble
	swap	adder
mul10b:	;***** multiplies "mp10H:mp10L" with 10 and adds "adder" low nibble
	mov	copyL,mp10L	;make copy
	mov	copyH,mp10H
	lsl	mp10L		;multiply original by 2
	rol	mp10H
	lsl	copyL		;multiply copy by 2
	rol	copyH		
	lsl	copyL		;multiply copy by 2 (4)
	rol	copyH		
	lsl	copyL		;multiply copy by 2 (8)
	rol	copyH		
	add	mp10L,copyL	;add copy to original
	adc	mp10H,copyH	
	andi	adder,0x0f	;mask away upper nibble of adder
	add	mp10L,adder	;add lower nibble of adder
    brcc	m10_1		;if carry not cleared
	    inc	mp10H		;	inc high byte
    m10_1:
ret	

;***** Main Routine Register Variables

.def	tbinL	=r14		;Low byte of binary result (same as mp10L)
.def	tbinH	=r15		;High byte of binary result (same as mp10H)
.def	fBCD0	=r16		;BCD value digits 1 and 0
.def	fBCD1	=r17		;BCD value digits 2 and 3
.def	fBCD2	=r18		;BCD value digit 5

;***** Code

BCD2bin16:
	andi	fBCD2,0x0f	;mask away upper nibble of fBCD2
	clr	mp10H		
	mov	mp10L,fBCD2	;mp10H:mp10L = a
	mov	adder,fBCD1
	rcall	mul10a		;mp10H:mp10L = 10a+b
	mov	adder,fBCD1
	rcall	mul10b		;mp10H:mp10L = 10(10a+b)+c
	mov	adder,fBCD0		
	rcall	mul10a		;mp10H:mp10L = 10(10(10a+b)+c)+d
	mov	adder,fBCD0
	rcall	mul10b		;mp10H:mp10L = 10(10(10(10a+b)+c)+d)+e
ret

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
