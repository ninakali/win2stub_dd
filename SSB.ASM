        page    ,132
;-----------------------------Module-Header-----------------------------;
; Module Name:	SSB.ASM
;
;   This module contains the SaveScreenBitmap routine.
;
; Created: 19-May-1987
; Author:  *** ****** [******]
;
; Copyright (c) 1984-1987 Microsoft Corporation
;
; Exported Functions:	SaveScreenBitmap
;
; Public Functions:	none
;
; Public Data:		none
;
; General Description:
;
;	The subroutine SaveScreenBitmap saves a single bitmap from
;	the display to unused display memory, or restores or discards
;	a bitmap from otherwise unused memory to the display.  It
;	returns an error if the memory is either nonexistent, already
;	in use, or has been changed since the last save.
;
;	If the extra memory is being used by another program, the 
;	"SHADOW_EXISTS" bit will be turned off.  When it becomes free
;	again, the "SHADOW_TRASHED" and "SHADOW_EXISTS" bits will be set.
;	Thus, whenever the "SHADOW_EXISTS" bit is set, the memory is
;	available for use by this function.
;
; Restrictions:
;
;	Only one bitmap can be saved at a time.
;
;-----------------------------------------------------------------------;

;	This function will perform private stack checking.  In order for
;	private stack checking to occur, two symbols must be defined
;	prior to the inclusion of cmacros.inc.  ?CHKSTK must be defined
;	if the cmacros are to perform stack checking on procedures with
;	local parameters.  ?CHKSTKPROC must be defined if private stack
;	checking will be used.
;
;	The actual macro body for ?CHKSTKPROC will be defined later.



?CHKSTK = 1
?CHKSTKPROC	macro
		endm


	.xlist
	include	cmacros.inc
	include	gdidefs.inc
	include	display.inc
	include	egamem.inc
	include	macros.mac
	.list


	externA	ScreenSelector		;selector to the screen
	externA	SSB_EXTRA_SCANS

	externFP bitblt 		;bitblt function


;	Allowed values for the function (cmd) SaveScreenBitmap is to
;	perform.

SSB_SAVE	equ	0
SSB_RESTORE	equ	1
SSB_IGNORE	equ	2


sBegin	Code
assumes cs,Code
assumes ds,Data
assumes es,nothing

	externW ssb_device

;--------------------------Exported-Routine-----------------------------;
; SaveScreenBitmap
;
; Move a bitmap between active and unused display memory.
;
; Entry:
;	EGA registers in default state
; Returns:
;	AX = positive if no error
; Error Returns:
;	AX = 0 if error occured
; Registers Preserved:
;	SI,DI,DS,BP
; Registers Destroyed:
;	AX,BX,CX,DX,ES,FLAGS
; Calls:
;	bitblt
; History:
;	Tue 19-May-1987 17:22:59 -by-  *** ****** [******]
;	Created.
;	Thu 06-Aug-1987          -by-  *** ****** [******]
;	Replaced some magic numbers with equates; cleanup up style.
;-----------------------------------------------------------------------;


cProc	SaveScreenBitmap,<FAR,PUBLIC>,<si,di>

	parmD	lprect			;--> rectangle to operate on
	parmW	cmd			;0 = save, 1 = restore, 2 = ignore

	localB	status			;shadow memory status byte
	localW	x1			;lower x boundary of rectangle
	localW	y1			;lower y boundary
	localW	y2			;upper y boundary
	localW	xExt			;width of rectangle in pixels
	localW	yExt			;height of rectangle in scan lines

cBegin
	mov ax, 1

ssb_exit:

cEnd
sEnd	Code
	end

