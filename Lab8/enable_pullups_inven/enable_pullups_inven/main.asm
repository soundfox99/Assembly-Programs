;*****************************************
;*
;* Title: enable_pullup_inven
;* Author: Aditya Jindal
;* Version: 1.0
;* Last updated: 10-29-2020
;* Target: ATmega4809
;*
;* DESCRIPTION: Enable the the pullup resistor
;*	and inverotr for port A pins
;* 
;* 
;*
;*
;* VERSION HISTORY
;* 1.0 Original version
;*******************************************

.nolist
.include "m4809def.inc"
.list

;Task 1
start:	
main_loop:
	rcall pullup_inven_en_A  ;call subroutine
readin_porta:
	lds r16, PORTA_IN
	rjmp readin_porta

;*******************************************
;* 
;* "pullup_inven_en_A" - title
;*
;* Description: Enables the pullup resistor and 
;*	and invertor for each of the PORT A pins
;*
;* Author:	Aditya Jindal
;* Version: 1.0
;* Last updated: 10-29-2020
;* Target:	ATmega4809
;* Number of words: 11
;* Number of cycles: 66
;* Low registers modified: none
;* High registers modified: r16, r17, XH, XL
;*
;* Parameters: none
;* Returns: none
;*
;* Notes: 
;*
;***********************************************
pullup_inven_en_A:
	ldi r16, 0x00	;load r16 with all 0s
	out VPORTA_DIR, r16 ;PORTA - all pins configured as inputs
	ldi XH, HIGH(PORTA_PIN0CTRL)	;X points to PORTA_PIN)CTRL
	ldi XL, LOW(PORTA_PIN0CTRL)
	ldi r17,8
pullups:
	ld r16, X   ;load value of PORTA_PINnCTRL
	ori r16, 0x88	;enable pullups and inven
	st X+, r16		;stores results
	dec r17			;decrement
	brne pullups
	ret