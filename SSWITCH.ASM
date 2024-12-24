	page	,132
;-----------------------------Module-Header-----------------------------;
; Module Name:	SSWITCH.ASM
;
;   This module contains the functions:
;
;
; Created: 16-Sep-1987
; Author:  *** ****** [******]
;
; Copyright (c) 1984-1987 Microsoft Corporation
;
; Exported Functions:	none
;
; Public Functions:	none
;
; Public Data:		none
;
; General Description:
;
; Restrictions:
;
;-----------------------------------------------------------------------;


	??_out	sswitch


ifdef	OS2_ONLY
	.286c
endif

	.xlist
	include cmacros.inc
	include macros.mac
	.list

	externFP GetModuleHandle
	externFP GetProcAddress
	externNP dev_initialization	;Other boot-time initialization


SCREEN_SWITCH_OUT equ	4001h		;Moving 3xBox to background
SCREEN_SWITCH_IN  equ	4002h		;Moving 3xBox to foreground
;DOS_VERSION	  equ	1000h		;Earliest DOS we must support (10.00)
DOS_VERSION	  equ	0310h		;Earliest DOS we must support (03.10)
HOT_KEY_VERSION   equ	1000h		;Version with hot key support (10.00)


INT_MULT	equ	2Fh		;Multiplexed interrupt number


sBegin	Data

	externB		screen_busy	;screen semaphore

old_screen_busy	db	?		;saved value of screen semaphore
IS_BUSY	equ	0			;should be public in cursors.asm!


pre_switch	label	word
;		dw	pre_switch_to_background
;		dw	pre_switch_to_foreground

post_switch	label	word
;		dw	post_switch_to_background
;		dw	post_switch_to_foreground

switch_table	label	word		;Screen switch dispatch table
;		dw	dev_to_background
;		dw	dev_to_foreground

switch_control	db	0		;Switch control flags
PREVENT_SWITCH	equ	10000000b	;Don't allow switch (DOS 3.x, 4.x)
DO_SWITCHING	equ	01000000b	;Have to do switching
INT_2F_HOOKED	equ	00000001b	;Have hooked int 2Fh
DISABLE_HOT_KEY equ	00000010b	;Set if keyboard disabling required

FLAGS_ON_STACK	equ	4		;iret --> offset(0), seg(2), flags(4)
CARRY_FLAG	equ	00000001b


REPAINT_EXPORT_INDEX	equ	275
repaint_addr	dd	0
user_string	db	'USER',0

sEnd	Data


sBegin	Code
assumes cs,Code


prev_int_2Fh	dd	0		;Previous int 2Fh vector
page


sEnd	Code
page

createSeg _INIT,InitSeg,word,public,CODE
sBegin	InitSeg
assumes cs,InitSeg


;---------------------------Public-Routine-----------------------------;
; hook_int_2Fh
;
; Installs a link in the 2Fh multiplex interrupt chain to watch for
; calls to the driver to save or restore the state of the display
; hardware before a context switch.
;
; This function is called whenever the driver recieves an enable call.
;
; Entry:
;	DS = Data
; Returns:
;	DS = Data
; Registers Preserved:
;	BX,CX,DX,SI,DI,BP,DS,ES
; Registers Destroyed:
;	AX,flags
; Calls:
;	none
; History:
;	Mon 05-Oct-1987 20:13:46 -by-  **** ***** [*****]
;	Moved getting the repaint procedure address to this
;	routine.
;
;	Sun 20-Sep-1987 19:00:13 -by-  **** ***** [*****]
;	Added addressibility to the Code segment where stuff
;	is stored.  Added switch_control flag.
;
;	Wed 16-Sep-1987 20:17:08 -by-  *** ****** [******]
;	Wrote it.
;-----------------------------------------------------------------------;

;------------------------------Pseudo-Code------------------------------;
; {
; }
;-----------------------------------------------------------------------;

	assumes ds,Data
	assumes es,nothing

		public	hook_int_2Fh
hook_int_2Fh	proc	near

	ret

hook_int_2Fh	endp
page

;---------------------------Public-Routine-----------------------------;
; restore_int_2Fh
;
; If we installed ourselves into int 2Fh, we'll restore the previous
; vector.
;
; This function is called whenever the driver receives a disable call.
;
; Entry:
;	ES = Data
; Returns:
;	ES = Data
; Registers Preserved:
;	BX,CX,DX,SI,DI,BP,DS
; Registers Destroyed:
;	AX,ES,flags
; Calls:
;	none
; History:
;	Sun 20-Sep-1987 19:00:13 -by-  **** ***** [*****]
;	Added addressibility to the Code segment where stuff
;	is stored.  Added switch_control flag.
;
;	Wed 16-Sep-1987 20:17:08 -by-  *** ****** [******]
;	Wrote it.
;-----------------------------------------------------------------------;

;------------------------------Pseudo-Code------------------------------;
; {
; }
;-----------------------------------------------------------------------;

	assumes ds,nothing
	assumes es,Data

		public	restore_int_2Fh

restore_int_2Fh proc	near

	ret

restore_int_2Fh endp
page

;---------------------------Public-Routine-----------------------------;
; driver_initialization
;
; Windows display driver initialization.  All display drivers which
; require special support for screen group switching will have this
; as their load time entry point.  This function will perform its
; initialization, then call the device specific initialization code.
;
; The DOS version number is checked, and the internal flags for
; screen group switching are set.
;
; Entry:
;	CX = size of heap
;	DI = module handle
;	DS = automatic data segment
;	ES:SI = address of command line (not used)
; Returns:
;	DS = Data
; Registers Preserved:
;	SI,DI,BP,DS
; Registers Destroyed:
;	AX,BX,CX,DX,ES,FLAGS
; Calls:
;	none
; History:
;	Sun 20-Sep-1987 19:00:13 -by-  **** ***** [*****]
;	Wrote it.
;-----------------------------------------------------------------------;

;------------------------------Pseudo-Code------------------------------;
; {
; }
;-----------------------------------------------------------------------;

	assumes ds,Data
	assumes es,nothing

cProc	driver_initialization,<FAR,PUBLIC>,<si,di>

cBegin

dont_support_switching:
	call	dev_initialization	;Device specific initialization

cEnd

sEnd	InitCode
end	driver_initialization
