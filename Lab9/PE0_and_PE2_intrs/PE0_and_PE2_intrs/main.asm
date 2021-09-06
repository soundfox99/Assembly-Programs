
;*****************************************
;*
;* Title:
;* Interrupt Driven Counting of Pushbutton Presses
;*
;* Author:				Ken Short
;* Version:				1.0
;* Last updated:		102820
;* Target:				ATmega4809 @3.3MHz
;*
;* DESCRIPTION
;* Uses positive edge triggered pin change 
;*interrupts to count the number of times each of 
;* two pushbuttons is pressed. Pushbutton 1 is connected
;* to PE0 and pushbutton 2 is connected to PE2. 
;* The counts are stored in two byte memory variable.
;*
;* VERSION HISTORY
;* 1.0 Original version
;******************************************

.nolist
.include "m4809def.inc"
.list

.dseg
PB1_count: .byte 1	;pushbutton 1 presses.
PB2_count: .byte 1	;pushbutton 2 presses.


.cseg				;start of code segment
reset:
 	jmp start		;reset vector executed a power on

.org PORTE_PORT_vect
	jmp porte_isr	;vector for all PORTE pin change IRQs


start:
    ; Configure I/O ports
	cbi VPORTE_DIR, 0	;PE0 input- gets output from PB1
	cbi VPORTE_DIR, 2	;PE2 input- gets output from PB2

	ldi r16, 0x00		;make initial counts 0
	sts PB1_count, r16
	sts PB2_count, r16

	;Configure interrupts
	lds r16, PORTE_PIN0CTRL	;set ISC for PE0 to pos. edge
	ori r16, 0x02		;set ISC for rising edge
	sts PORTE_PIN0CTRL, r16

	lds r16, PORTE_PIN2CTRL	;set ISC for PE2 to pos. edge
	ori r16, 0x02		;set ISC for rising edge
	sts PORTE_PIN2CTRL, r16

	sei			;enable global interrupts
    
main_loop:		;main program loop
	nop
	rjmp main_loop


;Interrupt service routine for any PORTE pin change IRQ
porte_ISR:
	push r16		;save r16 then SREG
	in r16, CPU_SREG
	push r16
	cli				;clear global interrupt enable

	;Determine which pins of PORTE have IRQs
	lds r16, PORTE_INTFLAGS	;check for PE0 IRQ flag set
	sbrc r16, 0
	rcall PB1_sub			;execute subroutine for PE0

	lds r16, PORTE_INTFLAGS	;check for PE2 IRQ flag set
	sbrc r16, 2
	rcall PB2_sub			;execute subroutine for PE2

	pop r16			;restore SREG then r16
	out CPU_SREG, r16
	pop r16
	reti			;return from PORTE pin change ISR


;Subroutines called by porte_ISR
PB1_sub:		;PE0's task to be done
	lds r16, PB1_count		;get current count for PB1
	inc r16					;increment count
	sts PB1_count, r16		;store new count
	ldi r16, PORT_INT0_bm	;clear IRQ flag for PE0
	sts PORTE_INTFLAGS, r16
	ret


PB2_sub:		;PE2's task to be done
	lds r16, PB2_count		;get current count for PB2
	inc r16					;increment count
	sts PB2_count, r16		;store new count
	ldi r16, PORT_INT2_bm	;clear IRQ flag for PE2
	sts PORTE_INTFLAGS, r16
	ret


